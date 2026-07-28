part of 'battery_info_bloc.dart';

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
  const BatteryInfoLoaded(this.data, {required this.history});

  final Map<String, dynamic> data;
  final List<Map<String, dynamic>> history;

  @override
  List<Object?> get props => [data, history];
}

class BatteryInfoError extends BatteryInfoState {
  const BatteryInfoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
