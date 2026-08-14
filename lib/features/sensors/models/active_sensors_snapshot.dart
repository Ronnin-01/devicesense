import 'package:equatable/equatable.dart';

import 'active_sensor_model.dart';
import 'sensor_map_parsers.dart';

class ActiveSensorsSnapshot extends Equatable {
  const ActiveSensorsSnapshot({
    required this.activeCount,
    required this.activeSensors,
  });

  final int activeCount;
  final List<ActiveSensorModel> activeSensors;

  factory ActiveSensorsSnapshot.fromMap(Map<String, dynamic> map) {
    final rawSensors = asDynamicList(map['activeSensors']);

    return ActiveSensorsSnapshot(
      activeCount: parseInt(map['activeCount'], rawSensors.length),
      activeSensors: rawSensors
          .map((item) => ActiveSensorModel.fromMap(asStringMap(item)))
          .toList(growable: false),
    );
  }

  factory ActiveSensorsSnapshot.empty() {
    return const ActiveSensorsSnapshot(
      activeCount: 0,
      activeSensors: <ActiveSensorModel>[],
    );
  }

  ActiveSensorsSnapshot copyWith({
    int? activeCount,
    List<ActiveSensorModel>? activeSensors,
  }) {
    return ActiveSensorsSnapshot(
      activeCount: activeCount ?? this.activeCount,
      activeSensors: activeSensors ?? this.activeSensors,
    );
  }

  @override
  List<Object?> get props => [activeCount, activeSensors];
}
