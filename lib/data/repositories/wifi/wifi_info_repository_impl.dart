import '../../../core/platform/native_channel.dart';
import '../../../features/wifi/models/wifi_info_model.dart';
import 'wifi_info_repository.dart';

/// Concrete [WifiInfoRepository] backed by [NativeChannel].
class WifiInfoRepositoryImpl implements WifiInfoRepository {
  const WifiInfoRepositoryImpl();

  @override
  Future<WifiInfoModel> getWifiInfo() async {
    final map = await NativeChannel.getWifiInfo();
    return WifiInfoModel.fromMap(map);
  }
}
