import 'dart:async';

import '../../../core/platform/native_channel.dart';
import '../../../features/nfc/models/nfc_capabilities_model.dart';
import '../../../features/nfc/models/nfc_reader_snapshot.dart';
import '../../../features/nfc/models/nfc_record_model.dart';
import 'nfc_reader_repository.dart';

class NfcReaderRepositoryImpl implements NfcReaderRepository {
  final _snapshotController = StreamController<NfcReaderSnapshot>.broadcast();
  StreamSubscription? _subscription;
  NfcReaderSnapshot _currentSnapshot = NfcReaderSnapshot.initial();

  @override
  Stream<NfcReaderSnapshot> get snapshotStream {
    _subscription ??= NativeChannel.nfcReaderStream().listen(_handleEvent);
    return _snapshotController.stream;
  }

  void _handleEvent(Map<String, dynamic> event) {
    if (_snapshotController.isClosed) return;

    try {
      final type = event['event'] as String?;
      final now = DateTime.now();

      switch (type) {
        case 'nfcState':
          _currentSnapshot = _currentSnapshot.copyWith(
            isReading:
                event['isReading'] as bool? ?? _currentSnapshot.isReading,
            nfcEnabled:
                event['nfcEnabled'] as bool? ?? _currentSnapshot.nfcEnabled,
            lastUpdated: now,
            nfcError: null, // FIX: Explicitly clear lingering errors!
          );
          break;
        case 'tagDetected':
          final tagMap = event['tag'] as Map<dynamic, dynamic>?;
          if (tagMap != null) {
            final tagModel = NfcTagModel.fromMap(
              Map<String, dynamic>.from(tagMap),
            );
            _currentSnapshot = _currentSnapshot.copyWith(
              lastDetectedTag: tagModel,
              isReading: false,
              nfcError: null, // FIX: Clear errors on successful read
              lastUpdated: now,
            );
          }
          break;
        case 'nfcError':
          _currentSnapshot = _currentSnapshot.copyWith(
            nfcError: event['message'] as String?,
            isReading: false,
            lastUpdated: now,
          );
          break;
        case 'readerStopped':
          _currentSnapshot = _currentSnapshot.copyWith(
            isReading: false,
            lastUpdated: now,
          );
          break;
      }

      if (!_snapshotController.isClosed) {
        _snapshotController.add(_currentSnapshot);
      }
    } catch (e, stackTrace) {
      if (!_snapshotController.isClosed) {
        _snapshotController.addError(
          Exception('Failed to parse NFC event: $e'),
          stackTrace,
        );
      }
    }
  }

  @override
  Future<bool> startReader() async {
    try {
      final success = await NativeChannel.startNfcReader();
      // FIX: Optimistic UI Update. Instantly set isReading to true if the native call succeeds.
      if (success && !_snapshotController.isClosed) {
        _currentSnapshot = _currentSnapshot.copyWith(
          isReading: true,
          nfcError: null, // Clear any previous errors immediately
          lastUpdated: DateTime.now(),
        );
        _snapshotController.add(_currentSnapshot);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> stopReader() async {
    try {
      final success = await NativeChannel.stopNfcReader();
      // FIX: Optimistic UI Update. Instantly set isReading to false.
      if (success && !_snapshotController.isClosed) {
        _currentSnapshot = _currentSnapshot.copyWith(
          isReading: false,
          lastUpdated: DateTime.now(),
        );
        _snapshotController.add(_currentSnapshot);
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<NfcCapabilitiesModel> getNfcCapabilities() async {
    final map = await NativeChannel.getNfcCapabilities();
    return NfcCapabilitiesModel.fromMap(map);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _snapshotController.close();
  }
}
