import 'package:flutter/material.dart';

import '../../core/permissions/permission_type.dart';

/// Immutable metadata describing a runtime permission.
///
/// This class contains presentation information only.
/// It does NOT contain permission state.
@immutable
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

/// Central catalogue of every runtime permission supported
/// by Device Sense.
///
/// Every screen in the application should use this list instead
/// of hardcoded titles or icons.
abstract final class PermissionCatalog {
  static const permissions = <PermissionMetadata>[
    PermissionMetadata(
      type: PermissionType.bluetoothConnect,
      title: 'Bluetooth Connect',
      description:
          'Allows Device Sense to communicate with paired Bluetooth devices.',
      icon: Icons.bluetooth_connected,
    ),

    PermissionMetadata(
      type: PermissionType.bluetoothScan,
      title: 'Bluetooth Scan',
      description: 'Allows Device Sense to discover nearby Bluetooth devices.',
      icon: Icons.bluetooth_searching,
    ),

    PermissionMetadata(
      type: PermissionType.camera,
      title: 'Camera',
      description: 'Required for barcode and QR code scanning features.',
      icon: Icons.photo_camera_outlined,
    ),

    PermissionMetadata(
      type: PermissionType.microphone,
      title: 'Microphone',
      description:
          'Allows recording audio when future voice features are added.',
      icon: Icons.mic_none_outlined,
    ),

    PermissionMetadata(
      type: PermissionType.location,
      title: 'Location',
      description:
          'Required on some Android versions for nearby device discovery.',
      icon: Icons.location_on_outlined,
    ),

    PermissionMetadata(
      type: PermissionType.notification,
      title: 'Notifications',
      description:
          'Allows Device Sense to send important alerts and background updates.',
      icon: Icons.notifications_outlined,
    ),
  ];
}
