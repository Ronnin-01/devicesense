/// SOLID — Single Responsibility: events describe *what happened*, and
/// nothing else — no data-fetching or UI logic lives here.
sealed class DeviceInfoEvent {
  const DeviceInfoEvent();
}

/// Fired on first page load and on pull-to-refresh.
class DeviceInfoRequested extends DeviceInfoEvent {
  const DeviceInfoRequested();
}
