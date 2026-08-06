class NfcRecordModel {
  const NfcRecordModel({
    required this.tnf,
    required this.type,
    required this.payloadHex,
    required this.parsedText,
  });

  final int tnf;
  final String type;
  final String payloadHex;
  final String parsedText;

  factory NfcRecordModel.fromMap(Map<String, dynamic> map) {
    return NfcRecordModel(
      tnf: map['tnf'] as int? ?? 0,
      type: map['type'] as String? ?? '',
      payloadHex: map['payloadHex'] as String? ?? '',
      parsedText: map['parsedText'] as String? ?? '',
    );
  }
}

class NfcTagModel {
  const NfcTagModel({
    required this.id,
    required this.techs,
    required this.maxSize,
    required this.isWritable,
    required this.isReadOnly,
    required this.canMakeReadOnly,
    required this.records,
    required this.timestamp,
  });

  final String id;
  final List<String> techs;
  final int maxSize;
  final bool isWritable;
  final bool isReadOnly;
  final bool canMakeReadOnly;
  final List<NfcRecordModel> records;
  final int timestamp;

  factory NfcTagModel.fromMap(Map<String, dynamic> map) {
    final rawRecords = map['records'] as List<dynamic>? ?? [];
    return NfcTagModel(
      id: map['id'] as String? ?? 'N/A',
      techs: (map['techs'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      maxSize: map['maxSize'] as int? ?? 0,
      isWritable: map['isWritable'] as bool? ?? false,
      isReadOnly: map['isReadOnly'] as bool? ?? false,
      canMakeReadOnly: map['canMakeReadOnly'] as bool? ?? false,
      records: rawRecords
          .map(
            (r) => NfcRecordModel.fromMap(Map<String, dynamic>.from(r as Map)),
          )
          .toList(),
      timestamp: map['timestamp'] as int? ?? 0,
    );
  }
}
