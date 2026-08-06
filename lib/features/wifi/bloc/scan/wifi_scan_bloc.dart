import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../data/repositories/wifi/wifi_scan_repository.dart';
import '../../models/wifi_scan_snapshot.dart';
import 'wifi_scan_event.dart';
import 'wifi_scan_state.dart';

/// Bridges [WifiScanRepository]'s snapshot stream into Bloc states.
///
/// Mirrors [BluetoothDiscoveryBloc]'s architecture exactly — same
/// internal-event forwarding pattern, same lifecycle, same separation
/// between "what happened" (events) and "what to show" (states).
///
/// No event-routing logic lives here — that belongs in the repository.
/// This class only decides when to start/stop listening and forwards
/// snapshots and errors into the state machine.
class WifiScanBloc extends Bloc<WifiScanEvent, WifiScanState> {
  WifiScanBloc({required this._repository}) : super(const WifiScanInitial()) {
    on<WifiScanStarted>(_onStarted);
    on<WifiScanStopped>(_onStopped);
    on<_WifiScanSnapshotUpdated>(_onSnapshotUpdated);
    on<_WifiScanError>(_onError);
  }

  final WifiScanRepository _repository;
  StreamSubscription<WifiScanSnapshot>? _snapshotSubscription;

  Future<void> _onStarted(
    WifiScanStarted event,
    Emitter<WifiScanState> emit,
  ) async {
    emit(const WifiScanLoading());

    await _snapshotSubscription?.cancel();

    _snapshotSubscription = _repository.snapshotStream.listen(
      (snapshot) => add(_WifiScanSnapshotUpdated(snapshot)),
      onError: (Object error) => add(_WifiScanError(error.toString())),
    );

    await Future.microtask(() => _repository.startScan());
  }

  Future<void> _onStopped(
    WifiScanStopped event,
    Emitter<WifiScanState> emit,
  ) async {
    await _snapshotSubscription?.cancel();
    _snapshotSubscription = null;
    await _repository.stopScan();
    emit(const WifiScanInitial());
  }

  void _onSnapshotUpdated(
    _WifiScanSnapshotUpdated event,
    Emitter<WifiScanState> emit,
  ) {
    final snapshot = event.snapshot as WifiScanSnapshot;

    // If the snapshot carries a scanError, surface it as an error state
    // so the UI can show the appropriate prompt without inspecting the
    // snapshot itself — mirrors [BluetoothDiscoveryBloc]'s pattern.
    if (snapshot.scanError != null) {
      emit(WifiScanError(snapshot.scanError!));
      return;
    }

    emit(WifiScanLoaded(snapshot));
  }

  void _onError(_WifiScanError event, Emitter<WifiScanState> emit) {
    emit(WifiScanError(event.message));
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}

/// Internal: forwarded from [WifiScanRepository]'s snapshot stream.
/// Never dispatched by the UI directly.
class _WifiScanSnapshotUpdated extends WifiScanEvent {
  const _WifiScanSnapshotUpdated(this.snapshot);

  final Object snapshot; // typed as Object to keep the sealed hierarchy clean
}

/// Internal: forwarded when the repository stream errors.
class _WifiScanError extends WifiScanEvent {
  const _WifiScanError(this.message);

  final String message;
}
