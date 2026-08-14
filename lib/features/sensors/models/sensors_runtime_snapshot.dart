import 'package:equatable/equatable.dart';

import 'active_sensors_snapshot.dart';
import 'sensor_reading_model.dart';
import 'sensors_capabilities_snapshot.dart';

class SensorsRuntimeSnapshot extends Equatable {
  const SensorsRuntimeSnapshot({
    required this.listening,
    required this.activeSensors,
    required this.lastUpdated,
    this.capabilities,
    this.lastReading,
    this.errorCode,
    this.errorMessage,
  });

  final bool listening;
  final SensorsCapabilitiesSnapshot? capabilities;
  final ActiveSensorsSnapshot activeSensors;
  final SensorReadingModel? lastReading;
  final String? errorCode;
  final String? errorMessage;
  final DateTime lastUpdated;

  factory SensorsRuntimeSnapshot.initial() {
    return SensorsRuntimeSnapshot(
      listening: false,
      capabilities: null,
      activeSensors: ActiveSensorsSnapshot.empty(),
      lastReading: null,
      errorCode: null,
      errorMessage: null,
      lastUpdated: DateTime.now(),
    );
  }

  bool get hasError => errorCode != null || errorMessage != null;

  bool get isStreaming => activeSensors.activeCount > 0;

  SensorsRuntimeSnapshot copyWith({
    bool? listening,
    SensorsCapabilitiesSnapshot? capabilities,
    ActiveSensorsSnapshot? activeSensors,
    SensorReadingModel? lastReading,
    Object? errorCode = _keep,
    Object? errorMessage = _keep,
    DateTime? lastUpdated,
  }) {
    return SensorsRuntimeSnapshot(
      listening: listening ?? this.listening,
      capabilities: capabilities ?? this.capabilities,
      activeSensors: activeSensors ?? this.activeSensors,
      lastReading: lastReading ?? this.lastReading,
      errorCode: errorCode == _keep ? this.errorCode : errorCode as String?,
      errorMessage: errorMessage == _keep
          ? this.errorMessage
          : errorMessage as String?,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
    listening,
    capabilities,
    activeSensors,
    lastReading,
    errorCode,
    errorMessage,
    lastUpdated,
  ];
}

const Object _keep = Object();
