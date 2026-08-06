import 'dart:async';

import '../../../core/platform/native_channel.dart';
import '../../../features/bluetooth_info/models/bluetooth_device_model.dart';
import '../../../features/bluetooth_info/models/bluetooth_discovery_snapshot.dart';
import 'bluetooth_repository.dart';

/// Translates raw native Bluetooth events into a stream of immutable
/// [BluetoothDiscoverySnapshot]s consumed by [BluetoothDiscoveryBloc].
///
/// Single Responsibility: this class owns event routing and device-list
/// state. It knows nothing about Flutter widgets or Bloc events.
class BluetoothRepositoryImpl implements BluetoothRepository {
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

  // ---- Public API -------------------------------------------------------

  @override
  Future<void> startDiscovery() async {
    if (_disposed) {
      throw StateError('BluetoothRepositoryImpl has already been disposed.');
    }

    await stopDiscovery();

    _bluetoothSubscription = NativeChannel.bluetoothDiscoveryStream().listen(
      _handleBluetoothEvent,
      onError: (Object error, StackTrace stackTrace) {
        _emitError('STREAM_ERROR', error.toString());
      },
    );
  }

  @override
  Future<void> stopDiscovery() async {
    await _bluetoothSubscription?.cancel();
    _bluetoothSubscription = null;
  }

  @override
  Future<bool> startNativeScan() async {
    if (_disposed) {
      throw StateError('BluetoothRepositoryImpl has already been disposed.');
    }

    return NativeChannel.startBluetoothDiscovery();
  }

  @override
  Future<bool> stopNativeScan() async {
    if (_disposed) return false;

    final stopped = await NativeChannel.stopBluetoothDiscovery();

    _isScanning = false;
    _snapshot = _snapshot.copyWith(
      scanProgressElapsed: null,
      scanProgressTotal: null,
    );

    _emitSnapshot();

    return stopped;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await stopDiscovery();
    await _snapshotController.close();
  }

  // ---- Event routing ----------------------------------------------------

  void _handleBluetoothEvent(Map<String, dynamic> event) {
    final String eventType = event['event'] as String? ?? '';

    switch (eventType) {
      case 'adapterState':
        _handleAdapterState(event);

      case 'scanStarted':
        _handleScanStarted();

      case 'scanFinished':
        _handleScanFinished(event);

      // Classic device — same handler as BLE since the map shape is
      // identical. Differentiated by device.source ("classic") inside
      // the model if the UI needs to show a badge.
      case 'deviceUpdate':
        _handleDeviceEvent(event);

      // BLE device — new in the updated native handler. Same map shape
      // as "deviceUpdate", source field will be "ble".
      case 'bleDeviceUpdate':
        _handleDeviceEvent(event);

      // Native emitted a permission/adapter/BLE scan error. Surface it
      // in the snapshot so the Bloc can drive an error UI state and
      // prompt the user to grant the permission.
      case 'scanError':
        _handleScanError(event);

      // Classic discovery progress tick (every second, 0–12s).
      // Optional to use — drives a LinearProgressIndicator in the UI.
      case 'scanProgress':
        _handleScanProgress(event);

      // A device's pairing state changed while the stream was open.
      // Update the device in the map if we already know about it.
      case 'bondStateChanged':
        _handleBondStateChanged(event);

      case 'scanStopped':
        _handleScanStopped(event);
        break;

      // Unknown / future event types — ignore gracefully.
      default:
        break;
    }
  }

  // ---- Individual handlers ----------------------------------------------

  void _handleAdapterState(Map<String, dynamic> event) {
    _adapterState = event['state'] as String? ?? 'UNKNOWN';

    if (_adapterState == 'OFF' ||
        _adapterState == 'TURNING_OFF' ||
        _adapterState == 'UNSUPPORTED') {
      _isScanning = false;
      _devices.clear();
    }

    _emitSnapshot();
  }

  void _handleScanStarted() {
    _isScanning = true;
    _devices.clear();

    // Clear any previous error when a new scan begins successfully.
    _snapshot = _snapshot.copyWith(
      scanError: null,
      scanProgressElapsed: 0,
      scanProgressTotal: 12,
    );

    _emitSnapshot();
  }

  void _handleScanFinished(Map<String, dynamic> event) {
    _isScanning = false;

    // Clear progress once done.
    _snapshot = _snapshot.copyWith(
      scanProgressElapsed: null,
      scanProgressTotal: null,
    );

    _emitSnapshot();
  }

  void _handleScanStopped(Map<String, dynamic> event) {
    _isScanning = false;
    _snapshot = _snapshot.copyWith(
      scanProgressElapsed: null,
      scanProgressTotal: null,
    );
    _emitSnapshot();
  }

  /// Handles both "deviceUpdate" (classic) and "bleDeviceUpdate" (BLE).
  /// The map shape is identical — only device.source differs.
  void _handleDeviceEvent(Map<String, dynamic> event) {
    final deviceJson = event['device'];
    if (deviceJson == null) return;

    final device = BluetoothDeviceModel.fromJson(
      Map<String, dynamic>.from(deviceJson as Map),
    );

    // Insert or replace — using address as the stable key means an
    // updated RSSI reading for an already-seen device just overwrites
    // the previous entry rather than adding a duplicate.
    _devices[device.address] = device;

    _emitSnapshot();
  }

  void _handleScanError(Map<String, dynamic> event) {
    final code = event['code'] as String? ?? 'UNKNOWN';
    final message = event['message'] as String? ?? 'An unknown error occurred';
    _isScanning = false;

    _emitError(code, message);
  }

  void _handleScanProgress(Map<String, dynamic> event) {
    final elapsed = event['elapsedSeconds'] as int?;
    final total = event['totalSeconds'] as int?;
    if (elapsed == null || total == null) return;

    _snapshot = _snapshot.copyWith(
      scanProgressElapsed: elapsed,
      scanProgressTotal: total,
    );

    _emitSnapshot();
  }

  void _handleBondStateChanged(Map<String, dynamic> event) {
    final address = event['address'] as String?;
    final bondState = event['bondState'] as String?;
    if (address == null || bondState == null) return;

    final existing = _devices[address];
    if (existing == null) return; // device not in this scan session — ignore

    _devices[address] = existing.copyWith(bondState: bondState);
    _emitSnapshot();
  }

  // ---- Snapshot emission ------------------------------------------------

  void _emitSnapshot() {
    if (_disposed || _snapshotController.isClosed) return;

    final sorted = _devices.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    _snapshot = _snapshot.copyWith(
      devices: List.unmodifiable(sorted),
      adapterState: _adapterState,
      isScanning: _isScanning,
      lastUpdated: DateTime.now(),
    );

    _snapshotController.add(_snapshot);
  }

  void _emitError(String code, String message) {
    if (_disposed || _snapshotController.isClosed) return;

    _snapshot = _snapshot.copyWith(
      scanError: '$code: $message',
      isScanning: false,
      lastUpdated: DateTime.now(),
    );

    _snapshotController.add(_snapshot);
  }

  @override
  Stream<BluetoothDiscoverySnapshot> get discoveryStream => snapshotStream;
}
