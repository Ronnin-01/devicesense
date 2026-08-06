import 'package:equatable/equatable.dart';

import '../../models/wifi_info_model.dart';

/// States for [WifiInfoBloc].
sealed class WifiInfoState extends Equatable {
  const WifiInfoState();

  @override
  List<Object?> get props => [];
}

class WifiInfoInitial extends WifiInfoState {
  const WifiInfoInitial();
}

class WifiInfoLoading extends WifiInfoState {
  const WifiInfoLoading();
}

class WifiInfoLoaded extends WifiInfoState {
  const WifiInfoLoaded(this.info);

  final WifiInfoModel info;

  @override
  List<Object?> get props => [info];
}

class WifiInfoError extends WifiInfoState {
  const WifiInfoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
