import 'package:equatable/equatable.dart';

import 'sensor_map_parsers.dart';

class ActiveSensorModel extends Equatable {
  const ActiveSensorModel({
    required this.sensorKey,
    required this.type,
    required this.typeLabel,
    required this.name,
    required this.vendor,
    required this.samplingPeriodUs,
  });

  final String sensorKey;
  final int type;
  final String typeLabel;
  final String name;
  final String vendor;
  final int samplingPeriodUs;

  factory ActiveSensorModel.fromMap(Map<String, dynamic> map) {
    return ActiveSensorModel(
      sensorKey: parseString(map['sensorKey']),
      type: parseInt(map['type'], -1),
      typeLabel: parseString(map['typeLabel'], 'Unknown'),
      name: parseString(map['name'], 'Unknown'),
      vendor: parseString(map['vendor'], 'Unknown'),
      samplingPeriodUs: parseInt(map['samplingPeriodUs'], 0),
    );
  }

  @override
  List<Object?> get props => [
    sensorKey,
    type,
    typeLabel,
    name,
    vendor,
    samplingPeriodUs,
  ];
}
