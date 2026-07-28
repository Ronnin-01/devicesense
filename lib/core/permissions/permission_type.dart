/// Logical runtime permissions supported by Device Sense.
///
/// These values are converted to Android permissions by the native layer.
/// The enum name is sent across the MethodChannel.
enum PermissionType {
  camera,
  microphone,
  bluetoothConnect,
  bluetoothScan,
  location,
  notification,
}
