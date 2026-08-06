import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/wifi/wifi_capabilities_repository.dart';
import 'wifi_capabilities_event.dart';
import 'wifi_capabilities_state.dart';

/// Turns [WifiCapabilitiesEvent]s into [WifiCapabilitiesState]s.
///
/// SOLID — Single Responsibility: only converts events to states.
/// SOLID — Dependency Inversion: depends on [WifiCapabilitiesRepository]
/// (an abstraction) injected via the constructor — never on
/// [WifiCapabilitiesRepositoryImpl] or [NativeChannel] directly.
class WifiCapabilitiesBloc
    extends Bloc<WifiCapabilitiesEvent, WifiCapabilitiesState> {
  WifiCapabilitiesBloc(this._repository)
    : super(const WifiCapabilitiesInitial()) {
    on<WifiCapabilitiesRequested>(_onRequested);
  }

  final WifiCapabilitiesRepository _repository;

  Future<void> _onRequested(
    WifiCapabilitiesRequested event,
    Emitter<WifiCapabilitiesState> emit,
  ) async {
    emit(const WifiCapabilitiesLoading());
    try {
      final capabilities = await _repository.getWifiCapabilities();
      emit(WifiCapabilitiesLoaded(capabilities));
    } catch (error) {
      emit(WifiCapabilitiesError(error.toString()));
    }
  }
}
