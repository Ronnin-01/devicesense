import 'dart:async';

import 'package:flutter/services.dart';

import '../../../core/error/sensor_repository_exception.dart';
import '../../../core/platform/native_channel.dart';
import '../../../features/sensors/models/active_sensors_snapshot.dart';
import '../../../features/sensors/models/sensor_map_parsers.dart';
import '../../../features/sensors/models/sensor_operation_result.dart';
import '../../../features/sensors/models/sensor_reading_model.dart';
import '../../../features/sensors/models/sensors_capabilities_snapshot.dart';
import '../../../features/sensors/models/sensors_runtime_snapshot.dart';
import 'sensors_repository.dart';

class SensorsRepositoryImpl implements SensorsRepository {
  SensorsRepositoryImpl() {
    _snapshotController = StreamController<SensorsRuntimeSnapshot>.broadcast(
      onListen: () {
        if (!_disposed && !_snapshotController.isClosed) {
          _snapshotController.add(_state);
        }
      },
      onCancel: () {
        // Intentionally left blank.
        // The repository stays alive until dispose() is called by the Bloc.
      },
    );
  }

  late final StreamController<SensorsRuntimeSnapshot> _snapshotController;

  StreamSubscription<Map<String, dynamic>>? _nativeSubscription;
  bool _disposed = false;

  SensorsCapabilitiesSnapshot? _capabilitiesCache;

  SensorsRuntimeSnapshot _state = SensorsRuntimeSnapshot.initial();

  @override
  Stream<SensorsRuntimeSnapshot> get snapshotStream =>
      _snapshotController.stream;

  @override
  Future<SensorsCapabilitiesSnapshot> getCapabilities({
    bool forceRefresh = false,
  }) async {
    if (_disposed) {
      throw const SensorRepositoryException(
        code: 'SENSORS_DISPOSED',
        message: 'Sensors repository has already been disposed.',
      );
    }

    if (!forceRefresh && _capabilitiesCache != null) {
      return _capabilitiesCache!;
    }

    try {
      final raw = await NativeChannel.getSensorsCapabilities();
      final capabilities = SensorsCapabilitiesSnapshot.fromMap(raw);

      _capabilitiesCache = capabilities;
      _state = _state.copyWith(
        capabilities: capabilities,
        lastUpdated: DateTime.now(),
        errorCode: null,
        errorMessage: null,
      );

      _emitState();

      return capabilities;
    } on PlatformException catch (error) {
      _emitError(
        code: error.code,
        message: error.message ?? 'Failed to read sensor capabilities.',
        details: error.details,
      );
      throw SensorRepositoryException(
        code: error.code,
        message: error.message ?? 'Failed to read sensor capabilities.',
        details: error.details,
        cause: error,
      );
    } catch (error) {
      _emitError(code: 'SENSOR_CAPABILITIES_ERROR', message: error.toString());
      throw SensorRepositoryException(
        code: 'SENSOR_CAPABILITIES_ERROR',
        message: error.toString(),
        cause: error,
      );
    }
  }

  @override
  Future<void> ensureListening() async {
    if (_disposed) {
      throw const SensorRepositoryException(
        code: 'SENSORS_DISPOSED',
        message: 'Sensors repository has already been disposed.',
      );
    }

    if (_nativeSubscription != null) {
      return;
    }

    _nativeSubscription = NativeChannel.sensorStream().listen(
      _handleNativeEvent,
      onError: (Object error, StackTrace stackTrace) {
        _handleStreamError(error);
      },
      cancelOnError: false,
    );

    _state = _state.copyWith(
      listening: true,
      lastUpdated: DateTime.now(),
      errorCode: null,
      errorMessage: null,
    );
    _emitState();
  }

  @override
  Future<SensorOperationResult> startSensor({
    required int type,
    int? samplingPeriodUs,
  }) async {
    await ensureListening();

    try {
      final raw = await NativeChannel.startSensor(
        type: type,
        samplingPeriodUs: samplingPeriodUs,
      );

      final operation = SensorOperationResult.fromMap(raw);
      await _syncActiveSensors();

      return operation;
    } on PlatformException catch (error) {
      final repoError = SensorRepositoryException(
        code: error.code,
        message: error.message ?? 'Failed to start sensor.',
        details: error.details,
        cause: error,
      );

      _emitError(
        code: repoError.code,
        message: repoError.message,
        details: repoError.details,
      );

      return SensorOperationResult.failure(message: repoError.message);
    } catch (error) {
      _emitError(code: 'SENSOR_START_ERROR', message: error.toString());
      return SensorOperationResult.failure(message: error.toString());
    }
  }

  @override
  Future<SensorOperationResult> stopSensor({required int type}) async {
    if (_disposed) {
      return SensorOperationResult.failure(
        message: 'Sensors repository has already been disposed.',
      );
    }

    try {
      final raw = await NativeChannel.stopSensor(type: type);
      final operation = SensorOperationResult.fromMap(raw);
      await _syncActiveSensors();
      return operation;
    } on PlatformException catch (error) {
      _emitError(
        code: error.code,
        message: error.message ?? 'Failed to stop sensor.',
        details: error.details,
      );
      return SensorOperationResult.failure(
        message: error.message ?? 'Failed to stop sensor.',
      );
    } catch (error) {
      _emitError(code: 'SENSOR_STOP_ERROR', message: error.toString());
      return SensorOperationResult.failure(message: error.toString());
    }
  }

