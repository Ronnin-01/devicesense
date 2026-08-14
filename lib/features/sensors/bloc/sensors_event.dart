import 'package:equatable/equatable.dart';

import '../models/sensors_runtime_snapshot.dart';

class SensorsEvent extends Equatable {
  const SensorsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial page request.
/// Sets up the native sensor stream, loads capabilities, and syncs active sensors.
class SensorsRequested extends SensorsEvent {
  const SensorsRequested();
}

/// Refreshes the sensor capability catalog.
class SensorsCapabilitiesRequested extends SensorsEvent {
  const SensorsCapabilitiesRequested({this.forceRefresh = false});

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

/// Start one sensor by Android sensor type id.
class SensorsStartSensorRequested extends SensorsEvent {
  const SensorsStartSensorRequested({
    required this.type,
    this.samplingPeriodUs,
  });

  final int type;
  final int? samplingPeriodUs;

  @override
  List<Object?> get props => [type, samplingPeriodUs];
}

/// Stop one sensor by Android sensor type id.
class SensorsStopSensorRequested extends SensorsEvent {
  const SensorsStopSensorRequested({required this.type});

  final int type;

  @override
  List<Object?> get props => [type];
}

/// Start every sensor the native side can register.
class SensorsStartAllSensorsRequested extends SensorsEvent {
  const SensorsStartAllSensorsRequested({this.samplingPeriodUs});

  final int? samplingPeriodUs;

  @override
  List<Object?> get props => [samplingPeriodUs];
}

/// Stop every active sensor.
class SensorsStopAllSensorsRequested extends SensorsEvent {
  const SensorsStopAllSensorsRequested();
}

/// Refresh the active sensor list from the repository.
class SensorsRefreshActiveSensorsRequested extends SensorsEvent {
  const SensorsRefreshActiveSensorsRequested();
}
