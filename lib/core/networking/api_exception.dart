class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isNetworkError => statusCode == 0;

  @override
  String toString() => 'ApiException(code: $statusCode, message: $message)';
}
