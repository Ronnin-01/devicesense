class BluetoothDeviceModel {
  final String name;
  final String address;
  final int rssi;
  final String type;
  final String bondState;
  final String deviceClass;
  final int timestamp;

  const BluetoothDeviceModel({
    required this.name,
    required this.address,
    required this.rssi,
    required this.type,
    required this.bondState,
    required this.deviceClass,
    required this.timestamp,
  });

  factory BluetoothDeviceModel.fromJson(Map<String, dynamic> json) {
    return BluetoothDeviceModel(
      name: json['name'] ?? 'Unknown Device',

      address: json['address'] ?? '',

      rssi: json['rssi'] ?? 0,

      type: json['type'] ?? 'Unknown',

      bondState: json['bondState'] ?? 'Unknown',

      deviceClass: json['class'] ?? 'Unknown',

      timestamp: json['timestamp'] ?? 0,
    );
  }

  BluetoothDeviceModel copyWith({
    String? name,

    String? address,

    int? rssi,

    String? type,

    String? bondState,

    String? deviceClass,

    int? timestamp,
  }) {
    return BluetoothDeviceModel(
      name: name ?? this.name,

      address: address ?? this.address,

      rssi: rssi ?? this.rssi,

      type: type ?? this.type,

      bondState: bondState ?? this.bondState,

      deviceClass: deviceClass ?? this.deviceClass,

      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BluetoothDeviceModel && other.address == address;
  }

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() {
    return '''
BluetoothDeviceModel(
 name: $name,
 address: $address,
 rssi: $rssi,
 type: $type,
 bondState: $bondState,
 class: $deviceClass
)
''';
  }
}
