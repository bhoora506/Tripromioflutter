/// Typed failure hierarchy used across the application.
///
/// Use these in repository / use-case return types (e.g., `Either<Failure, T>`).
/// The [ApiException] classes in `core/network/api_exception.dart` are mapped
/// to [Failure] subtypes at the repository boundary to keep the domain layer
/// free of HTTP concerns.
sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No internet connection or host unreachable.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error. Check your connection.']);
}

/// A server-side error (HTTP 5xx).
final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error. Please try again.']);
}

/// Input validation failed (HTTP 422).
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.errors});

  /// Field-level error messages, keyed by field name.
  final Map<String, List<String>>? errors;
}

/// The user is not authenticated (HTTP 401).
final class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Session expired. Please log in again.']);
}

/// The user lacks permission for this action (HTTP 403).
final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'You are not allowed to do that.']);
}

/// Resource was not found (HTTP 404).
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Resource not found.']);
}

/// Resource conflict (HTTP 409).
final class ConflictFailure extends Failure {
  const ConflictFailure([super.message = 'Conflict with existing data.']);
}

/// Rate limited (HTTP 429).
final class RateLimitFailure extends Failure {
  const RateLimitFailure([super.message = 'Too many requests. Please wait.']);
}

/// An unexpected, uncategorised failure.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred.']);
}
