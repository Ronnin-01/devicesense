import '../../../core/permissions/permission_result.dart';
import '../../../core/permissions/permission_type.dart';
import '../../../core/platform/native_channel.dart';
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

  @override
  Future<Map<String, dynamic>> getBluetoothInfo() {
    return NativeChannel.getBluetoothCapabilities();
  }

  @override
  Future<PermissionResult> check(PermissionType permission) async {
    final status = await NativeChannel.checkPermission(permission);

    return PermissionResult(status: status, permission: permission);
  }

  @override
  Future<PermissionResult> request(PermissionType permission) async {
    final status = await NativeChannel.requestPermission(permission);

    return PermissionResult(status: status, permission: permission);
  }

  @override
  Future<void> openSettings() {
    return NativeChannel.openAppSettings();
  }

  @override
  Future<Map<String, dynamic>> getPairedDevices() async {
    return NativeChannel.getPairedDevices();
  }
}
