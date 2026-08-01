import 'bluetooth_device_model.dart';

/// Immutable snapshot of the current Bluetooth discovery state.
/// Emitted by [BluetoothRepository] every time any field changes.
class BluetoothDiscoverySnapshot {
  const BluetoothDiscoverySnapshot({
    required this.devices,
    required this.adapterState,
    required this.isScanning,
    required this.lastUpdated,
    this.scanError,
    this.scanProgressElapsed,
    this.scanProgressTotal,
  });

  final List<BluetoothDeviceModel> devices;
  final String adapterState;
  final bool isScanning;
  final DateTime lastUpdated;

  /// Non-null when the native side emitted a "scanError" event.
  /// Codes: "PERMISSION_DENIED" | "BLUETOOTH_DISABLED" | "BLE_SCAN_FAILED"
  /// Cleared to null when a new scan starts successfully.
  final String? scanError;

  /// Seconds elapsed in the current classic discovery window (0–12).
  /// Null when not scanning. Drive a LinearProgressIndicator with
  /// (scanProgressElapsed ?? 0) / (scanProgressTotal ?? 12).
  final int? scanProgressElapsed;

  /// Total classic discovery window in seconds — always 12, exposed
  /// here so the UI doesn't hardcode it.
  final int? scanProgressTotal;

  BluetoothDiscoverySnapshot copyWith({
    List<BluetoothDeviceModel>? devices,
    String? adapterState,
    bool? isScanning,
    DateTime? lastUpdated,

    // Nullable overrides: pass a sentinel to explicitly clear a field.
    // Using a wrapper lets copyWith distinguish "not passed" from "set to null".
    Object? scanError = _keep,
    Object? scanProgressElapsed = _keep,
    Object? scanProgressTotal = _keep,
  }) {
    return BluetoothDiscoverySnapshot(
      devices: devices ?? this.devices,
      adapterState: adapterState ?? this.adapterState,
      isScanning: isScanning ?? this.isScanning,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      scanError: scanError == _keep ? this.scanError : scanError as String?,
      scanProgressElapsed: scanProgressElapsed == _keep
          ? this.scanProgressElapsed
          : scanProgressElapsed as int?,
      scanProgressTotal: scanProgressTotal == _keep
          ? this.scanProgressTotal
          : scanProgressTotal as int?,
    );
  }

  factory BluetoothDiscoverySnapshot.initial() {
    return BluetoothDiscoverySnapshot(
      devices: const [],
      adapterState: 'UNKNOWN',
      isScanning: false,
      lastUpdated: DateTime.now(),
      scanError: null,
      scanProgressElapsed: null,
      scanProgressTotal: null,
    );
  }
}

/// Sentinel value used by [BluetoothDiscoverySnapshot.copyWith] to
/// distinguish "caller didn't pass this field" from "caller passed null".
const Object _keep = Object();
