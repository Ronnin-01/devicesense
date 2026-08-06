import '../../../features/wifi/models/wifi_info_model.dart';

/// Abstraction over "where connected Wi-Fi network details come from".
///
/// Kept separate from [WifiCapabilitiesRepository] and
/// [WifiScanRepository] — they have different lifecycles, different
/// permissions, and different consumers (Interface Segregation).
abstract interface class WifiInfoRepository {
  /// Returns a single snapshot of the currently connected network.
  /// The snapshot's [WifiInfoModel.connected] field is false if the
  /// device is not currently associated with any Wi-Fi network.
  Future<WifiInfoModel> getWifiInfo();
}
