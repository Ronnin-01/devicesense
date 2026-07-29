import 'package:devicesense/features/pages/paired_device_page.dart';
import 'package:devicesense/features/pages/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/pages/battery_page.dart';
import '../features/pages/battery_trends_page.dart';
import '../features/pages/bluetooth_info_page.dart';
import '../features/pages/dashboard.dart';
import '../features/pages/device_info_page.dart';
import '../features/shared/widgets.dart';

class AppRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const DashboardPage()),
      GoRoute(path: '/device-info', builder: (_, _) => const DeviceInfoPage()),
      GoRoute(path: '/battery', builder: (_, _) => const BatteryInfoPage()),
      GoRoute(
        path: '/battery/trends',
        builder: (_, _) => const BatteryTrendsPage(),
      ),
      GoRoute(path: '/permissions', builder: (_, _) => const PermissionPage()),
      GoRoute(path: '/bluetooth', builder: (_, _) => const BluetoothInfoPage()),
      GoRoute(
        path: '/bluetooth/paired-devices',
        builder: (_, _) => const PairedDevicesPage(),
      ),
      GoRoute(
        path: '/wifi',
        builder: (_, _) => const ComingSoonPage(
          title: 'Wi-Fi',
          icon: Icons.wifi_rounded,
          color: Color(0xFFFF6D00),
          description:
              'Signal strength, SSID, IP address and link speed will show '
              'up here once Wi-Fi support is wired up.',
        ),
      ),
      GoRoute(
        path: '/nfc',
        builder: (_, _) => const ComingSoonPage(
          title: 'NFC',
          icon: Icons.nfc_rounded,
          color: Color(0xFF6200EA),
          description:
              'NFC availability and tag reads will show up here once NFC '
              'support is wired up.',
        ),
      ),
      GoRoute(
        path: '/sensors',
        builder: (_, _) => const ComingSoonPage(
          title: 'Sensors',
          icon: Icons.sensors_rounded,
          color: Color(0xFFD50000),
          description:
              'Accelerometer, gyroscope, proximity and other sensor '
              'readings will show up here once sensor support is wired up.',
        ),
      ),
    ],
  );
}
