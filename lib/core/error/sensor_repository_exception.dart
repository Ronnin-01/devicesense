class SensorRepositoryException implements Exception {
  const SensorRepositoryException({
    required this.code,
    required this.message,
    this.details,
    this.cause,
  });

  final String code;
  final String message;
  final Object? details;
  final Object? cause;

  @override
  String toString() {
    return 'SensorRepositoryException(code: $code, message: $message, details: $details, cause: $cause)';
  }
}
