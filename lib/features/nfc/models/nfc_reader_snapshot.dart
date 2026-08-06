import 'nfc_record_model.dart';

/// Immutable snapshot of the current NFC reader state.
/// Emitted by [NfcReaderRepository] whenever the native stream updates.
class NfcReaderSnapshot {
  const NfcReaderSnapshot({
    required this.isReading,
    required this.nfcEnabled,
    required this.lastUpdated,
    this.lastDetectedTag,
    this.nfcError,
  });

  /// True if the hardware is actively polling for tags (Reader Mode).
  final bool isReading;

  /// True if NFC is turned on in Android Settings.
  final bool nfcEnabled;

  /// The timestamp of the most recent event.
  final DateTime lastUpdated;

  /// The most recently scanned tag, if any.
  final NfcTagModel? lastDetectedTag;

  /// System error message (e.g., NFC disabled, not supported).
  final String? nfcError;

  NfcReaderSnapshot copyWith({
    bool? isReading,
    bool? nfcEnabled,
    DateTime? lastUpdated,
    Object? lastDetectedTag = _keep,
    Object? nfcError = _keep,
  }) {
    return NfcReaderSnapshot(
      isReading: isReading ?? this.isReading,
      nfcEnabled: nfcEnabled ?? this.nfcEnabled,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastDetectedTag: lastDetectedTag == _keep
          ? this.lastDetectedTag
          : lastDetectedTag as NfcTagModel?,
      nfcError: nfcError == _keep ? this.nfcError : nfcError as String?,
    );
  }

  factory NfcReaderSnapshot.initial() {
    return NfcReaderSnapshot(
      isReading: false,
      nfcEnabled: false,
      lastUpdated: DateTime.now(),
      lastDetectedTag: null,
      nfcError: null,
    );
  }
}

const Object _keep = Object();
