/// Immutable snapshot of the currently connected Wi-Fi network.
///
/// SSID and BSSID are redacted by the OS to placeholder values when
/// ACCESS_FINE_LOCATION is not granted — check [hasLocationPermission]
/// before displaying them.
class WifiInfoModel {
  const WifiInfoModel({
    required this.connected,
    required this.wifiEnabled,
    required this.hasLocationPermission,
    required this.hasNearbyWifiPermission,
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.signalStrength,
    required this.signalLevel,
    required this.linkSpeedMbps,
    required this.frequencyMHz,
    required this.band,
    required this.ipAddress,
    required this.networkId,
    required this.hiddenSsid,
    required this.macAddress,
  });

  /// Whether the device is currently connected to a Wi-Fi network.
  final bool connected;

  /// Whether Wi-Fi is currently switched on.
  final bool wifiEnabled;

  /// Whether ACCESS_FINE_LOCATION was granted when this snapshot was
  /// taken. If false, [ssid] and [bssid] contain placeholder values.
  final bool hasLocationPermission;

  final bool hasNearbyWifiPermission;

  /// Network name — "Permission required" if location not granted.
  final String ssid;

  /// Access point MAC address — "Permission required" if location not
  /// granted. Always "02:00:00:00:00:00" on API 29+ for privacy.
  final String bssid;

  /// Received signal strength in dBm — always available, never redacted.
  final int rssi;

  /// Human-readable signal label: Excellent / Good / Fair / Weak / Very Weak.
  final String signalStrength;

  /// 0–4 bar scale computed from [rssi].
  final int signalLevel;

  /// Current link speed in Mbps.
  final int linkSpeedMbps;

  /// Center frequency of the channel in MHz.
  final int frequencyMHz;

  /// Human-readable band: "2.4 GHz" / "5 GHz" / "6 GHz" / "Unknown".
  final String band;

  /// Device's local IPv4 address on this network.
  final String ipAddress;

  /// Internal OS network identifier (-1 if not connected).
  final int networkId;

  /// Whether the access point does not broadcast its SSID.
  final bool hiddenSsid;

  /// Hardware MAC address — always "02:00:00:00:00:00" on API 23+ for
  /// privacy. Included for transparency/educational purposes.
  final String macAddress;

  factory WifiInfoModel.notConnected({required bool wifiEnabled}) {
    return WifiInfoModel(
      connected: false,
      wifiEnabled: wifiEnabled,
      hasLocationPermission: false,
      hasNearbyWifiPermission: false,
      ssid: '',
      bssid: '',
      rssi: 0,
      signalStrength: '',
      signalLevel: 0,
      linkSpeedMbps: 0,
      frequencyMHz: 0,
      band: '',
      ipAddress: '',
      networkId: -1,
      hiddenSsid: false,
      macAddress: '',
    );
  }

  factory WifiInfoModel.fromMap(Map<String, dynamic> map) {
    final connected = map['connected'] as bool? ?? false;
    final wifiEnabled = map['wifiEnabled'] as bool? ?? false;

    if (!connected) {
      return WifiInfoModel.notConnected(wifiEnabled: wifiEnabled);
    }

    return WifiInfoModel(
      connected: connected,
      wifiEnabled: wifiEnabled,
      hasLocationPermission: map['hasLocationPermission'] as bool? ?? false,
      hasNearbyWifiPermission: map['hasNearbyWifiPermission'] as bool? ?? false,
      ssid: map['ssid'] as String? ?? '',
      bssid: map['bssid'] as String? ?? '',
      rssi: map['rssi'] as int? ?? 0,
      signalStrength: map['signalStrength'] as String? ?? '',
      signalLevel: map['signalLevel'] as int? ?? 0,
      linkSpeedMbps: map['linkSpeedMbps'] as int? ?? 0,
      frequencyMHz: map['frequencyMHz'] as int? ?? 0,
      band: map['band'] as String? ?? '',
      ipAddress: map['ipAddress'] as String? ?? '',
      networkId: map['networkId'] as int? ?? -1,
      hiddenSsid: map['hiddenSsid'] as bool? ?? false,
      macAddress: map['macAddress'] as String? ?? '',
    );
  }
}
