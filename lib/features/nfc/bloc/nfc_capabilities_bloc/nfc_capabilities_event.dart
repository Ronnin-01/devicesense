import 'package:equatable/equatable.dart';

sealed class NfcCapabilitiesEvent extends Equatable {
  const NfcCapabilitiesEvent();

  @override
  List<Object?> get props => [];
}

class NfcCapabilitiesRequested extends NfcCapabilitiesEvent {
  const NfcCapabilitiesRequested();
}
