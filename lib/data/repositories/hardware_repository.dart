abstract interface class HardwareRepository {
  Future<Map<String, dynamic>> getDeviceInfo();
  Future<Map<String, dynamic>> getBatteryInfo();
  Future<List<Map<String, dynamic>>> getBatteryHistory();
}
