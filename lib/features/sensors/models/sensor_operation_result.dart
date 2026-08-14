import 'package:equatable/equatable.dart';

import 'sensor_map_parsers.dart';
import 'sensor_operation_entry.dart';

class SensorOperationResult extends Equatable {
  const SensorOperationResult({
    required this.success,
    required this.alreadyActive,
    required this.started,
    required this.stopped,
    required this.activeCount,
    required this.requestedCount,
    required this.startedCount,
    required this.skippedCount,
    required this.failedCount,
    required this.stoppedCount,
    required this.sensorKey,
    required this.message,
    required this.startedSensors,
    required this.skippedSensors,
    required this.failedSensors,
  });

  final bool success;
  final bool alreadyActive;
  final bool started;
  final bool stopped;

  final int activeCount;
  final int requestedCount;
  final int startedCount;
  final int skippedCount;
  final int failedCount;
  final int stoppedCount;

  final String sensorKey;
  final String message;

  final List<SensorOperationEntry> startedSensors;
  final List<SensorOperationEntry> skippedSensors;
  final List<SensorOperationEntry> failedSensors;

  factory SensorOperationResult.fromMap(Map<String, dynamic> map) {
    return SensorOperationResult(
      success: parseBool(map['success'] ?? map['started'] ?? map['stopped']),
      alreadyActive: parseBool(map['alreadyActive']),
      started: parseBool(map['started']),
      stopped: parseBool(map['stopped']),
      activeCount: parseInt(map['activeCount'], 0),
      requestedCount: parseInt(map['requestedCount'], 0),
      startedCount: parseInt(map['startedCount'], 0),
      skippedCount: parseInt(map['skippedCount'], 0),
      failedCount: parseInt(map['failedCount'], 0),
      stoppedCount: parseInt(map['stoppedCount'], 0),
      sensorKey: parseString(map['sensorKey']),
      message: parseString(map['message']),
      startedSensors: asDynamicList(map['startedSensors'])
          .map((item) => SensorOperationEntry.fromMap(asStringMap(item)))
          .toList(growable: false),
      skippedSensors: asDynamicList(map['skippedSensors'])
          .map((item) => SensorOperationEntry.fromMap(asStringMap(item)))
          .toList(growable: false),
      failedSensors: asDynamicList(map['failedSensors'])
          .map((item) => SensorOperationEntry.fromMap(asStringMap(item)))
          .toList(growable: false),
    );
  }

  factory SensorOperationResult.failure({required String message}) {
    return SensorOperationResult(
      success: false,
      alreadyActive: false,
      started: false,
      stopped: false,
      activeCount: 0,
      requestedCount: 0,
      startedCount: 0,
      skippedCount: 0,
      failedCount: 0,
      stoppedCount: 0,
      sensorKey: '',
      message: message,
      startedSensors: const <SensorOperationEntry>[],
      skippedSensors: const <SensorOperationEntry>[],
      failedSensors: const <SensorOperationEntry>[],
    );
  }

  @override
  List<Object?> get props => [
    success,
    alreadyActive,
    started,
    stopped,
    activeCount,
    requestedCount,
    startedCount,
    skippedCount,
    failedCount,
    stoppedCount,
    sensorKey,
    message,
    startedSensors,
    skippedSensors,
    failedSensors,
  ];
}
