import 'package:flutter/material.dart';

import '../../core/permissions/permission_type.dart';

class PermissionMetadata {
  const PermissionMetadata({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });

  final PermissionType type;
  final String title;
  final String description;
  final IconData icon;
}

class PermissionCatalog {
  PermissionCatalog._();

  static const List<PermissionMetadata> permissions = [
    PermissionMetadata(
      type: PermissionType.location,
      title: 'Location Services',
      description:
          'Required to scan for nearby Wi-Fi access points and get actual SSID/BSSID names.',
      icon: Icons.location_on_rounded,
    ),
    PermissionMetadata(
      type: PermissionType.nearbyWifiDevices,
      title: 'Nearby Wi-Fi Devices',
      description:
          'Required on Android 13+ to interact with local Wi-Fi networks without full location tracking.',
      icon: Icons.wifi_find_rounded,
    ),
    PermissionMetadata(
      type: PermissionType.bluetoothConnect,
      title: 'Bluetooth Connect',
      description:
          'Allows the app to connect to paired Bluetooth devices and read hardware states.',
      icon: Icons.bluetooth_connected_rounded,
    ),
    PermissionMetadata(
      type: PermissionType.bluetoothScan,
      title: 'Bluetooth Scan',
      description:
          'Required to discover new, unpaired Bluetooth Classic and BLE devices in the area.',
      icon: Icons.bluetooth_searching_rounded,
    ),
    PermissionMetadata(
      type: PermissionType.sensors,
      title: 'Body & Hardware Sensors',
      description:
          'Grants access to the accelerometer, gyroscope, and step counters.',
      icon: Icons.sensors_rounded,
    ),
    PermissionMetadata(
      type: PermissionType.camera,
      title: 'Camera Access',
      description:
          'Required for optical hardware analysis and barcode/QR scanning.',
      icon: Icons.camera_alt_rounded,
    ),
    PermissionMetadata(
      type: PermissionType.notification,
      title: 'System Notifications',
      description:
          'Allows background workers (like battery sampling) to post status updates.',
      icon: Icons.notifications_rounded,
    ),
  ];
}
