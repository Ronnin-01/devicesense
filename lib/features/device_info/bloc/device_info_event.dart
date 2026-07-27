sealed class DeviceInfoEvent {
  const DeviceInfoEvent();
}

/// Fired on first page load and on pull-to-refresh.
class DeviceInfoRequested extends DeviceInfoEvent {
  const DeviceInfoRequested();
}
