/// Immutable model for one nearby Wi-Fi access point discovered during
/// a scan. Maps directly to a single entry in the native "networks" list
/// inside a "scanResults" event.
class WifiNetworkModel {
  const WifiNetworkModel({
    required this.ssid,
    required this.bssid,
    required this.rssi,
    required this.signalStrength,
    required this.signalLevel,
    required this.frequencyMHz,
    required this.band,
    required this.channel,
    required this.channelWidthMHz,
    required this.capabilities,
    required this.securityType,
    required this.isHidden,
    required this.isPasspoint,
    required this.operatorFriendlyName,
    required this.timestamp,
  });

  /// Network name. Empty string for hidden networks.
  final String ssid;

  /// Access point MAC address.
  final String bssid;

  /// Signal strength in dBm.
  final int rssi;

  /// Excellent / Good / Fair / Weak / Very Weak.
  final String signalStrength;

  /// 0–4 bar scale.
  final int signalLevel;

  /// Center frequency of the channel in MHz.
  final int frequencyMHz;

  /// "2.4 GHz" / "5 GHz" / "6 GHz" / "Unknown".
  final String band;

  /// Wi-Fi channel number derived from frequency (-1 if unknown).
  final int channel;

  /// "20 MHz" / "40 MHz" / "80 MHz" / "160 MHz" / "80+80 MHz" / "Unknown".
  /// Empty string on API < 23.
  final String channelWidthMHz;

  /// Raw capabilities string from the OS — e.g. "[WPA2-PSK][ESS]".
  final String capabilities;

  /// Parsed security type: WPA3 / WPA2 / WPA / WEP / Enhanced Open (OWE)
  /// / Open / Unknown.
  final String securityType;

  /// Whether the network does not broadcast its SSID.
  final bool isHidden;

  /// Whether this is a Passpoint (Hotspot 2.0) network.
  final bool isPasspoint;

  /// Carrier-provided friendly name for this hotspot — empty if none.
  final String operatorFriendlyName;

  /// Epoch milliseconds when this result was received on the native side.
  final int timestamp;

  factory WifiNetworkModel.fromMap(Map<String, dynamic> map) {
    return WifiNetworkModel(
      ssid: map['ssid'] as String? ?? '',
      bssid: map['bssid'] as String? ?? '',
      rssi: map['rssi'] as int? ?? 0,
      signalStrength: map['signalStrength'] as String? ?? 'Unknown',
      signalLevel: map['signalLevel'] as int? ?? 0,
      frequencyMHz: map['frequencyMHz'] as int? ?? 0,
      band: map['band'] as String? ?? 'Unknown',
      channel: map['channel'] as int? ?? -1,
      channelWidthMHz: map['channelWidthMHz'] as String? ?? '',
      capabilities: map['capabilities'] as String? ?? '',
      securityType: map['securityType'] as String? ?? 'Unknown',
      isHidden: map['isHidden'] as bool? ?? false,
      isPasspoint: map['isPasspoint'] as bool? ?? false,
      operatorFriendlyName: map['operatorFriendlyName'] as String? ?? '',
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }

  /// Equality by BSSID — two scan results for the same physical access
  /// point are the same model regardless of updated RSSI.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WifiNetworkModel && other.bssid == bssid;

  @override
  int get hashCode => bssid.hashCode;

  @override
  String toString() =>
      'WifiNetworkModel(ssid: $ssid, bssid: $bssid, '
      'rssi: $rssi, band: $band, security: $securityType)';
}
