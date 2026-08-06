import '../../../core/platform/native_channel.dart';
import '../../../features/wifi/models/wifi_capabilities_model.dart';
import 'wifi_capabilities_repository.dart';

/// Concrete [WifiCapabilitiesRepository] backed by [NativeChannel].
///
/// SOLID — Liskov Substitution: any alternative implementation (a fake
/// for tests, a cached version) can replace this wherever the interface
/// is injected.
/// SOLID — Open/Closed: if the native transport changes, only this file
/// changes — the Bloc and every UI widget above it stay untouched.
class WifiCapabilitiesRepositoryImpl implements WifiCapabilitiesRepository {
  const WifiCapabilitiesRepositoryImpl();

  @override
  Future<WifiCapabilitiesModel> getWifiCapabilities() async {
    final map = await NativeChannel.getWifiCapabilities();
    return WifiCapabilitiesModel.fromMap(map);
  }
}
