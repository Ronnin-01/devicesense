import 'package:devicesense/data/repositories/nfc/nfc_reader_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'nfc_capabilities_event.dart';
import 'nfc_capabilities_state.dart';

class NfcCapabilitiesBloc
    extends Bloc<NfcCapabilitiesEvent, NfcCapabilitiesState> {
  NfcCapabilitiesBloc(this._repository)
    : super(const NfcCapabilitiesInitial()) {
    on<NfcCapabilitiesRequested>(_onRequested);
  }

  final NfcReaderRepository _repository;

  Future<void> _onRequested(
    NfcCapabilitiesRequested event,
    Emitter<NfcCapabilitiesState> emit,
  ) async {
    emit(const NfcCapabilitiesLoading());
    try {
      final capabilities = await _repository.getNfcCapabilities();
      emit(NfcCapabilitiesLoaded(capabilities));
    } catch (error) {
      emit(NfcCapabilitiesError(error.toString()));
    }
  }
}
