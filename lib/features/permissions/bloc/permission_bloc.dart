import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/hardware_repository.dart';
import 'permission_event.dart';
import 'permission_state.dart';

class PermissionBloc extends Bloc<PermissionEvent, PermissionState> {
  PermissionBloc(this._hardwareRepository) : super(const PermissionInitial()) {
    on<PermissionChecked>(_onChecked);
    on<PermissionRequested>(_onRequested);
    on<PermissionSettingsOpened>(_onSettingsOpened);
  }

  final HardwareRepository _hardwareRepository;

  Future<void> _onChecked(
    PermissionChecked event,
    Emitter<PermissionState> emit,
  ) async {
    emit(const PermissionLoading());

    try {
      final result = await _hardwareRepository.check(event.permission);

      emit(PermissionLoaded(result));
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }

  Future<void> _onRequested(
    PermissionRequested event,
    Emitter<PermissionState> emit,
  ) async {
    emit(const PermissionLoading());

    try {
      final result = await _hardwareRepository.request(event.permission);

      emit(PermissionLoaded(result));
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }

  Future<void> _onSettingsOpened(
    PermissionSettingsOpened event,
    Emitter<PermissionState> emit,
  ) async {
    try {
      await _hardwareRepository.openSettings();
    } catch (e) {
      emit(PermissionError(e.toString()));
    }
  }
}
