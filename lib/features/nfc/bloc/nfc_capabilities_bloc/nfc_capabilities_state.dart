import 'package:equatable/equatable.dart';
import '../../models/nfc_capabilities_model.dart';

sealed class NfcCapabilitiesState extends Equatable {
  const NfcCapabilitiesState();

  @override
  List<Object?> get props => [];
}

class NfcCapabilitiesInitial extends NfcCapabilitiesState {
  const NfcCapabilitiesInitial();
}

class NfcCapabilitiesLoading extends NfcCapabilitiesState {
  const NfcCapabilitiesLoading();
}

class NfcCapabilitiesLoaded extends NfcCapabilitiesState {
  const NfcCapabilitiesLoaded(this.capabilities);

  final NfcCapabilitiesModel capabilities;

  @override
  List<Object?> get props => [capabilities.nfcEnabled, capabilities.nfcState];
}

class NfcCapabilitiesError extends NfcCapabilitiesState {
  const NfcCapabilitiesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
