import 'package:devicesense/features/wifi/models/wifi_capabilities_model.dart';

/// Abstraction over "where Wi-Fi adapter capabilities come from".
///
/// SOLID — Dependency Inversion: [WifiCapabilitiesBloc] depends on this
/// interface, never on a concrete data source directly.
/// SOLID — Interface Segregation: only exposes the one method this
/// feature needs. Scan and connected-network details live in separate
/// repository interfaces.
abstract interface class WifiCapabilitiesRepository {
  /// Returns a single snapshot of the adapter's hardware capabilities.
  Future<WifiCapabilitiesModel> getWifiCapabilities();
}
