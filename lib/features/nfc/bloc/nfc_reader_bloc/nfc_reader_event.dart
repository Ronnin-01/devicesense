import 'package:equatable/equatable.dart';

abstract class NfcReaderEvent extends Equatable {
  const NfcReaderEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched by the UI to enable NFC Reader mode.
class NfcReaderStarted extends NfcReaderEvent {
  const NfcReaderStarted();
}

/// Dispatched by the UI to disable NFC Reader mode.
class NfcReaderStopped extends NfcReaderEvent {
  const NfcReaderStopped();
}
