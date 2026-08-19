import '../../config/constants.dart';

/// Base class for domain-level failures.
///
/// Failures are value objects produced by the domain/repository layer to
/// describe *why* an operation failed in a UI-friendly way. They are
/// intentionally pure Dart and never wrap an `Exception` so presentation code
/// can pattern-match on them with `switch` / `when`.
abstract class Failure {
  /// User-facing description of the failure.
  final String message;

  const Failure(this.message);

  const factory Failure.validation([String message]) = ValidationFailure;
  const factory Failure.server([String message, int? statusCode]) = ServerFailure;
  const factory Failure.network([String message]) = NetworkFailure;
  const factory Failure.cache([String message]) = CacheFailure;
  const factory Failure.unauthorized([String message]) = UnauthorizedFailure;
  const factory Failure.notFound([String message]) = NotFoundFailure;

  @override
  String toString() => '$runtimeType: $message';
}

/// Failure caused by a network/connectivity problem (offline, DNS, timeout).
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = AppConstants.errorConnection]);
}

/// Failure caused by the backend server (5xx, unexpected payload).
class ServerFailure extends Failure {
  /// Optional HTTP status code returned by the server.
  final int? statusCode;

  const ServerFailure([
    super.message = AppConstants.errorServer,
    this.statusCode,
  ]);
}

/// Failure caused by invalid user input (validation).
class ValidationFailure extends Failure {
  const ValidationFailure([super.message = AppConstants.errorGeneric]);
}

/// Failure caused by item or entity not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'العنصر غير موجود']);
}

/// Failure caused by a local cache/storage problem.
class CacheFailure extends Failure {
  const CacheFailure([super.message = AppConstants.errorCache]);
}

/// Failure caused by expired or invalid credentials/token.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = AppConstants.errorSessionExpired]);
}

