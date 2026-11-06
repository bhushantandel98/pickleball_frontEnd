import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/exceptions.dart';

/// Base failure class for all clean architecture domain operations.
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({
    required this.message,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, statusCode];

  @override
  String toString() => '$runtimeType: $message (statusCode: $statusCode)';

  /// Maps known exceptions into standard typed domain Failures.
  ///
  /// For unclassified or unexpected exceptions, returns a sanitized, safe
  /// [UnknownFailure] without exposing internal stack or exception details.
  factory Failure.fromException(Object exception) {
    if (exception is ServerException) {
      return ServerFailure(message: exception.message, statusCode: exception.statusCode);
    }
    if (exception is NetworkException) {
      return NetworkFailure(message: exception.message, statusCode: exception.statusCode);
    }
    if (exception is UnauthorizedException) {
      return UnauthorizedFailure(message: exception.message, statusCode: exception.statusCode);
    }
    if (exception is ForbiddenException) {
      return ForbiddenFailure(message: exception.message, statusCode: exception.statusCode);
    }
    if (exception is NotFoundException) {
      return NotFoundFailure(message: exception.message, statusCode: exception.statusCode);
    }
    if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        errors: exception.errors,
      );
    }
    if (exception is CacheException) {
      return CacheFailure(message: exception.message, statusCode: exception.statusCode);
    }
    return const UnknownFailure();
  }
}

/// Represents failures originating from remote server errors (5xx).
class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode = 500,
  });
}

/// Represents network transport, connectivity, or socket timeout failures.
class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.statusCode,
  });
}

/// Represents expired or missing authentication credentials (401).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    required super.message,
    super.statusCode = 401,
  });
}

/// Represents operations attempted without requisite role permissions or scope (403).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({
    required super.message,
    super.statusCode = 403,
  });
}

/// Represents records or resources that cannot be located (404).
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.statusCode = 404,
  });
}

/// Represents validation errors returned by the backend or business logic (422).
class ValidationFailure extends Failure {
  final Map<String, String>? errors;

  const ValidationFailure({
    required super.message,
    super.statusCode = 422,
    this.errors,
  });

  @override
  List<Object?> get props => [message, statusCode, errors];
}

/// Represents failures during local storage or cache retrieval.
class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.statusCode,
  });
}

/// Fallback failure for unclassified exceptions with safe, sanitized user-facing message.
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred. Please try again.',
    super.statusCode,
  });
}
