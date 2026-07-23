import '../../core/platform/native_channel.dart';
import 'device_info_repository.dart';

/// Concrete [DeviceInfoRepository] backed by the existing
/// `NativeChannel` platform channel (untouched — see
/// core/platform/native_channel.dart).
///
/// SOLID — Liskov Substitution: any other implementation (a fake for
/// tests, a cached version, etc.) can replace this one everywhere it's
/// injected, because it only promises what the interface promises.
/// SOLID — Open/Closed: if the native transport ever changes, only this
/// file changes — the Bloc and every UI file above it stay untouched.
class DeviceInfoRepositoryImpl implements DeviceInfoRepository {
  const DeviceInfoRepositoryImpl();

  @override
  Future<Map<String, dynamic>> getDeviceInfo() {
    return NativeChannel.getDeviceInfo();
  }

  @override
  Future<Map<String, dynamic>> getBatteryInfo() {
    return NativeChannel.getBatteryInfo();
  }
}
