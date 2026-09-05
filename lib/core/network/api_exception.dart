/// Typed exception thrown by [ApiClient] on every non-success response or
/// network failure.
///
/// Callers can inspect [statusCode] or use the subclasses directly:
///
/// ```dart
/// try {
///   await healthService.checkHealth();
/// } on UnauthorizedException {
///   // redirect to login
/// } on ApiException catch (e) {
///   // show e.message
/// }
/// ```
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  /// Human-readable error string (from backend `message` field or fallback).
  final String message;

  /// HTTP status code, if a response was received.
  final int? statusCode;

  /// Validation errors keyed by field name (backend `errors` map, HTTP 422).
  final Map<String, List<String>>? errors;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

// ── Typed subclasses ──────────────────────────────────────────────────────────

/// 400 – Bad request / malformed input.
final class BadRequestException extends ApiException {
  const BadRequestException(String message, {Map<String, List<String>>? errors}) // ignore: use_super_parameters
      : super(message: message, statusCode: 400, errors: errors);
}

/// 401 – Unauthenticated (missing or invalid Sanctum token).
final class UnauthorizedException extends ApiException {
  const UnauthorizedException([String message = 'Unauthenticated.'])
      : super(message: message, statusCode: 401);
}

/// 403 – Authenticated but not authorised for this action.
final class ForbiddenException extends ApiException {
  const ForbiddenException([String message = 'Forbidden.'])
      : super(message: message, statusCode: 403);
}

/// 404 – Resource not found.
final class NotFoundException extends ApiException {
  const NotFoundException([String message = 'Not found.'])
      : super(message: message, statusCode: 404);
}

/// 409 – Conflict (e.g. trip already published / duplicate resource).
final class ConflictException extends ApiException {
  const ConflictException([String message = 'Conflict.'])
      : super(message: message, statusCode: 409);
}

/// 422 – Validation failure.  Check [errors] for field-level messages.
final class ValidationException extends ApiException {
  const ValidationException(String message, {Map<String, List<String>>? errors}) // ignore: use_super_parameters
      : super(message: message, statusCode: 422, errors: errors);
}

/// 429 – Rate limited.
final class TooManyRequestsException extends ApiException {
  const TooManyRequestsException([String message = 'Too many requests.'])
      : super(message: message, statusCode: 429);
}

/// 500+ – Server-side error.
final class ServerException extends ApiException {
  const ServerException([String message = 'Server error.'])
      : super(message: message, statusCode: 500);
}

/// No internet connection or host unreachable.
final class NetworkException extends ApiException {
  const NetworkException([String message = 'Network error. Check your connection.'])
      : super(message: message);
}
