import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/hardware/hardware_repository.dart';
import 'device_info_event.dart';
import 'device_info_state.dart';

class DeviceInfoBloc extends Bloc<DeviceInfoEvent, DeviceInfoState> {
  DeviceInfoBloc(this._repository) : super(const DeviceInfoInitial()) {
    on<DeviceInfoRequested>(_onRequested);
  }

  final HardwareRepository _repository;

  Future<void> _onRequested(
    DeviceInfoRequested event,
    Emitter<DeviceInfoState> emit,
  ) async {
    emit(const DeviceInfoLoading());
    try {
      final data = await _repository.getDeviceInfo();
      emit(DeviceInfoLoaded(data));
    } catch (error) {
      emit(DeviceInfoError(error.toString()));
    }
  }
}
