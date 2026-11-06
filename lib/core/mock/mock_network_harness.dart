import 'package:flutter/foundation.dart';
import 'package:pickleball_platform/core/errors/exceptions.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/mock/mock_config.dart';
import 'package:pickleball_platform/core/mock/simulated_error_type.dart';
import 'package:pickleball_platform/core/network/result.dart';

/// Network simulation harness for mock data sources and repositories.
///
/// Implements ADR-011 (Configurable Latency & Error Toggles) and ADR-015 (Production Isolation).
/// In release mode, any invocation immediately throws [UnsupportedError].
class MockNetworkHarness {
  final MockConfig config;

  MockNetworkHarness({MockConfig? config})
      : config = config ?? MockConfig.instance;

  /// Simulates a raw network request, applying configured delay and throwing exceptions
  /// if an error scenario is configured in [MockConfig].
  ///
  /// Used primarily in mock data sources.
  Future<T> request<T>(Future<T> Function() executor) async {
    if (kReleaseMode) {
      throw UnsupportedError(
        'MockNetworkHarness cannot be executed in production builds (ADR-015).',
      );
    }

    await config.simulateDelay();
    config.maybeThrowException();

    return await executor();
  }

  /// Simulates a domain repository call, returning a type-safe [Result<T>].
  ///
  /// If an error scenario is configured, returns a [FailureResult] with the
  /// corresponding [Failure]. Catches any [AppException] thrown during execution
  /// and maps it cleanly into a [FailureResult].
  Future<Result<T>> requestResult<T>(Future<T> Function() executor) async {
    if (kReleaseMode) {
      throw UnsupportedError(
        'MockNetworkHarness cannot be executed in production builds (ADR-015).',
      );
    }

    await config.simulateDelay();

    // Check for simulated failure first
    if (config.isFailureSimulated && config.simulatedErrorType != SimulatedErrorType.none) {
      return FailureResult<T>(config.simulatedErrorType.toFailure());
    }

    try {
      final data = await executor();
      return Success<T>(data);
    } on AppException catch (e) {
      return FailureResult<T>(Failure.fromException(e));
    } catch (_) {
      return FailureResult<T>(const UnknownFailure());
    }
  }
}
