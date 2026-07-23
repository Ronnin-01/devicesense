import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/device_info_repository.dart';
import 'device_info_event.dart';
import 'device_info_state.dart';

/// SOLID — Single Responsibility: turns [DeviceInfoEvent]s into
/// [DeviceInfoState]s. Knows nothing about platform channels or widgets.
/// SOLID — Dependency Inversion: depends on [DeviceInfoRepository] (an
/// abstraction), injected through the constructor. get_it decides which
/// concrete implementation to hand it — this class never asks.
class DeviceInfoBloc extends Bloc<DeviceInfoEvent, DeviceInfoState> {
  DeviceInfoBloc(this._repository) : super(const DeviceInfoInitial()) {
    on<DeviceInfoRequested>(_onRequested);
  }

  final DeviceInfoRepository _repository;

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
