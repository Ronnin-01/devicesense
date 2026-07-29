import 'package:equatable/equatable.dart';

sealed class BluetoothInfoState extends Equatable {
  const BluetoothInfoState();

  @override
  List<Object?> get props => [];
}

class BluetoothInfoInitial extends BluetoothInfoState {
  const BluetoothInfoInitial();
}

class BluetoothInfoLoading extends BluetoothInfoState {
  const BluetoothInfoLoading();
}

class BluetoothInfoLoaded extends BluetoothInfoState {
  const BluetoothInfoLoaded(this.data);

  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [data];
}

class BTDevicesLoaded extends BluetoothInfoState {
  const BTDevicesLoaded(this.data);

  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [data];
}

class BluetoothInfoError extends BluetoothInfoState {
  const BluetoothInfoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