  @override
  Future<SensorOperationResult> startAllSensors({int? samplingPeriodUs}) async {
    await ensureListening();

    try {
      final raw = await NativeChannel.startAllSensors(
        samplingPeriodUs: samplingPeriodUs,
      );

      final operation = SensorOperationResult.fromMap(raw);
      await _syncActiveSensors();

      return operation;
    } on PlatformException catch (error) {
      _emitError(
        code: error.code,
        message: error.message ?? 'Failed to start sensors.',
        details: error.details,
      );
      return SensorOperationResult.failure(
        message: error.message ?? 'Failed to start sensors.',
      );
    } catch (error) {
      _emitError(code: 'SENSOR_START_ALL_ERROR', message: error.toString());
      return SensorOperationResult.failure(message: error.toString());
    }
  }

  @override
  Future<SensorOperationResult> stopAllSensors() async {
    if (_disposed) {
      return SensorOperationResult.failure(
        message: 'Sensors repository has already been disposed.',
      );
    }

    try {
      final raw = await NativeChannel.stopAllSensors();
      final operation = SensorOperationResult.fromMap(raw);
      await _syncActiveSensors();
      return operation;
    } on PlatformException catch (error) {
      _emitError(
        code: error.code,
        message: error.message ?? 'Failed to stop sensors.',
        details: error.details,
      );
      return SensorOperationResult.failure(
        message: error.message ?? 'Failed to stop sensors.',
      );
    } catch (error) {
      _emitError(code: 'SENSOR_STOP_ALL_ERROR', message: error.toString());
      return SensorOperationResult.failure(message: error.toString());
    }
  }

  @override
  Future<ActiveSensorsSnapshot> getActiveSensors() async {
    if (_disposed) {
      throw const SensorRepositoryException(
        code: 'SENSORS_DISPOSED',
        message: 'Sensors repository has already been disposed.',
      );
    }

    try {
      final raw = await NativeChannel.getActiveSensors();
      final active = ActiveSensorsSnapshot.fromMap(raw);

      _state = _state.copyWith(
        activeSensors: active,
        lastUpdated: DateTime.now(),
        errorCode: null,
        errorMessage: null,
      );
      _emitState();

      return active;
    } on PlatformException catch (error) {
      _emitError(
        code: error.code,
        message: error.message ?? 'Failed to read active sensors.',
        details: error.details,
      );
      throw SensorRepositoryException(
        code: error.code,
        message: error.message ?? 'Failed to read active sensors.',
        details: error.details,
        cause: error,
      );
    } catch (error) {
      _emitError(code: 'ACTIVE_SENSORS_ERROR', message: error.toString());
      throw SensorRepositoryException(
        code: 'ACTIVE_SENSORS_ERROR',
        message: error.toString(),
        cause: error,
      );
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    try {
      await _nativeSubscription?.cancel();
    } catch (_) {
      // Intentionally ignored. Disposal should not crash the app.
    } finally {
      _nativeSubscription = null;
    }

    if (!_snapshotController.isClosed) {
      await _snapshotController.close();
    }
  }

  void _handleNativeEvent(Map<String, dynamic> event) {
    if (_disposed) return;

    final eventType = parseString(event['event']);

    switch (eventType) {
      case 'sensorData':
        _handleSensorData(event);
        break;

      case 'sensorAccuracyChanged':
        _handleSensorAccuracyChanged(event);
        break;

      case 'sensorError':
      case 'streamError':
        _handleNativeErrorEvent(event);
        break;

      default:
        // Ignore unknown future events gracefully.
        break;
    }
  }

  void _handleSensorData(Map<String, dynamic> event) {
    final reading = SensorReadingModel.fromMap(event, eventType: 'sensorData');

    _state = _state.copyWith(
      lastReading: reading,
      lastUpdated: DateTime.now(),
      errorCode: null,
      errorMessage: null,
    );
    _emitState();
  }

  void _handleSensorAccuracyChanged(Map<String, dynamic> event) {
    final reading = SensorReadingModel.fromMap(
      event,
      eventType: 'sensorAccuracyChanged',
    );

    _state = _state.copyWith(
      lastReading: reading,
      lastUpdated: DateTime.now(),
      errorCode: null,
      errorMessage: null,
    );
    _emitState();
  }

  void _handleNativeErrorEvent(Map<String, dynamic> event) {
    final code = parseString(event['code'], 'SENSOR_ERROR');
    final message = parseString(event['message'], 'Unknown sensor error');

    _emitError(code: code, message: message, details: event);
  }

  void _handleStreamError(Object error) {
    if (_disposed) return;

    _emitError(code: 'SENSOR_STREAM_ERROR', message: error.toString());
  }

  Future<void> _syncActiveSensors() async {
    if (_disposed) return;

    try {
      final raw = await NativeChannel.getActiveSensors();
      final active = ActiveSensorsSnapshot.fromMap(raw);

      _state = _state.copyWith(
        activeSensors: active,
        lastUpdated: DateTime.now(),
        errorCode: null,
        errorMessage: null,
      );
      _emitState();
    } catch (error) {
      // Keep the last good state, but surface the problem.
      _emitError(code: 'ACTIVE_SENSORS_SYNC_ERROR', message: error.toString());
    }
  }

  void _emitState() {
    if (_disposed || _snapshotController.isClosed) return;
    _snapshotController.add(_state);
  }

  void _emitError({
    required String code,
    required String message,
    Object? details,
  }) {
    if (_disposed || _snapshotController.isClosed) return;

    _state = _state.copyWith(
      errorCode: code,
      errorMessage: message,
      lastUpdated: DateTime.now(),
    );
    _snapshotController.add(_state);
  }
}
