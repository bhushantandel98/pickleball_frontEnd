import 'package:pickleball_platform/core/errors/failures.dart';

/// Sealed result container representing either a successful domain outcome or a failure.
///
/// Approved under ADR-006 to provide compile-safe, explicit error handling without throwing.
sealed class Result<T> {
  const Result();

  /// Returns true if this instance represents a successful outcome.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this instance represents a failure.
  bool get isFailure => this is FailureResult<T>;

  /// Returns the underlying data if [isSuccess] is true; otherwise returns null.
  T? get dataOrNull => switch (this) {
        Success<T>(data: final d) => d,
        FailureResult<T>() => null,
      };

  /// Returns the underlying [Failure] if [isFailure] is true; otherwise returns null.
  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        FailureResult<T>(failure: final f) => f,
      };

  /// Pattern-matches over [Success] and [FailureResult] states.
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) =>
      switch (this) {
        Success<T>(data: final d) => success(d),
        FailureResult<T>(failure: final f) => failure(f),
      };
}

/// Represents a successful operation delivering [data] of type [T].
final class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success(data: $data)';
}

/// Represents a failed operation holding a typed [failure].
final class FailureResult<T> extends Result<T> {
  final Failure failure;

  const FailureResult(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FailureResult<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'FailureResult(failure: $failure)';
}
