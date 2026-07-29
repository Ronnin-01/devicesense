import '../../core/permissions/permission_result.dart';
import '../../core/permissions/permission_type.dart';

abstract interface class HardwareRepository {
  Future<Map<String, dynamic>> getDeviceInfo();

  Future<Map<String, dynamic>> getBatteryInfo();

  Future<List<Map<String, dynamic>>> getBatteryHistory();

  Future<Map<String, dynamic>> getBluetoothInfo();

  Future<PermissionResult> check(PermissionType permission);

  Future<PermissionResult> request(PermissionType permission);

  Future<void> openSettings();

  Future<Map<String, dynamic>> getPairedDevices();
}
