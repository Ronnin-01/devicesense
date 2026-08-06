/// Immutable snapshot of the device's Wi-Fi adapter hardware capabilities.
///
/// All fields are available without any runtime permission — they describe
/// what the hardware supports, not what network you are connected to.
class WifiCapabilitiesModel {
  const WifiCapabilitiesModel({
    required this.wifiSupported,
    required this.wifiEnabled,
    required this.wifiState,
    required this.scanAlwaysAvailable,
    required this.is5GHzSupported,
    required this.is6GHzSupported,
    required this.isWifiDirectSupported,
    required this.isWpa3SaeSupported,
    required this.isWpa3SuiteBSupported,
    required this.isEnhancedOpenSupported,
  });

  final bool wifiSupported;
  final bool wifiEnabled;

  /// ENABLED / ENABLING / DISABLED / DISABLING / UNKNOWN
  final String wifiState;

  final bool scanAlwaysAvailable;
  final bool is5GHzSupported;

  /// Wi-Fi 6E — API 30+; false on older devices.
  final bool is6GHzSupported;

  /// Wi-Fi Direct (P2P) — API 30+; false on older devices.
  final bool isWifiDirectSupported;

  /// WPA3-Personal (SAE) — API 29+; false on older devices.
  final bool isWpa3SaeSupported;

  /// WPA3-Enterprise Suite-B — API 29+; false on older devices.
  final bool isWpa3SuiteBSupported;

  /// Enhanced Open (OWE) — API 29+; false on older devices.
  final bool isEnhancedOpenSupported;

  factory WifiCapabilitiesModel.fromMap(Map<String, dynamic> map) {
    return WifiCapabilitiesModel(
      wifiSupported: map['wifiSupported'] as bool? ?? false,
      wifiEnabled: map['wifiEnabled'] as bool? ?? false,
      wifiState: map['wifiState'] as String? ?? 'UNKNOWN',
      scanAlwaysAvailable: map['scanAlwaysAvailable'] as bool? ?? false,
      is5GHzSupported: map['is5GHzSupported'] as bool? ?? false,
      is6GHzSupported: map['is6GHzSupported'] as bool? ?? false,
      isWifiDirectSupported: map['isWifiDirectSupported'] as bool? ?? false,
      isWpa3SaeSupported: map['isWpa3SaeSupported'] as bool? ?? false,
      isWpa3SuiteBSupported: map['isWpa3SuiteBSupported'] as bool? ?? false,
      isEnhancedOpenSupported: map['isEnhancedOpenSupported'] as bool? ?? false,
    );
  }
}
