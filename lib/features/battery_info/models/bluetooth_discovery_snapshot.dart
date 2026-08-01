import 'bluetooth_device_model.dart';

class BluetoothDiscoverySnapshot {
  const BluetoothDiscoverySnapshot({
    required this.devices,
    required this.adapterState,
    required this.isScanning,
    required this.lastUpdated,
  });

  final List<BluetoothDeviceModel> devices;

  final String adapterState;

  final bool isScanning;

  final DateTime lastUpdated;

  BluetoothDiscoverySnapshot copyWith({
    List<BluetoothDeviceModel>? devices,
    String? adapterState,
    bool? isScanning,
    DateTime? lastUpdated,
  }) {
    return BluetoothDiscoverySnapshot(
      devices: devices ?? this.devices,
      adapterState: adapterState ?? this.adapterState,
      isScanning: isScanning ?? this.isScanning,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory BluetoothDiscoverySnapshot.initial() {
    return BluetoothDiscoverySnapshot(
      devices: const [],
      adapterState: 'UNKNOWN',
      isScanning: false,
      lastUpdated: DateTime.now(),
    );
  }
}
