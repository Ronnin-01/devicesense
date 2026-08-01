/// Represents one Bluetooth device found during discovery.
///
/// Works for both Classic (event: "deviceUpdate") and BLE
/// (event: "bleDeviceUpdate") devices — the native side sends the
/// same map shape for both, differentiated only by [source].
class BluetoothDeviceModel {
  const BluetoothDeviceModel({
    required this.name,
    required this.address,
    required this.shortAddress,
    required this.rssi,
    required this.signalStrength,
    required this.type,
    required this.bondState,
    required this.deviceClass,
    required this.source,
    required this.category,
    required this.timestamp,
  });

  final String name;
  final String address;

  /// Last 5 characters of [address] — used as display-name fallback
  /// for nameless BLE devices instead of "Unknown Device".
  final String shortAddress;

  final int rssi;

  /// Human-readable signal label: "Excellent" | "Good" | "Fair" |
  /// "Weak" | "Unknown". Computed on the native side.
  final String signalStrength;

  final String type;
  final String bondState;
  final String deviceClass;

  /// "classic" for devices found via Classic discovery,
  /// "ble" for devices found via BluetoothLeScanner.
  final String source;
  final String category;

  final int timestamp;

  factory BluetoothDeviceModel.fromJson(Map<String, dynamic> json) {
    return BluetoothDeviceModel(
      name: json['name'] as String? ?? 'Unknown Device',
      address: json['address'] as String? ?? '',
      shortAddress: json['shortAddress'] as String? ?? '',
      rssi: json['rssi'] as int? ?? 0,
      signalStrength: json['signalStrength'] as String? ?? 'Unknown',
      type: json['type'] as String? ?? 'Unknown',
      bondState: json['bondState'] as String? ?? 'Unknown',

      // Native still sends the key as 'class' — unchanged.
      deviceClass: json['class'] as String? ?? 'Unknown',

      source: json['source'] as String? ?? 'classic',
      category: json['category'] as String? ?? 'Unknown',
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  BluetoothDeviceModel copyWith({
    String? name,
    String? address,
    String? shortAddress,
    int? rssi,
    String? signalStrength,
    String? type,
    String? bondState,
    String? deviceClass,
    String? source,
    String? category,
    int? timestamp,
  }) {
    return BluetoothDeviceModel(
      name: name ?? this.name,
      address: address ?? this.address,
      shortAddress: shortAddress ?? this.shortAddress,
      rssi: rssi ?? this.rssi,
      signalStrength: signalStrength ?? this.signalStrength,
      type: type ?? this.type,
      bondState: bondState ?? this.bondState,
      deviceClass: deviceClass ?? this.deviceClass,
      source: source ?? this.source,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // Equality is by address — two events for the same hardware device
  // should resolve to the same model regardless of updated RSSI.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BluetoothDeviceModel && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() =>
      'BluetoothDeviceModel('
      'name: $name, '
      'address: $address, '
      'rssi: $rssi ($signalStrength), '
      'type: $type, '
      'source: $source, '
      'bondState: $bondState, '
      'class: $deviceClass, '
      'category: $category'
      ')';
}
