import 'package:flutter/services.dart';

/// Thin wrapper around the `device_sense/native` platform channel.
///
/// This is the only file that knows a [MethodChannel] exists — every
/// layer above it (repositories, blocs, widgets) only ever sees a plain
/// `Future<Map<String, dynamic>>`.
class NativeChannel {
  NativeChannel._();

  static const String _channelName = 'device_sense/native';
  static const MethodChannel _channel = MethodChannel(_channelName);

  /// Reads publicly-documented device build info from the native side.
  /// Throws a [PlatformException] if the native handler reports an error.
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
}
