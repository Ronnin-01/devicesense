part of 'battery_info_bloc.dart';

/// SOLID — Single Responsibility: states only describe *what the UI
/// should render*. They carry data, never behavior.
sealed class BatteryInfoState extends Equatable {
  const BatteryInfoState();

  @override
  List<Object?> get props => [];
}

class BatteryInfoInitial extends BatteryInfoState {
  const BatteryInfoInitial();
}

class BatteryInfoLoading extends BatteryInfoState {
  const BatteryInfoLoading();
}

class BatteryInfoLoaded extends BatteryInfoState {
  const BatteryInfoLoaded(this.data);

  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [data];
}

class BatteryInfoError extends BatteryInfoState {
  const BatteryInfoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
