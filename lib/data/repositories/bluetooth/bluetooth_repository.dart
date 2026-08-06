import '../../../features/bluetooth_info/models/bluetooth_discovery_snapshot.dart';

abstract interface class BluetoothRepository {
  Stream<BluetoothDiscoverySnapshot> get discoveryStream;

  Future<void> startDiscovery();

  Future<void> stopDiscovery();

  Future<bool> startNativeScan();

  Future<bool> stopNativeScan();

  Future<void> dispose();
}
