class NfcCapabilitiesModel {
  const NfcCapabilitiesModel({
    required this.nfcSupported,
    required this.nfcEnabled,
    required this.nfcState,
    required this.isNdefSupported,
    required this.isMifareClassicSupported,
    required this.isHceSupported,
  });

  final bool nfcSupported;
  final bool nfcEnabled;
  final String nfcState;
  final bool isNdefSupported;
  final bool isMifareClassicSupported;
  final bool isHceSupported;

  factory NfcCapabilitiesModel.fromMap(Map<String, dynamic> map) {
    return NfcCapabilitiesModel(
      nfcSupported: map['nfcSupported'] as bool? ?? false,
      nfcEnabled: map['nfcEnabled'] as bool? ?? false,
      nfcState: map['nfcState'] as String? ?? 'UNSUPPORTED',
      isNdefSupported: map['isNdefSupported'] as bool? ?? false,
      isMifareClassicSupported:
          map['isMifareClassicSupported'] as bool? ?? false,
      isHceSupported: map['isHceSupported'] as bool? ?? false,
    );
  }
}
