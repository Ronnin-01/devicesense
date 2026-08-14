import 'package:equatable/equatable.dart';

import 'sensor_map_parsers.dart';

class SensorReadingModel extends Equatable {
  const SensorReadingModel({
    required this.eventType,
    required this.sensorKey,
    required this.type,
    required this.typeLabel,
    required this.category,
    required this.name,
    required this.vendor,
    required this.version,
    required this.stringType,
    required this.values,
    required this.accuracy,
    required this.accuracyLabel,
    required this.sensorTimestampNs,
    required this.receivedAtMs,
    required this.reportingMode,
    required this.wakeUpSensor,
    required this.power,
    required this.resolution,
    required this.maximumRange,
    required this.minDelay,
    required this.maxDelay,
    required this.fifoReservedEventCount,
    required this.fifoMaxEventCount,
  });

  final String eventType;
  final String sensorKey;
  final int type;
  final String typeLabel;
  final String category;
  final String name;
  final String vendor;
  final int version;
  final String stringType;
  final List<double> values;
  final int accuracy;
  final String accuracyLabel;
  final int sensorTimestampNs;
  final int receivedAtMs;
  final String reportingMode;
  final bool wakeUpSensor;
  final double power;
  final double resolution;
  final double maximumRange;
  final int minDelay;
  final int maxDelay;
  final int fifoReservedEventCount;
  final int fifoMaxEventCount;

  factory SensorReadingModel.fromMap(
    Map<String, dynamic> map, {
    required String eventType,
  }) {
    return SensorReadingModel(
      eventType: eventType,
      sensorKey: parseString(map['sensorKey']),
      type: parseInt(map['type'], -1),
      typeLabel: parseString(map['typeLabel'], 'Unknown'),
      category: parseString(map['category'], 'other'),
      name: parseString(map['name'], 'Unknown'),
      vendor: parseString(map['vendor'], 'Unknown'),
      version: parseInt(map['version'], 0),
      stringType: parseString(map['stringType'], 'Unknown'),
      values: parseDoubleList(map['values']),
      accuracy: parseInt(map['accuracy'], -1),
      accuracyLabel: parseString(map['accuracyLabel'], 'UNKNOWN'),
      sensorTimestampNs: parseInt(map['sensorTimestampNs'], 0),
      receivedAtMs: parseInt(map['receivedAtMs'], 0),
      reportingMode: parseString(map['reportingMode'], 'UNKNOWN'),
      wakeUpSensor: parseBool(map['wakeUpSensor']),
      power: parseDouble(map['power']),
      resolution: parseDouble(map['resolution']),
      maximumRange: parseDouble(map['maximumRange']),
      minDelay: parseInt(map['minDelay'], -1),
      maxDelay: parseInt(map['maxDelay'], -1),
      fifoReservedEventCount: parseInt(map['fifoReservedEventCount'], 0),
      fifoMaxEventCount: parseInt(map['fifoMaxEventCount'], 0),
    );
  }

  @override
  List<Object?> get props => [
    eventType,
    sensorKey,
    type,
    typeLabel,
    category,
    name,
    vendor,
    version,
    stringType,
    values,
    accuracy,
    accuracyLabel,
    sensorTimestampNs,
    receivedAtMs,
    reportingMode,
    wakeUpSensor,
    power,
    resolution,
    maximumRange,
    minDelay,
    maxDelay,
    fifoReservedEventCount,
    fifoMaxEventCount,
  ];
}
