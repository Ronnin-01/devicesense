import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'battery_info_event.dart';
part 'battery_info_state.dart';

class BatteryInfoBloc extends Bloc<BatteryInfoEvent, BatteryInfoState> {
  BatteryInfoBloc(this._repository) : super(const BatteryInfoInitial()) {
    on<BatteryInfoRequested>(_onRequested);
  }

  final BatteryInfoRepository _repository;

  Future<void> _onRequested(
    BatteryInfoRequested event,
    Emitter<BatteryInfoState> emit,
  ) async {
    emit(const BatteryInfoLoading());
    try {
      final data = await _repository.getBatteryInfo();
      emit(BatteryInfoLoaded(data));
    } catch (error) {
      emit(BatteryInfoError(error.toString()));
    }
  }
}
