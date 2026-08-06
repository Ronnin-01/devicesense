import 'package:equatable/equatable.dart';

import '../../models/wifi_capabilities_model.dart';

/// States for [WifiCapabilitiesBloc].
sealed class WifiCapabilitiesState extends Equatable {
  const WifiCapabilitiesState();

  @override
  List<Object?> get props => [];
}

class WifiCapabilitiesInitial extends WifiCapabilitiesState {
  const WifiCapabilitiesInitial();
}

class WifiCapabilitiesLoading extends WifiCapabilitiesState {
  const WifiCapabilitiesLoading();
}

class WifiCapabilitiesLoaded extends WifiCapabilitiesState {
  const WifiCapabilitiesLoaded(this.capabilities);

  final WifiCapabilitiesModel capabilities;

  @override
  List<Object?> get props => [capabilities];
}

class WifiCapabilitiesError extends WifiCapabilitiesState {
  const WifiCapabilitiesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
