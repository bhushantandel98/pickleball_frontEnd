/// Base exception class for all domain and data layer exceptions.
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => '$runtimeType: $message (statusCode: $statusCode)';
}

/// Thrown when a remote server returns a 5xx response or unexpected server error.
class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.statusCode = 500,
  });
}

/// Thrown when a network transport failure occurs (timeout, no internet connectivity, socket error).
class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.statusCode,
  });
}

/// Thrown when credentials or access tokens are missing, invalid, or expired (HTTP 401).
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    required super.message,
    super.statusCode = 401,
  });
}

/// Thrown when an authenticated user attempts an operation outside their authorized role or scope (HTTP 403).
class ForbiddenException extends AppException {
  const ForbiddenException({
    required super.message,
    super.statusCode = 403,
  });
}

/// Thrown when a requested resource or record cannot be located (HTTP 404).
class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.statusCode = 404,
  });
}

/// Thrown when server-side or payload validation fails (HTTP 422).
class ValidationException extends AppException {
  final Map<String, String>? errors;

  const ValidationException({
    required super.message,
    super.statusCode = 422,
    this.errors,
  });
}

/// Thrown when a local storage or cache reading/writing failure occurs.
class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.statusCode,
  });
}
