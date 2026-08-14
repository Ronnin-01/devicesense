import 'package:equatable/equatable.dart';

import 'sensor_map_parsers.dart';

class SensorOperationEntry extends Equatable {
  const SensorOperationEntry({
    required this.sensorKey,
    required this.type,
    required this.name,
    required this.typeLabel,
    required this.reason,
    required this.alreadyActive,
  });

  final String sensorKey;
  final int type;
  final String name;
  final String typeLabel;
  final String reason;
  final bool alreadyActive;

  factory SensorOperationEntry.fromMap(Map<String, dynamic> map) {
    return SensorOperationEntry(
      sensorKey: parseString(map['sensorKey']),
      type: parseInt(map['type'], -1),
      name: parseString(map['name'], 'Unknown'),
      typeLabel: parseString(map['typeLabel'], 'Unknown'),
      reason: parseString(map['reason']),
      alreadyActive: parseBool(map['alreadyActive']),
    );
  }

  @override
  List<Object?> get props => [
    sensorKey,
    type,
    name,
    typeLabel,
    reason,
    alreadyActive,
  ];
}
