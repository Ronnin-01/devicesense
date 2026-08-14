Map<String, dynamic> asStringMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{};
}

List<dynamic> asDynamicList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

List<Map<String, dynamic>> asStringMapList(dynamic value) {
  return asDynamicList(
    value,
  ).map((item) => asStringMap(item)).toList(growable: false);
}

String parseString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  if (value is String) return value;
  return value.toString();
}

int parseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();

  final parsed = int.tryParse(value.toString());
  return parsed ?? fallback;
}

double parseDouble(dynamic value, [double fallback = 0.0]) {
  if (value == null) return fallback;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();

  final parsed = double.tryParse(value.toString());
  return parsed ?? fallback;
}

bool parseBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;

  final text = value.toString().toLowerCase().trim();
  if (text == 'true') return true;
  if (text == 'false') return false;

  return fallback;
}

List<double> parseDoubleList(dynamic value) {
  if (value is! List) return const <double>[];

  return value.map((item) => parseDouble(item)).toList(growable: false);
}
