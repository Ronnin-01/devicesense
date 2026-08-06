import 'package:equatable/equatable.dart';
import '../../models/nfc_reader_snapshot.dart';

sealed class NfcReaderState extends Equatable {
  const NfcReaderState();

  @override
  List<Object?> get props => [];
}

class NfcReaderInitial extends NfcReaderState {
  const NfcReaderInitial();
}

class NfcReaderLoading extends NfcReaderState {
  const NfcReaderLoading();
}

class NfcReaderLoaded extends NfcReaderState {
  const NfcReaderLoaded(this.snapshot);

  final NfcReaderSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot.lastUpdated];
}

class NfcReaderError extends NfcReaderState {
  const NfcReaderError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
