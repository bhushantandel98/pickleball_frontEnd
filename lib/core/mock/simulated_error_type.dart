import 'package:pickleball_platform/core/errors/exceptions.dart';
import 'package:pickleball_platform/core/errors/failures.dart';

/// Supported error types for development and QA mock simulation.
enum SimulatedErrorType {
  /// Normal successful mock operation; no error triggered.
  none,

  /// Simulates a network transport failure, connectivity drop, or timeout.
  networkTimeout,

  /// Simulates an unexpected internal server error (HTTP 500).
  serverError,

  /// Simulates an expired, invalid, or missing authentication credential (HTTP 401).
  unauthorized,

  /// Simulates an unauthorized role or permission boundary violation (HTTP 403).
  forbidden,

  /// Simulates a resource not found error (HTTP 404).
  notFound,

  /// Simulates a payload validation failure (HTTP 422).
  validationError;

  /// Human-readable label for dev panels and diagnostics.
  String get displayName => switch (this) {
        SimulatedErrorType.none => 'None (Success)',
        SimulatedErrorType.networkTimeout => 'Network Timeout / Offline',
        SimulatedErrorType.serverError => 'Server Error (500)',
        SimulatedErrorType.unauthorized => 'Unauthorized (401)',
        SimulatedErrorType.forbidden => 'Forbidden (403)',
        SimulatedErrorType.notFound => 'Not Found (404)',
        SimulatedErrorType.validationError => 'Validation Error (422)',
      };

  /// Constructs the corresponding [AppException].
  AppException toException() => switch (this) {
        SimulatedErrorType.none => throw StateError('Cannot create exception for SimulatedErrorType.none'),
        SimulatedErrorType.networkTimeout => const NetworkException(
            message: 'Simulated network timeout: Connection to server lost.',
          ),
        SimulatedErrorType.serverError => const ServerException(
            message: 'Simulated internal server error: The remote service encountered an error.',
          ),
        SimulatedErrorType.unauthorized => const UnauthorizedException(
            message: 'Simulated unauthorized access: Authentication credentials expired.',
          ),
        SimulatedErrorType.forbidden => const ForbiddenException(
            message: 'Simulated forbidden access: Current role lacks permission for this resource.',
          ),
        SimulatedErrorType.notFound => const NotFoundException(
            message: 'Simulated not found: The requested record does not exist.',
          ),
        SimulatedErrorType.validationError => const ValidationException(
            message: 'Simulated validation error: Payload input failed validation checks.',
            errors: {'field': 'Invalid input data provided.'},
          ),
      };

  /// Constructs the corresponding domain [Failure].
  Failure toFailure() => switch (this) {
        SimulatedErrorType.none => throw StateError('Cannot create failure for SimulatedErrorType.none'),
        SimulatedErrorType.networkTimeout => const NetworkFailure(
            message: 'Simulated network timeout: Connection to server lost.',
          ),
        SimulatedErrorType.serverError => const ServerFailure(
            message: 'Simulated internal server error: The remote service encountered an error.',
          ),
        SimulatedErrorType.unauthorized => const UnauthorizedFailure(
            message: 'Simulated unauthorized access: Authentication credentials expired.',
          ),
        SimulatedErrorType.forbidden => const ForbiddenFailure(
            message: 'Simulated forbidden access: Current role lacks permission for this resource.',
          ),
        SimulatedErrorType.notFound => const NotFoundFailure(
            message: 'Simulated not found: The requested record does not exist.',
          ),
        SimulatedErrorType.validationError => const ValidationFailure(
            message: 'Simulated validation error: Payload input failed validation checks.',
            errors: {'field': 'Invalid input data provided.'},
          ),
      };
}
