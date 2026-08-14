import 'package:equatable/equatable.dart';

import 'sensor_map_parsers.dart';

class SensorCapabilityModel extends Equatable {
  const SensorCapabilityModel({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.category,
    required this.name,
    required this.vendor,
    required this.version,
    required this.stringType,
    required this.maximumRange,
    required this.resolution,
    required this.power,
    required this.minDelay,
    required this.maxDelay,
    required this.reportingMode,
    required this.wakeUpSensor,
    required this.fifoReservedEventCount,
    required this.fifoMaxEventCount,
    required this.requiredPermission,
    required this.permissionRequired,
    required this.permissionReason,
  });

  final int id;
  final int type;
  final String typeLabel;
  final String category;
  final String name;
  final String vendor;
  final int version;
  final String stringType;
  final double maximumRange;
  final double resolution;
  final double power;
  final int minDelay;
  final int maxDelay;
  final String reportingMode;
  final bool wakeUpSensor;
  final int fifoReservedEventCount;
  final int fifoMaxEventCount;
  final String requiredPermission;
  final bool permissionRequired;
  final String permissionReason;

  factory SensorCapabilityModel.fromMap(Map<String, dynamic> map) {
    return SensorCapabilityModel(
      id: parseInt(map['id'], -1),
      type: parseInt(map['type'], -1),
      typeLabel: parseString(map['typeLabel'], 'Unknown'),
      category: parseString(map['category'], 'other'),
      name: parseString(map['name'], 'Unknown'),
      vendor: parseString(map['vendor'], 'Unknown'),
      version: parseInt(map['version'], 0),
      stringType: parseString(map['stringType'], 'Unknown'),
      maximumRange: parseDouble(map['maximumRange']),
      resolution: parseDouble(map['resolution']),
      power: parseDouble(map['power']),
      minDelay: parseInt(map['minDelay'], -1),
      maxDelay: parseInt(map['maxDelay'], -1),
      reportingMode: parseString(map['reportingMode'], 'UNKNOWN'),
      wakeUpSensor: parseBool(map['wakeUpSensor']),
      fifoReservedEventCount: parseInt(map['fifoReservedEventCount'], 0),
      fifoMaxEventCount: parseInt(map['fifoMaxEventCount'], 0),
      requiredPermission: parseString(map['requiredPermission']),
      permissionRequired: parseBool(map['permissionRequired']),
      permissionReason: parseString(map['permissionReason']),
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    typeLabel,
    category,
    name,
    vendor,
    version,
    stringType,
    maximumRange,
    resolution,
    power,
    minDelay,
    maxDelay,
    reportingMode,
    wakeUpSensor,
    fifoReservedEventCount,
    fifoMaxEventCount,
    requiredPermission,
    permissionRequired,
    permissionReason,
  ];
}
