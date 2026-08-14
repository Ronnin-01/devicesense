import 'package:flutter/services.dart';

import '../permissions/permission_status.dart';
import '../permissions/permission_type.dart';

/// Single gateway between Dart and every native platform channel.
///
/// This is the only file in the project that knows platform-channel
/// names and invocation signatures. Every layer above this (repositories,
/// blocs, widgets) only ever sees plain Dart types — never [MethodChannel]
/// or [EventChannel] directly.
///
/// Sections:
///   - Channel declarations
///   - Device Info
///   - Battery
///   - Bluetooth capabilities
///   - Bluetooth discovery (EventChannel + control)
///   - Permissions
///   - Wi-Fi capabilities
///   - Wi-Fi info (connected network)
///   - Wi-Fi scan (EventChannel + control)
class NativeChannel {
  NativeChannel._();

  // ===========================================================================
  // Channel declarations
  // ===========================================================================

  /// Primary request/response channel — handles all [MethodHandler]s
  /// registered inside NativeBridge.kt.
  static const MethodChannel _channel = MethodChannel('device_sense/native');

  /// EventChannel that streams classic + BLE discovery events from
  /// [BluetoothDiscoveryHandler].
  static const EventChannel _bluetoothDiscoveryChannel = EventChannel(
    'device_sense/bluetooth_discovery',
  );

  /// MethodChannel for start/stop/status control of Bluetooth discovery —
  /// kept separate from the event stream so control calls never block it.
  static const MethodChannel _bluetoothDiscoveryControlChannel = MethodChannel(
    'device_sense/bluetooth_discovery_control',
  );

  /// EventChannel that streams Wi-Fi scan results from [WifiScanHandler].
  static const EventChannel _wifiScanChannel = EventChannel(
    'device_sense/wifi_scan',
  );

  /// MethodChannel for start/stop/status control of Wi-Fi scanning —
  /// mirrors the Bluetooth control channel pattern.
  static const MethodChannel _wifiScanControlChannel = MethodChannel(
    'device_sense/wifi_scan_control',
  );

  /// MethodChannel for start/stop/status control of NFC reader —
  static const EventChannel _nfcReaderChannel = EventChannel(
    'device_sense/nfc_reader',
  );

  /// MethodChannel for start/stop/status control of NFC reader —
  static const MethodChannel _nfcReaderControlChannel = MethodChannel(
    'device_sense/nfc_reader_control',
  );

  // Sensors channels
  static const String _sensorChannelName = 'device_sense/sensor';
  static const MethodChannel _sensorChannel = MethodChannel(_sensorChannelName);

  static const String _sensorStreamChannelName = 'device_sense/sensor_stream';
  static const EventChannel _sensorStreamChannel = EventChannel(
    _sensorStreamChannelName,
  );

  // ===========================================================================
  // Device Info
  // ===========================================================================

