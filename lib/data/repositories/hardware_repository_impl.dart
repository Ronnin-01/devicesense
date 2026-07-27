import '../../core/platform/native_channel.dart';
import 'hardware_repository.dart';

class HardwareRepositoryImpl implements HardwareRepository {
  const HardwareRepositoryImpl();

  @override
  Future<Map<String, dynamic>> getDeviceInfo() {
    return NativeChannel.getDeviceInfo();
  }

  @override
  Future<Map<String, dynamic>> getBatteryInfo() {
    return NativeChannel.getBatteryInfo();
  }

  @override
  Future<List<Map<String, dynamic>>> getBatteryHistory() {
    return NativeChannel.getBatteryHistory();
  }
}
