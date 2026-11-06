import 'package:equatable/equatable.dart';

/// Entity representing an active password reset verification session.
final class PasswordResetInitiatedEntity extends Equatable {
  final String phone;
  final String resetSessionId;
  final int resendCountdownSeconds;

  const PasswordResetInitiatedEntity({
    required this.phone,
    required this.resetSessionId,
    this.resendCountdownSeconds = 30,
  });

  @override
  List<Object?> get props => [phone, resetSessionId, resendCountdownSeconds];
}

/// Entity representing a verified password reset session ready for new password submission.
final class PasswordResetVerifiedEntity extends Equatable {
  final String phone;
  final String resetSessionId;
  final String resetToken;

  const PasswordResetVerifiedEntity({
    required this.phone,
    required this.resetSessionId,
    required this.resetToken,
  });

  @override
  List<Object?> get props => [phone, resetSessionId, resetToken];
}

/// Entity representing the successful completion of a password reset operation.
final class PasswordResetSuccessEntity extends Equatable {
  final String phone;
  final String message;
  final DateTime timestamp;

  const PasswordResetSuccessEntity({
    required this.phone,
    required this.message,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [phone, message, timestamp];
}
