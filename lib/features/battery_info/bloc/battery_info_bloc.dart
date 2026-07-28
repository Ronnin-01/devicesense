import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/hardware_repository.dart';

part 'battery_info_event.dart';
part 'battery_info_state.dart';

class BatteryInfoBloc extends Bloc<BatteryInfoEvent, BatteryInfoState> {
  BatteryInfoBloc(this._repository) : super(const BatteryInfoInitial()) {
    on<BatteryInfoRequested>(_onRequested);
  }

  final HardwareRepository _repository;

  Future<void> _onRequested(
    BatteryInfoRequested event,
    Emitter<BatteryInfoState> emit,
  ) async {
    emit(const BatteryInfoLoading());
    try {
      final data = await _repository.getBatteryInfo();
      final history = await _repository.getBatteryHistory();
      emit(BatteryInfoLoaded(data, history: [...history]));
    } catch (error) {
      emit(BatteryInfoError(error.toString()));
    }
  }
}
