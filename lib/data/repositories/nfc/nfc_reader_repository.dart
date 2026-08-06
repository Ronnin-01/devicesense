import '../../../features/nfc/models/nfc_capabilities_model.dart';
import '../../../features/nfc/models/nfc_reader_snapshot.dart';

abstract interface class NfcReaderRepository {
  Stream<NfcReaderSnapshot> get snapshotStream;
  Future<bool> startReader();
  Future<bool> stopReader();
  Future<NfcCapabilitiesModel> getNfcCapabilities();
  void dispose();
}
