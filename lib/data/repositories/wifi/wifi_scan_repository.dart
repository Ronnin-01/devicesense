import 'dart:async';

import '../../../core/platform/native_channel.dart';
import '../../../features/wifi/models/wifi_network_model.dart';
import '../../../features/wifi/models/wifi_scan_snapshot.dart';

/// Translates raw native Wi-Fi scan events into a stream of immutable
/// [WifiScanSnapshot]s consumed by [WifiScanBloc].
///
/// Mirrors [BluetoothRepository]'s architecture exactly — same snapshot
/// pattern, same event routing shape, same dispose lifecycle.
///
/// Single Responsibility: this class owns event routing and network-list
/// state. It knows nothing about Flutter widgets or Bloc events.
class WifiScanRepository {
  final Map<String, WifiNetworkModel> _networks = {};

  bool _isScanning = false;
  bool _disposed = false;
  String _wifiState = 'UNKNOWN';

  WifiScanSnapshot _snapshot = WifiScanSnapshot.initial();

  final StreamController<WifiScanSnapshot> _snapshotController =
      StreamController<WifiScanSnapshot>.broadcast();

  StreamSubscription<Map<String, dynamic>>? _wifiSubscription;

  Stream<WifiScanSnapshot> get snapshotStream => _snapshotController.stream;

  // ---- Public API ---------------------------------------------------------

  Future<void> startScan() async {
    stopScan();

    _wifiSubscription = NativeChannel.wifiScanStream().listen(
      _handleEvent,
      onError: (Object error) {
        _emitError('STREAM_ERROR', error.toString());
      },
    );
  }

  Future<void> stopScan() async {
    await _wifiSubscription?.cancel();
    _wifiSubscription = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    stopScan();
    _snapshotController.close();
  }

  // ---- Event routing ------------------------------------------------------

  void _handleEvent(Map<String, dynamic> event) {
    final String type = event['event'] as String? ?? '';

    switch (type) {
      case 'wifiState':
        _handleWifiState(event);

      case 'scanStarted':
        _handleScanStarted();

      case 'scanResults':
        _handleScanResults(event);

      // OS returned cached results because the 4-per-2-min throttle was
      // hit. A "scanResults" event follows immediately after this one with
      // the cached list — surface the flag so the UI can show a badge.
      case 'scanThrottled':
        _handleScanThrottled(event);

      // Permission denied / Location Services off / Wi-Fi off.
      case 'scanError':
        _handleScanError(event);

      // User or stream cancelled.
      case 'scanStopped':
        _handleScanStopped();

      default:
        break;
    }
  }

  // ---- Individual handlers ------------------------------------------------

  void _handleWifiState(Map<String, dynamic> event) {
    _wifiState = event['state'] as String? ?? 'UNKNOWN';

    if (_wifiState == 'DISABLED' || _wifiState == 'DISABLING') {
      // Wi-Fi turned off mid-scan — clear the network list since those
      // results are no longer valid.
      _networks.clear();
      _isScanning = false;
    }

    _emitSnapshot();
  }

  void _handleScanStarted() {
    _isScanning = true;
    _networks.clear();

    // Clear any previous error when a new scan begins successfully.
    _snapshot = _snapshot.copyWith(scanError: null, fromCache: null);

    _emitSnapshot();
  }

  void _handleScanResults(Map<String, dynamic> event) {
    _isScanning = false;

    final rawList = event['networks'];
    if (rawList == null) {
      _emitSnapshot();
      return;
    }

    final fromCache = event['fromCache'] as bool? ?? false;

    final networks = (rawList as List)
        .map(
          (entry) =>
              WifiNetworkModel.fromMap(Map<String, dynamic>.from(entry as Map)),
        )
        .toList();

    // Insert or replace by BSSID — same access point with updated RSSI
    // just overwrites the previous entry.
    for (final network in networks) {
      _networks[network.bssid] = network;
    }

    _snapshot = _snapshot.copyWith(fromCache: fromCache);
    _emitSnapshot();
  }

  void _handleScanThrottled(Map<String, dynamic> event) {
    // The "scanResults" event with cached data follows immediately.
    // Pre-set the fromCache flag so the snapshot after results is correct.
    _snapshot = _snapshot.copyWith(fromCache: true);
    _emitSnapshot();
  }

  void _handleScanError(Map<String, dynamic> event) {
    final code = event['code'] as String? ?? 'UNKNOWN';
    final message = event['message'] as String? ?? 'An unknown error occurred';
    _isScanning = false;
    _emitError(code, message);
  }

  void _handleScanStopped() {
    _isScanning = false;
    _emitSnapshot();
  }

  // ---- Snapshot emission --------------------------------------------------

  void _emitSnapshot() {
    if (_disposed || _snapshotController.isClosed) return;

    final sorted = _networks.values.toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    _snapshot = _snapshot.copyWith(
      networks: List.unmodifiable(sorted),
      wifiState: _wifiState,
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
}
