import 'package:flutter/services.dart';

import '../permissions/permission_status.dart';
import '../permissions/permission_type.dart';

class NativeChannel {
  NativeChannel._();

  static const String _channelName = 'device_sense/native';
  static const MethodChannel _channel = MethodChannel(_channelName);

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getDeviceInfo',
    );

    return result ?? {};
  }

  static Future<Map<String, dynamic>> getBatteryInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getBatteryInfo',
    );

    return result ?? {};
  }

  /// Reads the background-collected battery history, oldest first.
  /// Read-only — nothing on the Dart side ever writes to this history;
  /// only the native `BatterySamplingWorker` appends new samples.
  static Future<List<Map<String, dynamic>>> getBatteryHistory() async {
    final result = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'getBatteryHistory',
    );

    if (result == null) return [];

    return result
        .map(
          (entry) => entry.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  static Future<Map<String, dynamic>> getBluetoothInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getBluetoothCapabilities',
    );

    return result ?? {};
  }

  static Future<PermissionStatus> check(PermissionType permission) async {
    final String value = await _channel.invokeMethod('permission', {
      'action': 'check',
      'permission': permission.name,
    });

    return PermissionStatus.values.firstWhere((e) => e.name == value);
  }

  static Future<PermissionStatus> request(PermissionType permission) async {
    final String value = await _channel.invokeMethod('permission', {
      'action': 'request',
      'permission': permission.name,
    });

    return PermissionStatus.values.firstWhere((e) => e.name == value);
  }

  static Future<void> openSettings() {
    return _channel.invokeMethod('permission', {'action': 'openSettings'});
  }

  static Future<Map<String, dynamic>> getPairedDevices() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getPairedDevices',
    );

    return result ?? {};
  }

  static Future<Map<String, dynamic>> getConnectedDevices() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getConnectedDevices',
    );

    return result ?? {};
  }
}
