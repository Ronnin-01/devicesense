import 'package:devicesense/core/platform/native_channel.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../data/repositories/hardware/hardware_repository.dart';

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
      final sensors = await NativeChannel.getSensorsCapabilities();
      Logger().e('BatteryInfoBloc Sensors capabilities: $sensors');
      final history = await _repository.getBatteryHistory();
      emit(BatteryInfoLoaded(data, history: [...history]));
    } catch (error) {
      emit(BatteryInfoError(error.toString()));
    }
  }
}
