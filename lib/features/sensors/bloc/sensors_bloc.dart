import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/error/sensor_repository_exception.dart';
import '../../../data/repositories/sensors/sensors_repository.dart';
import '../models/sensors_runtime_snapshot.dart';
import 'sensors_event.dart';
import 'sensors_state.dart';

class SensorsBloc extends Bloc<SensorsEvent, SensorsState> {
  SensorsBloc({required this._repository}) : super(const SensorsInitial()) {
    on<SensorsRequested>(_onRequested);
    on<SensorsCapabilitiesRequested>(_onCapabilitiesRequested);
    on<SensorsStartSensorRequested>(_onStartSensorRequested);
    on<SensorsStopSensorRequested>(_onStopSensorRequested);
    on<SensorsStartAllSensorsRequested>(_onStartAllSensorsRequested);
    on<SensorsStopAllSensorsRequested>(_onStopAllSensorsRequested);
    on<SensorsRefreshActiveSensorsRequested>(_onRefreshActiveSensorsRequested);

    on<_SensorsSnapshotUpdated>(_onSnapshotUpdated);
    on<_SensorsRepositoryError>(_onRepositoryError);
  }

  final SensorsRepository _repository;

  StreamSubscription<SensorsRuntimeSnapshot>? _snapshotSubscription;
  SensorsRuntimeSnapshot _latestSnapshot = SensorsRuntimeSnapshot.initial();

  Future<void> _onRequested(
    SensorsRequested event,
    Emitter<SensorsState> emit,
  ) async {
    emit(const SensorsLoading());

    await _restartRepositorySubscription();

    try {
      await _repository.ensureListening();

      final capabilities = await _repository.getCapabilities(
        forceRefresh: false,
      );

      final activeSensors = await _repository.getActiveSensors();

      _latestSnapshot = _latestSnapshot.copyWith(
        listening: true,
        capabilities: capabilities,
        activeSensors: activeSensors,
        errorCode: null,
        errorMessage: null,
        lastUpdated: DateTime.now(),
      );

      emit(SensorsLoaded(snapshot: _latestSnapshot));
    } on SensorRepositoryException catch (error) {
      emit(SensorsError(message: error.message, snapshot: _latestSnapshot));
    } on PlatformException catch (error) {
      emit(
        SensorsError(
          message: error.message ?? error.code,
          snapshot: _latestSnapshot,
        ),
      );
    } catch (error) {
      emit(SensorsError(message: error.toString(), snapshot: _latestSnapshot));
    }
  }

  Future<void> _onCapabilitiesRequested(
    SensorsCapabilitiesRequested event,
    Emitter<SensorsState> emit,
  ) async {
    emit(const SensorsLoading());

    try {
      final capabilities = await _repository.getCapabilities(
        forceRefresh: event.forceRefresh,
      );

      _latestSnapshot = _latestSnapshot.copyWith(
        capabilities: capabilities,
        errorCode: null,
        errorMessage: null,
        lastUpdated: DateTime.now(),
      );

      emit(SensorsLoaded(snapshot: _latestSnapshot));
    } on SensorRepositoryException catch (error) {
      emit(SensorsError(message: error.message, snapshot: _latestSnapshot));
    } on PlatformException catch (error) {
      emit(
        SensorsError(
          message: error.message ?? error.code,
          snapshot: _latestSnapshot,
        ),
      );
    } catch (error) {
      emit(SensorsError(message: error.toString(), snapshot: _latestSnapshot));
    }
  }

  Future<void> _onStartSensorRequested(
    SensorsStartSensorRequested event,
    Emitter<SensorsState> emit,
  ) async {
    try {
      await _repository.startSensor(
        type: event.type,
        samplingPeriodUs: event.samplingPeriodUs,
      );

      await _repository.getActiveSensors();
    } on SensorRepositoryException catch (error) {
      emit(SensorsError(message: error.message, snapshot: _latestSnapshot));
    } on PlatformException catch (error) {
      emit(
        SensorsError(
          message: error.message ?? error.code,
          snapshot: _latestSnapshot,
        ),
      );
    } catch (error) {
      emit(SensorsError(message: error.toString(), snapshot: _latestSnapshot));
    }
  }

