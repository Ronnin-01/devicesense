/// Abstraction over "where device info comes from".
///
/// SOLID — Dependency Inversion: [DeviceInfoBloc] (high-level) depends on
/// this interface, never on a concrete data source directly.
/// SOLID — Interface Segregation: this contract only knows about device
/// info. Battery, Bluetooth, Wi-Fi, NFC and Sensors each get their own
/// small repository interface later instead of one bloated
/// "HardwareRepository" that forces every implementer to support
/// methods it doesn't need.
abstract interface class DeviceInfoRepository {
  Future<Map<String, dynamic>> getDeviceInfo();
}
