import 'package:equatable/equatable.dart';

import 'sensor_capability_model.dart';
import 'sensor_map_parsers.dart';

class SensorsCapabilitiesSnapshot extends Equatable {
  const SensorsCapabilitiesSnapshot({
    required this.supported,
    required this.sdkInt,
    required this.sensorCount,
    required this.sensors,
  });

  final bool supported;
  final int sdkInt;
  final int sensorCount;
  final List<SensorCapabilityModel> sensors;

  factory SensorsCapabilitiesSnapshot.fromMap(Map<String, dynamic> map) {
    final rawSensors = asDynamicList(map['sensors']);

    return SensorsCapabilitiesSnapshot(
      supported: parseBool(map['supported']),
      sdkInt: parseInt(map['sdkInt'], 0),
      sensorCount: parseInt(map['sensorCount'], rawSensors.length),
      sensors: rawSensors
          .map((item) => SensorCapabilityModel.fromMap(asStringMap(item)))
          .toList(growable: false),
    );
  }

  factory SensorsCapabilitiesSnapshot.empty() {
    return const SensorsCapabilitiesSnapshot(
      supported: false,
      sdkInt: 0,
      sensorCount: 0,
      sensors: <SensorCapabilityModel>[],
    );
  }

  SensorsCapabilitiesSnapshot copyWith({
    bool? supported,
    int? sdkInt,
    int? sensorCount,
    List<SensorCapabilityModel>? sensors,
  }) {
    return SensorsCapabilitiesSnapshot(
      supported: supported ?? this.supported,
      sdkInt: sdkInt ?? this.sdkInt,
      sensorCount: sensorCount ?? this.sensorCount,
      sensors: sensors ?? this.sensors,
    );
  }

  @override
  List<Object?> get props => [supported, sdkInt, sensorCount, sensors];
}