  Future<void> _onStopSensorRequested(
    SensorsStopSensorRequested event,
    Emitter<SensorsState> emit,
  ) async {
    try {
      await _repository.stopSensor(type: event.type);
      await _repository.getActiveSensors();
    } on SensorRepositoryException catch (error) {
      emit(SensorsError(message: error.message, snapshot: _latestSnapshot));
    } on PlatformException catch (error) {
      emit(
        SensorsError(
          message: error.message ?? error.code,
          snapshot: _latestSnapshot,
        ),
      );
    } catch (error) {
      emit(SensorsError(message: error.toString(), snapshot: _latestSnapshot));
    }
  }

  Future<void> _onStartAllSensorsRequested(
    SensorsStartAllSensorsRequested event,
    Emitter<SensorsState> emit,
  ) async {
    try {
      await _repository.startAllSensors(
        samplingPeriodUs: event.samplingPeriodUs,
      );

      await _repository.getActiveSensors();
    } on SensorRepositoryException catch (error) {
      emit(SensorsError(message: error.message, snapshot: _latestSnapshot));
    } on PlatformException catch (error) {
      emit(
        SensorsError(
          message: error.message ?? error.code,
          snapshot: _latestSnapshot,
        ),
      );
    } catch (error) {
      emit(SensorsError(message: error.toString(), snapshot: _latestSnapshot));
    }
  }

  Future<void> _onStopAllSensorsRequested(
    SensorsStopAllSensorsRequested event,
    Emitter<SensorsState> emit,
  ) async {
    try {
      await _repository.stopAllSensors();
      await _repository.getActiveSensors();
    } on SensorRepositoryException catch (error) {
      emit(SensorsError(message: error.message, snapshot: _latestSnapshot));
    } on PlatformException catch (error) {
      emit(
        SensorsError(
          message: error.message ?? error.code,
          snapshot: _latestSnapshot,
        ),
      );
    } catch (error) {
      emit(SensorsError(message: error.toString(), snapshot: _latestSnapshot));
    }
  }

  Future<void> _onRefreshActiveSensorsRequested(
    SensorsRefreshActiveSensorsRequested event,
    Emitter<SensorsState> emit,
  ) async {
    try {
      await _repository.getActiveSensors();
    } on SensorRepositoryException catch (error) {
      emit(SensorsError(message: error.message, snapshot: _latestSnapshot));
    } on PlatformException catch (error) {
      emit(
        SensorsError(
          message: error.message ?? error.code,
          snapshot: _latestSnapshot,
        ),
      );
    } catch (error) {
      emit(SensorsError(message: error.toString(), snapshot: _latestSnapshot));
    }
  }

  void _onSnapshotUpdated(
    _SensorsSnapshotUpdated event,
    Emitter<SensorsState> emit,
  ) {
    _latestSnapshot = event.snapshot;
    emit(SensorsLoaded(snapshot: event.snapshot));
  }

  void _onRepositoryError(
    _SensorsRepositoryError event,
    Emitter<SensorsState> emit,
  ) {
    emit(
      SensorsError(
        message: '[${event.code}] ${event.message}',
        snapshot: _latestSnapshot,
      ),
    );
  }

  Future<void> _restartRepositorySubscription() async {
    await _snapshotSubscription?.cancel();
    _snapshotSubscription = null;

    _snapshotSubscription = _repository.snapshotStream.listen(
      (snapshot) {
        add(_SensorsSnapshotUpdated(snapshot));
      },
      onError: (Object error, StackTrace stackTrace) {
        add(
          _SensorsRepositoryError(
            code: 'SENSOR_STREAM_ERROR',
            message: error.toString(),
          ),
        );
      },
      cancelOnError: false,
    );
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription?.cancel();
    _snapshotSubscription = null;

    await _repository.dispose();

    return super.close();
  }
}

/// Internal event, forwarded from the repository snapshot stream.
class _SensorsSnapshotUpdated extends SensorsEvent {
  const _SensorsSnapshotUpdated(this.snapshot);

  final SensorsRuntimeSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

/// Internal event, forwarded when the repository stream reports a fatal error.
class _SensorsRepositoryError extends SensorsEvent {
  const _SensorsRepositoryError({required this.code, required this.message});

  final String code;
  final String message;

  @override
  List<Object?> get props => [code, message];
}
