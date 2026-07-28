import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/hardware_repository.dart';
import 'bluetooth_info_event.dart';
import 'bluetooth_info_state.dart';

class BluetoothInfoBloc extends Bloc<BluetoothInfoEvent, BluetoothInfoState> {
  BluetoothInfoBloc(this._repository) : super(const BluetoothInfoInitial()) {
    on<BluetoothInfoRequested>(_onRequested);
  }

  final HardwareRepository _repository;

  Future<void> _onRequested(
    BluetoothInfoRequested event,
    Emitter<BluetoothInfoState> emit,
  ) async {
    emit(const BluetoothInfoLoading());
    try {
      final data = await _repository.getBluetoothInfo();
      emit(BluetoothInfoLoaded(data));
    } catch (error) {
      emit(BluetoothInfoError(error.toString()));
    }
  }
}
