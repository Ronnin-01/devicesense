import 'package:devicesense/features/pages/paired_device_page.dart';
import 'package:devicesense/features/pages/permission_page.dart';
import 'package:devicesense/features/pages/sensor_capabilities_page.dart';
import 'package:devicesense/features/pages/wifi_capabilities_page.dart';
import 'package:go_router/go_router.dart';
import '../features/pages/battery_page.dart';
import '../features/pages/battery_trends_page.dart';
import '../features/pages/bluetooth_discovery_page.dart';
import '../features/pages/bluetooth_info_page.dart';
import '../features/pages/dashboard.dart';
import '../features/pages/device_info_page.dart';
import '../features/pages/nfc_page.dart';
import '../features/pages/sensor_stream_page.dart';
import '../features/pages/wifi_scan_page.dart';

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
        path: '/bluetooth/bt-discovery',
        builder: (_, _) => const BluetoothDiscoveryPage(),
      ),
      GoRoute(path: '/wifi', builder: (_, _) => const WifiCapabilitiesPage()),
      GoRoute(path: '/wifi/scan', builder: (_, _) => const WifiScanPage()),
      GoRoute(path: '/nfc', builder: (_, _) => const NfcPage()),
      GoRoute(
        path: '/sensors',
        builder: (_, _) => const SensorsCapabilitiesPage(),
      ),
      GoRoute(
        path: '/sensors/stream',
        builder: (_, _) => const SensorsStreamPage(),
      ),
    ],
  );
}
