sealed class BluetoothInfoEvent {
  const BluetoothInfoEvent();
}

/// Fired on first page load and on pull-to-refresh.
class BluetoothInfoRequested extends BluetoothInfoEvent {
  const BluetoothInfoRequested();
}