  /// Returns a single snapshot of device build info (manufacturer, model,
  /// SoC, SDK level, etc.). No permission required.
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getDeviceInfo',
    );

    return result ?? {};
  }

  // ===========================================================================
  // Battery
  // ===========================================================================

  /// Returns a single on-demand battery snapshot — level, charging state,
  /// health, voltage, temperature, electrical readings, and power-manager
  /// state. No permission required.
  static Future<Map<String, dynamic>> getBatteryInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getBatteryInfo',
    );

    return result ?? {};
  }

  /// Returns the background-collected battery history, oldest first.
  ///
  /// Read-only from the Dart side — only the native [BatterySamplingWorker]
  /// ever appends new samples. Sampled every 30 minutes, capped at ~31 days.
  static Future<List<Map<String, dynamic>>> getBatteryHistory() async {
    final result = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'getBatteryHistory',
    );

    if (result == null) return [];

    return result
        .map(
          (entry) => entry.map((key, value) => MapEntry(key.toString(), value)),
        )
        .toList();
  }

  // ===========================================================================
  // Bluetooth capabilities
  // ===========================================================================

  /// Returns static Bluetooth adapter capabilities — BLE support,
  /// 2M/Coded PHY, LE Audio, offloaded scanning, etc.
  /// No runtime permission required.
  static Future<Map<String, dynamic>> getBluetoothCapabilities() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getBluetoothCapabilities',
    );

    return result ?? {};
  }

  /// Returns the list of devices bonded (paired) to this adapter.
  /// Requires BLUETOOTH_CONNECT on API 31+.
  static Future<Map<String, dynamic>> getPairedDevices() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getPairedDevices',
    );

    return result ?? {};
  }

  /// Returns the list of devices currently connected via a Bluetooth
  /// profile (GATT, A2DP, HFP, etc.).
  /// Requires BLUETOOTH_CONNECT on API 31+.
  static Future<Map<String, dynamic>> getConnectedDevices() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getConnectedDevices',
    );

    return result ?? {};
  }

  // ===========================================================================
  // Bluetooth discovery — EventChannel stream + control
  // ===========================================================================

  /// Opens a broadcast stream of Bluetooth discovery events from the
  /// native [BluetoothDiscoveryHandler].
  ///
  /// Event types carried in each map's "event" key:
  ///   - "adapterState"     — Bluetooth turned on/off (also emitted on connect)
  ///   - "scanStarted"      — classic discovery began
  ///   - "deviceUpdate"     — classic device found (source: "classic")
  ///   - "bleDeviceUpdate"  — BLE device found (source: "ble")
  ///   - "bondStateChanged" — a device's pairing state changed
  ///   - "scanProgress"     — elapsed/total seconds (0-12 s window)
  ///   - "scanFinished"     — classic discovery ended
  ///   - "scanError"        — permission denied / adapter off / BLE failed
  ///   - "scanStopped"      — user or stream cancelled the scan
  static Stream<Map<String, dynamic>> bluetoothDiscoveryStream() {
    return _bluetoothDiscoveryChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
  }

  /// Asks the native side to start Bluetooth classic + BLE discovery.
  /// Returns true if the scan was initiated, false if already running.
  static Future<bool> startBluetoothDiscovery() async {
    final result = await _bluetoothDiscoveryControlChannel.invokeMethod<bool>(
      'startBluetoothDiscovery',
    );

    return result ?? false;
  }

  /// Asks the native side to stop any in-progress Bluetooth discovery.
  /// Returns true when stopped.
  static Future<bool> stopBluetoothDiscovery() async {
    final result = await _bluetoothDiscoveryControlChannel.invokeMethod<bool>(
      'stopBluetoothDiscovery',
    );

    return result ?? false;
  }

  /// Returns the current Bluetooth discovery status without changing it.
  /// Fields: adapterState, isScanning, classicScanning, bleScanning.
  static Future<Map<String, dynamic>> getBluetoothDiscoveryStatus() async {
    final result = await _bluetoothDiscoveryControlChannel
        .invokeMapMethod<String, dynamic>('getBluetoothDiscoveryStatus');

    return result ?? {};
  }

  // ===========================================================================
  // Permissions
  // ===========================================================================

  /// Checks whether [permission] has already been granted without
  /// showing any system dialog.
  static Future<PermissionStatus> checkPermission(
    PermissionType permission,
  ) async {
    final String value = await _channel.invokeMethod('permission', {
      'action': 'check',
      'permission': permission.name,
    });

    return PermissionStatus.values.firstWhere((e) => e.name == value);
  }

  /// Shows the system permission dialog for [permission] and returns the
  /// result. Returns [PermissionStatus.permanentlyDenied] if the user
  /// has selected "Don't ask again".
  static Future<PermissionStatus> requestPermission(
    PermissionType permission,
  ) async {
    final String value = await _channel.invokeMethod('permission', {
      'action': 'request',
      'permission': permission.name,
    });

    return PermissionStatus.values.firstWhere((e) => e.name == value);
  }

  /// Opens this application's page in the system Settings app so the
  /// user can manually toggle permissions.
  static Future<void> openAppSettings() {
    return _channel.invokeMethod('permission', {'action': 'openSettings'});
  }

  // ===========================================================================
  // Wi-Fi capabilities
  // ===========================================================================

  /// Returns static Wi-Fi adapter capabilities — 5/6 GHz support, WPA3,
  /// Wi-Fi Direct, scan-always-available, and current adapter state.
  /// No runtime permission required.
  static Future<Map<String, dynamic>> getWifiCapabilities() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getWifiCapabilities',
    );

    return result ?? {};
  }

  // ===========================================================================
  // Wi-Fi info — currently connected network
  // ===========================================================================

  /// Returns details of the currently connected Wi-Fi network — SSID,
  /// BSSID, RSSI, signal strength, link speed, frequency, band, and IP.
  ///
  /// Requires ACCESS_FINE_LOCATION for real SSID/BSSID — without it the
  /// OS redacts those two fields to placeholder values. RSSI, link speed,
  /// and frequency are NOT redacted and are always available.
  static Future<Map<String, dynamic>> getWifiInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getWifiInfo',
    );

    return result ?? {};
  }

  // ===========================================================================
  // Wi-Fi scan — EventChannel stream + control
  // ===========================================================================

  /// Opens a broadcast stream of Wi-Fi scan events from the native
  /// [WifiScanHandler]. Mirrors the Bluetooth discovery stream pattern.
  ///
  /// Event types carried in each map's "event" key:
  ///   - "wifiState"     — adapter state on connect and on state change
  ///   - "scanStarted"   — scan successfully initiated
  ///   - "scanResults"   — list of nearby networks (key: "networks")
  ///   - "scanThrottled" — OS returned cached results (4 per 2 min limit)
  ///   - "scanError"     — permission denied / location off / adapter off
  ///   - "scanStopped"   — user or stream cancelled the scan
  ///
  /// Each network in "networks" carries:
  ///   ssid, bssid, rssi, signalStrength, signalLevel, frequencyMHz,
  ///   band, channel, channelWidthMHz, capabilities, securityType,
  ///   isHidden, isPasspoint, operatorFriendlyName, timestamp
  static Stream<Map<String, dynamic>> wifiScanStream() {
    return _wifiScanChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
  }

  /// Asks the native side to initiate a Wi-Fi scan.
  /// Returns true if the scan was started, false if already running.
  ///
  /// Prerequisites checked natively (errors arrive as "scanError" events):
  ///   - ACCESS_FINE_LOCATION granted
  ///   - Location Services enabled in system Settings
  ///   - Wi-Fi enabled
  static Future<bool> startWifiScan() async {
    final result = await _wifiScanControlChannel.invokeMethod<bool>(
      'startWifiScan',
    );

    return result ?? false;
  }

  /// Asks the native side to stop any in-progress Wi-Fi scan.
  /// Returns true when stopped.
  static Future<bool> stopWifiScan() async {
    final result = await _wifiScanControlChannel.invokeMethod<bool>(
      'stopWifiScan',
    );

    return result ?? false;
  }

  /// Returns the current Wi-Fi scan status without changing it.
  /// Fields: isScanning, wifiEnabled, hasPermission,
  ///         locationServicesEnabled, wifiState.
  static Future<Map<String, dynamic>> getWifiScanStatus() async {
    final result = await _wifiScanControlChannel
        .invokeMapMethod<String, dynamic>('getWifiScanStatus');

    return result ?? {};
  }

  /// Returns the static NFC adapter capabilities — whether NFC is supported, enabled, and the current adapter state.
  /// No runtime permission required.
  static Future<Map<String, dynamic>> getNfcCapabilities() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getNfcCapabilities',
    );
    return result ?? {};
  }

  /// Opens a broadcast stream of NFC reader events from the native
  static Stream<Map<String, dynamic>> nfcReaderStream() {
    return _nfcReaderChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
  }

  /// Asks the native side to start NFC reader.
  /// Returns true if the reader was started, false if already running.
  static Future<bool> startNfcReader() async {
    final result = await _nfcReaderControlChannel.invokeMethod<bool>(
      'startNfcReader',
    );
    return result ?? false;
  }

  /// Asks the native side to stop any in-progress NFC reader.
  /// Returns true when stopped.
  static Future<bool> stopNfcReader() async {
    final result = await _nfcReaderControlChannel.invokeMethod<bool>(
      'stopNfcReader',
    );
    return result ?? false;
  }

  /// Opens a broadcast stream of live sensor events from native.
  ///
  /// Events may include:
  /// - sensorData
  /// - sensorAccuracyChanged
  static Stream<Map<String, dynamic>> sensorStream() {
    return _sensorStreamChannel.receiveBroadcastStream().map(
      (event) => Map<String, dynamic>.from(event as Map),
    );
  }

  /// Fetches a full catalog of sensors available on the device.
  static Future<Map<String, dynamic>> getSensorsCapabilities() async {
    final result = await _sensorChannel.invokeMapMethod<String, dynamic>(
      'getSensorsCapabilities',
    );
    return result ?? {};
  }

  /// Starts one sensor stream by Android sensor type id.
  /// Example: Sensor.TYPE_ACCELEROMETER, Sensor.TYPE_GYROSCOPE, etc.
  static Future<Map<String, dynamic>> startSensor({
    required int type,
    int? samplingPeriodUs,
  }) async {
    final result = await _sensorChannel
        .invokeMapMethod<String, dynamic>('startSensor', {
          'type': type,
          if (samplingPeriodUs != null) 'samplingPeriodUs': samplingPeriodUs,
        });
    return result ?? {};
  }

  /// Stops one active sensor stream by Android sensor type id.
  static Future<Map<String, dynamic>> stopSensor({required int type}) async {
    final result = await _sensorChannel.invokeMapMethod<String, dynamic>(
      'stopSensor',
      {'type': type},
    );
    return result ?? {};
  }

  /// Starts all available sensors that can be registered on the device.
  static Future<Map<String, dynamic>> startAllSensors({
    int? samplingPeriodUs,
  }) async {
    final result = await _sensorChannel.invokeMapMethod<String, dynamic>(
      'startAllSensors',
      {'samplingPeriodUs': ?samplingPeriodUs},
    );
    return result ?? {};
  }

  /// Stops every active sensor listener.
  static Future<Map<String, dynamic>> stopAllSensors() async {
    final result = await _sensorChannel.invokeMapMethod<String, dynamic>(
      'stopAllSensors',
    );
    return result ?? {};
  }

  /// Returns the list of currently active sensors on the native side.
  static Future<Map<String, dynamic>> getActiveSensors() async {
    final result = await _sensorChannel.invokeMapMethod<String, dynamic>(
      'getActiveSensors',
    );
    return result ?? {};
  }
}
