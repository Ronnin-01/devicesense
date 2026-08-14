import '../../../features/sensors/models/active_sensors_snapshot.dart';
import '../../../features/sensors/models/sensor_operation_result.dart';
import '../../../features/sensors/models/sensors_capabilities_snapshot.dart';
import '../../../features/sensors/models/sensors_runtime_snapshot.dart';

abstract class SensorsRepository {
  Stream<SensorsRuntimeSnapshot> get snapshotStream;

  Future<SensorsCapabilitiesSnapshot> getCapabilities({bool forceRefresh});

  Future<SensorOperationResult> startSensor({
    required int type,
    int? samplingPeriodUs,
  });

  Future<SensorOperationResult> stopSensor({required int type});

  Future<SensorOperationResult> startAllSensors({int? samplingPeriodUs});

  Future<SensorOperationResult> stopAllSensors();

  Future<ActiveSensorsSnapshot> getActiveSensors();

  Future<void> ensureListening();

  Future<void> dispose();
}
