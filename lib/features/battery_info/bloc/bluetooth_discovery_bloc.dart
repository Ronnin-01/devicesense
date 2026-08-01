import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/bluetooth_repository.dart';
import '../models/bluetooth_discovery_snapshot.dart';
import 'bluetooth_discovery_event.dart';
import 'bluetooth_discovery_state.dart';

class BluetoothDiscoveryBloc
    extends Bloc<BluetoothDiscoveryEvent, BluetoothDiscoveryState> {
  BluetoothDiscoveryBloc({required this._repository})
    : super(const BluetoothDiscoveryInitial()) {
    on<BluetoothDiscoveryStarted>(_onStarted);

    on<BluetoothDiscoveryStopped>(_onStopped);

    on<_RepositorySnapshotUpdated>(_onRepositoryUpdated);

    on<_RepositoryError>(_onRepositoryError);
  }

  final BluetoothRepository _repository;

  StreamSubscription<BluetoothDiscoverySnapshot>? _snapshotSubscription;

  Future<void> _onStarted(
    BluetoothDiscoveryStarted event,
    Emitter<BluetoothDiscoveryState> emit,
  ) async {
    emit(const BluetoothDiscoveryLoading());

    await _snapshotSubscription?.cancel();

    _snapshotSubscription = _repository.snapshotStream.listen(
      (snapshot) {
        print("BLOC RECEIVED ${snapshot.devices.length}");
        add(_RepositorySnapshotUpdated(snapshot));
      },
      onError: (error) {
        add(_RepositoryError(error.toString()));
      },
    );
    await Future.microtask(() => _repository.startDiscovery());
  }

  Future<void> _onStopped(
    BluetoothDiscoveryStopped event,
    Emitter<BluetoothDiscoveryState> emit,
  ) async {
    await _snapshotSubscription?.cancel();

    _repository.stopDiscovery();

    emit(const BluetoothDiscoveryInitial());
  }

  void _onRepositoryUpdated(
    _RepositorySnapshotUpdated event,
    Emitter<BluetoothDiscoveryState> emit,
  ) {
    print("EMITTING STATE ${event.snapshot.devices.length}");
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
    _repository.dispose();

    return super.close();
  }
}

/// ----------------------------------------------------------------------
/// Internal Events
/// ----------------------------------------------------------------------

class _RepositorySnapshotUpdated extends BluetoothDiscoveryEvent {
  const _RepositorySnapshotUpdated(this.snapshot);

  final BluetoothDiscoverySnapshot snapshot;
}

class _RepositoryError extends BluetoothDiscoveryEvent {
  const _RepositoryError(this.message);

  final String message;
}
