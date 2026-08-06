import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

import '../../../core/platform/native_channel.dart';
import '../../../data/repositories/hardware/hardware_repository.dart';
import 'bluetooth_info_event.dart';
import 'bluetooth_info_state.dart';

class BluetoothInfoBloc extends Bloc<BluetoothInfoEvent, BluetoothInfoState> {
  BluetoothInfoBloc(this._repository) : super(const BluetoothInfoInitial()) {
    on<BluetoothInfoRequested>(_onRequested);
    on<BluetoothPairedDevices>(_getPairedDevices);
  }

  final HardwareRepository _repository;

  Future<void> _onRequested(
    BluetoothInfoRequested event,
    Emitter<BluetoothInfoState> emit,
  ) async {
    emit(const BluetoothInfoLoading());
    try {
      final data = await _repository.getBluetoothInfo();
      final status = await NativeChannel.getConnectedDevices();
      Logger().f("Connected Devices: $status");
      emit(BluetoothInfoLoaded(data));
    } catch (error) {
      emit(BluetoothInfoError(error.toString()));
    }
  }

  Future<void> _getPairedDevices(
    BluetoothPairedDevices event,
    Emitter<BluetoothInfoState> emit,
  ) async {
    emit(const BluetoothInfoLoading());
    try {
      final data = await _repository.getPairedDevices();
      emit(BTDevicesLoaded(data));
    } catch (error) {
      emit(BluetoothInfoError(error.toString()));
    }
  }
}
