import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/wifi/wifi_info_repository.dart';
import 'wifi_info_event.dart';
import 'wifi_info_state.dart';

/// Turns [WifiInfoEvent]s into [WifiInfoState]s.
///
/// Kept separate from [WifiCapabilitiesBloc] — different lifecycle
/// (info needs manual refresh; capabilities rarely change), different
/// permission story, different UI page. Merging them would force both
/// pages to rebuild on events they don't care about.
class WifiInfoBloc extends Bloc<WifiInfoEvent, WifiInfoState> {
  WifiInfoBloc(this._repository) : super(const WifiInfoInitial()) {
    on<WifiInfoRequested>(_onRequested);
  }

  final WifiInfoRepository _repository;

  Future<void> _onRequested(
    WifiInfoRequested event,
    Emitter<WifiInfoState> emit,
  ) async {
    emit(const WifiInfoLoading());
    try {
      final info = await _repository.getWifiInfo();
      emit(WifiInfoLoaded(info));
    } catch (error) {
      emit(WifiInfoError(error.toString()));
    }
  }
}