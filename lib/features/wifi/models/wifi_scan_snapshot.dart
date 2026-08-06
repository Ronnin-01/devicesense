import 'wifi_network_model.dart';

/// Immutable snapshot of the current Wi-Fi scan state emitted by
/// [WifiScanRepository] on every event from the native side.
class WifiScanSnapshot {
  const WifiScanSnapshot({
    required this.networks,
    required this.wifiState,
    required this.isScanning,
    required this.lastUpdated,
    this.scanError,
    this.fromCache,
  });

  /// Nearby networks found in the most recent scan, sorted by RSSI
  /// (strongest first).
  final List<WifiNetworkModel> networks;

  /// ENABLED / ENABLING / DISABLED / DISABLING / UNKNOWN
  final String wifiState;

  /// Whether a scan is currently in progress.
  final bool isScanning;

  final DateTime lastUpdated;

  /// Non-null when the native side emitted a "scanError" event.
  /// Codes: PERMISSION_DENIED / LOCATION_SERVICES_DISABLED /
  ///        WIFI_DISABLED / THROTTLED
  /// Cleared to null when a new scan starts successfully.
  final String? scanError;

  /// True if the most recent results came from the OS cache (throttled),
  /// false if they came from a fresh scan. Null before the first result.
  final bool? fromCache;

  WifiScanSnapshot copyWith({
    List<WifiNetworkModel>? networks,
    String? wifiState,
    bool? isScanning,
    DateTime? lastUpdated,
    Object? scanError = _keep,
    Object? fromCache = _keep,
  }) {
    return WifiScanSnapshot(
      networks: networks ?? this.networks,
      wifiState: wifiState ?? this.wifiState,
      isScanning: isScanning ?? this.isScanning,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      scanError: scanError == _keep ? this.scanError : scanError as String?,
      fromCache: fromCache == _keep ? this.fromCache : fromCache as bool?,
    );
  }

  factory WifiScanSnapshot.initial() {
    return WifiScanSnapshot(
      networks: const [],
      wifiState: 'UNKNOWN',
      isScanning: false,
      lastUpdated: DateTime.now(),
      scanError: null,
      fromCache: null,
    );
  }
}

const Object _keep = Object();
