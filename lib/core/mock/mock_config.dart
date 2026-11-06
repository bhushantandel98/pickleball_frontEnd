import 'package:flutter/foundation.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/mock/simulated_error_type.dart';

/// Centralized configuration for mock network latency and error simulation.
///
/// Complies with ADR-011 and ADR-015:
/// In release mode (`kReleaseMode == true`), mock simulation is permanently disabled
/// and attempts to execute simulation throw [UnsupportedError].
class MockConfig {
  static final MockConfig _instance = MockConfig._internal();

  /// Shared singleton instance for developer convenience.
  static MockConfig get instance => _instance;

  MockConfig._internal() {
    _enabled = !kReleaseMode;
    _isLatencyEnabled = !kReleaseMode;
    _latencyDuration = const Duration(milliseconds: 400);
    _isFailureSimulated = false;
    _simulatedErrorType = SimulatedErrorType.none;
  }

  /// Factory constructor returning the singleton or isolated instance.
  factory MockConfig() => _instance;

  bool _enabled = !kReleaseMode;
  bool _isLatencyEnabled = !kReleaseMode;
  Duration _latencyDuration = const Duration(milliseconds: 400);
  bool _isFailureSimulated = false;
  SimulatedErrorType _simulatedErrorType = SimulatedErrorType.none;

  /// Whether the mock infrastructure is active. Always `false` in release mode.
  bool get enabled => !kReleaseMode && _enabled;

  /// Whether simulated network latency is active.
  bool get isLatencyEnabled => enabled && _isLatencyEnabled;

  /// The duration of simulated network latency (default: 400ms).
  Duration get latencyDuration => _latencyDuration;

  /// Whether error simulation is active.
  bool get isFailureSimulated => enabled && _isFailureSimulated;

  /// The current error type being simulated.
  SimulatedErrorType get simulatedErrorType => _simulatedErrorType;

  // --- Configuration Controls (Permitted in non-release mode only) ---

  /// Enables or disables mock simulation infrastructure.
  void setEnabled(bool value) {
    if (kReleaseMode) return;
    _enabled = value;
  }

  /// Enables or disables fake network latency.
  void setLatencyEnabled(bool value) {
    if (kReleaseMode) return;
    _isLatencyEnabled = value;
  }

  /// Configures the fake network latency duration.
  void setLatencyDuration(Duration duration) {
    if (kReleaseMode) return;
    _latencyDuration = duration;
  }

  /// Configures and enables an error simulation scenario.
  void simulateError(SimulatedErrorType errorType) {
    if (kReleaseMode) return;
    if (errorType == SimulatedErrorType.none) {
      clearSimulatedError();
    } else {
      _isFailureSimulated = true;
      _simulatedErrorType = errorType;
    }
  }

  /// Clears active error simulation, restoring normal mock responses.
  void clearSimulatedError() {
    _isFailureSimulated = false;
    _simulatedErrorType = SimulatedErrorType.none;
  }

  /// Resets mock configuration to default non-error state.
  void reset() {
    if (kReleaseMode) return;
    _enabled = true;
    _isLatencyEnabled = true;
    _latencyDuration = const Duration(milliseconds: 400);
    _isFailureSimulated = false;
    _simulatedErrorType = SimulatedErrorType.none;
  }

  // --- Runtime Simulation Execution ---

  /// Awaits the configured latency duration if latency simulation is enabled.
  ///
  /// Returns immediately if latency is disabled or running in release mode.
  Future<void> simulateDelay() async {
    if (kReleaseMode || !enabled || !_isLatencyEnabled || _latencyDuration <= Duration.zero) {
      return;
    }
    await Future.delayed(_latencyDuration);
  }

  /// Throws the active simulated exception if error simulation is active.
  ///
  /// In release mode, throws [UnsupportedError] to prevent accidental execution.
  void maybeThrowException() {
    if (kReleaseMode) {
      throw UnsupportedError('Mock error simulation cannot run in release mode (ADR-015).');
    }
    if (!enabled || !_isFailureSimulated || _simulatedErrorType == SimulatedErrorType.none) {
      return;
    }
    throw _simulatedErrorType.toException();
  }

  /// Returns the active simulated [Failure] if error simulation is active; otherwise null.
  Failure? getSimulatedFailure() {
    if (kReleaseMode) {
      throw UnsupportedError('Mock error simulation cannot run in release mode (ADR-015).');
    }
    if (!enabled || !_isFailureSimulated || _simulatedErrorType == SimulatedErrorType.none) {
      return null;
    }
    return _simulatedErrorType.toFailure();
  }
}
