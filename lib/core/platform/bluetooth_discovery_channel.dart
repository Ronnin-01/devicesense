// import 'dart:async';
// import 'package:flutter/services.dart';

// class BluetoothDiscoveryChannel {
//   BluetoothDiscoveryChannel._();

//   static const EventChannel _channel = EventChannel(
//     'device_sense/bluetooth_discovery',
//   );

//   static Stream<Map<String, dynamic>> get events {
//     return _channel.receiveBroadcastStream().map((event) {
//       return Map<String, dynamic>.from(event);
//     });
//   }
// }
