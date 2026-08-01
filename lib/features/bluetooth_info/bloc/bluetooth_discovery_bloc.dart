import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/bluetooth_repository.dart';
import '../models/bluetooth_discovery_snapshot.dart';
import 'bluetooth_discovery_event.dart';
import 'bluetooth_discovery_state.dart';

/// Bridges [BluetoothRepository]'s snapshot stream into Bloc states.
///
/// No event-routing logic lives here — that belongs in the repository.
/// This class only decides *when* to start/stop listening and forwards
/// snapshots and errors into the state machine.
class BluetoothDiscoveryBloc
    extends Bloc<BluetoothDiscoveryEvent, BluetoothDiscoveryState> {
  BluetoothDiscoveryBloc({required this._repository})
    : super(const BluetoothDiscoveryInitial()) {
    on<BluetoothDiscoveryStarted>(_onStarted);
    on<BluetoothDiscoveryStopped>(_onStopped);
    on<_RepositorySnapshotUpdated>(_onRepositoryUpdated);
    on<_RepositoryError>(_onRepositoryError);

    on<BluetoothScanStartRequested>(_onScanStartRequested);
    on<BluetoothScanStopRequested>(_onScanStopRequested);
  }

  final BluetoothRepository _repository;
  StreamSubscription<BluetoothDiscoverySnapshot>? _snapshotSubscription;

  Future<void> _onScanStartRequested(
    BluetoothScanStartRequested event,
    Emitter<BluetoothDiscoveryState> emit,
  ) async {
    try {
      final started = await _repository.startNativeScan();

      if (!started) {
        // Do not emit an error if false merely means the scan
        // was already active. Native should ideally return a
        // status object rather than a bare Boolean.
        return;
      }
    } catch (error) {
      emit(BluetoothDiscoveryError('Unable to start Bluetooth scan: $error'));
    }
  }

  Future<void> _onScanStopRequested(
    BluetoothScanStopRequested event,
    Emitter<BluetoothDiscoveryState> emit,
  ) async {
    try {
      await _repository.stopNativeScan();
    } catch (error) {
      emit(BluetoothDiscoveryError('Unable to stop Bluetooth scan: $error'));
    }
  }

  Future<void> _onStarted(
    BluetoothDiscoveryStarted event,
    Emitter<BluetoothDiscoveryState> emit,
  ) async {
    emit(const BluetoothDiscoveryLoading());

    await _snapshotSubscription?.cancel();

    _snapshotSubscription = _repository.discoveryStream.listen(
      (snapshot) => add(_RepositorySnapshotUpdated(snapshot)),
      onError: (error) => add(_RepositoryError(error.toString())),
    );

    await Future.microtask(() => _repository.startDiscovery());
  }

  Future<void> _onStopped(
    BluetoothDiscoveryStopped event,
    Emitter<BluetoothDiscoveryState> emit,
  ) async {
    await _snapshotSubscription?.cancel();
    _snapshotSubscription = null;
    await _repository.stopDiscovery();
    emit(const BluetoothDiscoveryInitial());
  }

  void _onRepositoryUpdated(
    _RepositorySnapshotUpdated event,
    Emitter<BluetoothDiscoveryState> emit,
  ) {
    // If the snapshot carries a scanError, surface it as an error state
    // so the UI can show the permission prompt or error card without
    // needing to inspect the snapshot itself.
    if (event.snapshot.scanError != null) {
      emit(BluetoothDiscoveryError(event.snapshot.scanError!));
      return;
    }

    emit(BluetoothDiscoveryLoaded(snapshot: event.snapshot));
  }

  void _onRepositoryError(
    _RepositoryError event,
    Emitter<BluetoothDiscoveryState> emit,
  ) {
    emit(BluetoothDiscoveryError(event.message));
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription?.cancel();
    _snapshotSubscription = null;

    await _repository.dispose();

    return super.close();
  }
}

// ---- Internal events ----------------------------------------------------
// Private to this file — the UI never dispatches these directly.

class _RepositorySnapshotUpdated extends BluetoothDiscoveryEvent {
  const _RepositorySnapshotUpdated(this.snapshot);
  final BluetoothDiscoverySnapshot snapshot;
}

class _RepositoryError extends BluetoothDiscoveryEvent {
  const _RepositoryError(this.message);
  final String message;
}
