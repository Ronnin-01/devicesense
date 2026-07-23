import 'package:flutter/services.dart';

class NativeChannel {
  NativeChannel._();

  static const MethodChannel _channel = MethodChannel('device_sense/native');

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getDeviceInfo',
    );

    return result ?? {};
  }
}
