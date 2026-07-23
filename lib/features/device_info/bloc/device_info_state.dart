import 'package:equatable/equatable.dart';

/// SOLID — Single Responsibility: states only describe *what the UI
/// should render*. They carry data, never behavior.
sealed class DeviceInfoState extends Equatable {
  const DeviceInfoState();

  @override
  List<Object?> get props => [];
}

class DeviceInfoInitial extends DeviceInfoState {
  const DeviceInfoInitial();
}

class DeviceInfoLoading extends DeviceInfoState {
  const DeviceInfoLoading();
}

class DeviceInfoLoaded extends DeviceInfoState {
  const DeviceInfoLoaded(this.data);

  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [data];
}

class DeviceInfoError extends DeviceInfoState {
  const DeviceInfoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
