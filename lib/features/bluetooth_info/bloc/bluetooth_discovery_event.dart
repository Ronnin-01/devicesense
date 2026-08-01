import 'package:equatable/equatable.dart';

abstract class BluetoothDiscoveryEvent extends Equatable {
  const BluetoothDiscoveryEvent();

  @override
  List<Object?> get props => [];
}

/// Starts listening to the native Bluetooth stream.
class BluetoothDiscoveryStarted extends BluetoothDiscoveryEvent {
  const BluetoothDiscoveryStarted();
}

/// Stops listening to the native Bluetooth stream.
class BluetoothDiscoveryStopped extends BluetoothDiscoveryEvent {
  const BluetoothDiscoveryStopped();
}

class BluetoothScanStartRequested extends BluetoothDiscoveryEvent {
  const BluetoothScanStartRequested();
}

class BluetoothScanStopRequested extends BluetoothDiscoveryEvent {
  const BluetoothScanStopRequested();
}
