import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../data/repositories/nfc/nfc_reader_repository.dart';
import '../../models/nfc_reader_snapshot.dart';
import 'nfc_reader_event.dart';
import 'nfc_reader_state.dart';

class NfcReaderBloc extends Bloc<NfcReaderEvent, NfcReaderState> {
  NfcReaderBloc({required this._repository}) : super(const NfcReaderInitial()) {
    on<NfcReaderStarted>(_onStarted);
    on<NfcReaderStopped>(_onStopped);
    on<_NfcReaderSnapshotUpdated>(_onSnapshotUpdated);
    on<_NfcReaderError>(_onError);
  }

  final NfcReaderRepository _repository;
  StreamSubscription<NfcReaderSnapshot>? _snapshotSubscription;

  Future<void> _onStarted(
    NfcReaderStarted event,
    Emitter<NfcReaderState> emit,
  ) async {
    emit(const NfcReaderLoading());

    await _snapshotSubscription?.cancel();

    _snapshotSubscription = _repository.snapshotStream.listen(
      (snapshot) => add(_NfcReaderSnapshotUpdated(snapshot)),
      onError: (Object error) => add(_NfcReaderError(error.toString())),
    );

    await Future.microtask(() => _repository.startReader());
  }

  Future<void> _onStopped(
    NfcReaderStopped event,
    Emitter<NfcReaderState> emit,
  ) async {
    await _repository.stopReader();
    // The stream will emit a 'readerStopped' event which will update the state naturally,
    // so we don't need to manually emit anything here.
  }

  void _onSnapshotUpdated(
    _NfcReaderSnapshotUpdated event,
    Emitter<NfcReaderState> emit,
  ) {
    final snapshot = event.snapshot as NfcReaderSnapshot;

    if (snapshot.nfcError != null && !snapshot.isReading) {
      emit(NfcReaderError(snapshot.nfcError!));
      return;
    }

    emit(NfcReaderLoaded(snapshot));
  }

  void _onError(_NfcReaderError event, Emitter<NfcReaderState> emit) {
    emit(NfcReaderError(event.message));
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}

/// Internal: forwarded from [NfcReaderRepository]'s snapshot stream.
class _NfcReaderSnapshotUpdated extends NfcReaderEvent {
  const _NfcReaderSnapshotUpdated(this.snapshot);

  final Object snapshot;
}

/// Internal: forwarded when the repository stream errors.
class _NfcReaderError extends NfcReaderEvent {
  const _NfcReaderError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
