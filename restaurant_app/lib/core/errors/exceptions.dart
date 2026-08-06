import '../../config/constants.dart';

/// Base class for all application-level exceptions.
///
/// Exceptions represent *unexpected technical errors* that bubble up through
/// the data layer (e.g. from Dio, Hive). They are caught and translated into
/// [Failure]s at the repository boundary.
abstract class AppException implements Exception {
  /// Human-readable description of the error.
  final String message;

  const AppException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception raised when the backend responds with an error (4xx/5xx) or an
/// unexpected payload.
class ServerException extends AppException {
  /// Optional HTTP status code of the failing response.
  final int? statusCode;

  const ServerException(super.message, {this.statusCode});
}

/// Exception raised when a network request cannot be completed.
///
/// Kept dependency-free on purpose: [type] carries the `DioExceptionType`
/// enum name as a string so the core layer stays pure Dart and test-safe.
class NetworkException extends AppException {
  /// Optional HTTP status code, when one was received.
  final int? statusCode;

  /// `DioExceptionType` name (e.g. `connectionTimeout`, `connectionError`)
  /// captured as a string to keep this file free of package dependencies.
  final String? type;

  const NetworkException(super.message, {this.statusCode, this.type});
}

/// Exception raised when a local cache/storage operation fails.
class CacheException extends AppException {
  const CacheException([super.message = AppConstants.errorCache]);
}

/// Exception raised when the supplied credentials are rejected.
class InvalidCredentialsException extends AppException {
  const InvalidCredentialsException([
    super.message = AppConstants.errorInvalidCredentials,
  ]);
}
