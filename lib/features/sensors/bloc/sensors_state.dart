import 'package:equatable/equatable.dart';

import '../models/active_sensors_snapshot.dart';
import '../models/sensor_reading_model.dart';
import '../models/sensors_capabilities_snapshot.dart';
import '../models/sensors_runtime_snapshot.dart';

sealed class SensorsState extends Equatable {
  const SensorsState();

  @override
  List<Object?> get props => [];
}

class SensorsInitial extends SensorsState {
  const SensorsInitial();
}

class SensorsLoading extends SensorsState {
  const SensorsLoading();
}

/// The normal steady-state.
/// This carries the full runtime snapshot and should be used for most UI.
class SensorsLoaded extends SensorsState {
  const SensorsLoaded({required this.snapshot});

  final SensorsRuntimeSnapshot snapshot;

  SensorsCapabilitiesSnapshot? get capabilities => snapshot.capabilities;
  ActiveSensorsSnapshot get activeSensors => snapshot.activeSensors;
  SensorReadingModel? get lastReading => snapshot.lastReading;
  bool get listening => snapshot.listening;
  bool get isStreaming => snapshot.isStreaming;
  bool get hasError => snapshot.hasError;
  String? get errorCode => snapshot.errorCode;
  String? get errorMessage => snapshot.errorMessage;
  DateTime get lastUpdated => snapshot.lastUpdated;

  @override
  List<Object?> get props => [snapshot];
}

/// Used only for fatal orchestration failures,
/// not for normal sensor permissions/errors that the snapshot can already carry.
class SensorsError extends SensorsState {
  const SensorsError({required this.message, this.snapshot});

  final String message;
  final SensorsRuntimeSnapshot? snapshot;

  bool get hasSnapshot => snapshot != null;

  @override
  List<Object?> get props => [message, snapshot];
}
