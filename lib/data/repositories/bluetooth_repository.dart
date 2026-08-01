// ignore_for_file: avoid_print

import 'dart:async';

import '../../features/battery_info/models/bluetooth_device_model.dart';
import '../../../core/platform/native_channel.dart';
import '../../features/battery_info/models/bluetooth_discovery_snapshot.dart';

class BluetoothRepository {
  final Map<String, BluetoothDeviceModel> _devices = {};

  bool _isScanning = false;
  bool _disposed = false;

  String _adapterState = 'UNKNOWN';

  BluetoothDiscoverySnapshot _snapshot = BluetoothDiscoverySnapshot.initial();

  final StreamController<BluetoothDiscoverySnapshot> _snapshotController =
      StreamController<BluetoothDiscoverySnapshot>.broadcast();

  StreamSubscription? _bluetoothSubscription;

  Stream<BluetoothDiscoverySnapshot> get snapshotStream =>
      _snapshotController.stream;

  // ------------------------------------------------------------
  // Start listening to native Bluetooth events
  // ------------------------------------------------------------

  Future<void> startDiscovery() async {
    stopDiscovery();

    _bluetoothSubscription = NativeChannel.bluetoothDiscoveryStream().listen(
      _handleBluetoothEvent,
      onError: (error) {
        print(error);
      },
    );
  }

  // ------------------------------------------------------------
  // Stop listening
  // ------------------------------------------------------------

  Future<void> stopDiscovery() async {
    await _bluetoothSubscription?.cancel();
    _bluetoothSubscription = null;
  }

  // ------------------------------------------------------------
  // Process native events
  // ------------------------------------------------------------

  void _handleBluetoothEvent(Map<String, dynamic> event) {
    final String eventType = event['event'] ?? '';

    switch (eventType) {
      case 'adapterState':
        _handleAdapterState(event);
        break;

      case 'scanStarted':
        _handleScanStarted();
        break;

      case 'scanFinished':
        _handleScanFinished();
        break;

      case 'deviceAdded':
        _handleDeviceAdded(event);
        break;

      case 'deviceUpdate':
        _handleDeviceUpdated(event);
        break;
    }
  }

  void _handleAdapterState(Map<String, dynamic> event) {
    _adapterState = event['state'] ?? 'UNKNOWN';

    if (_adapterState == 'OFF') {
      _devices.clear();

      _emitSnapshot();
    }
    _emitSnapshot();
  }

  void _handleScanStarted() {
    _isScanning = true;

    _emitSnapshot();
  }

  void _handleScanFinished() {
    _isScanning = false;

    _emitSnapshot();
  }
  // ------------------------------------------------------------
  // Add or update device
  // ------------------------------------------------------------

  void _handleDeviceAdded(Map<String, dynamic> event) {
    final deviceJson = event['device'];

    if (deviceJson == null) return;

    final device = BluetoothDeviceModel.fromJson(
      Map<String, dynamic>.from(deviceJson),
    );

    _devices[device.address] = device;

    _emitSnapshot();
  }

  void _handleDeviceUpdated(Map<String, dynamic> event) {
    final deviceJson = event['device'];

    if (deviceJson == null) return;

    final device = BluetoothDeviceModel.fromJson(
      Map<String, dynamic>.from(deviceJson),
    );

    _devices[device.address] = device;

    _emitSnapshot();
  }

  // ------------------------------------------------------------
  // Send updated list
  // ------------------------------------------------------------

  void _emitSnapshot() {
    final devices = _devices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    _snapshot = _snapshot.copyWith(
      devices: List.unmodifiable(devices),
      adapterState: _adapterState,
      isScanning: _isScanning,
      lastUpdated: DateTime.now(),
    );

    if (_disposed) return;

    if (_snapshotController.isClosed) return;

    _snapshotController.add(_snapshot);
  }

  // ------------------------------------------------------------
  // Cleanup
  // ------------------------------------------------------------

  void dispose() {
    if (_disposed) return;

    _disposed = true;

    stopDiscovery();

    _snapshotController.close();
  }
}
