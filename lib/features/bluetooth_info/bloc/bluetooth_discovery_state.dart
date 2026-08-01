import 'package:equatable/equatable.dart';

import '../models/bluetooth_device_model.dart';
import '../models/bluetooth_discovery_snapshot.dart';

abstract class BluetoothDiscoveryState extends Equatable {
  const BluetoothDiscoveryState();

  @override
  List<Object?> get props => [];
}

class BluetoothDiscoveryInitial extends BluetoothDiscoveryState {
  const BluetoothDiscoveryInitial();
}

class BluetoothDiscoveryLoading extends BluetoothDiscoveryState {
  const BluetoothDiscoveryLoading();
}

class BluetoothDiscoveryLoaded extends BluetoothDiscoveryState {
  const BluetoothDiscoveryLoaded({required this.snapshot});

  final BluetoothDiscoverySnapshot snapshot;

  List<BluetoothDeviceModel> get devices => snapshot.devices;

  bool get isScanning => snapshot.isScanning;

  String get adapterState => snapshot.adapterState;

  DateTime get lastUpdated => snapshot.lastUpdated;

  @override
  List<Object?> get props => [snapshot];
}

class BluetoothDiscoveryError extends BluetoothDiscoveryState {
  final String message;

  const BluetoothDiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}
