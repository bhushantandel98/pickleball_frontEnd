import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/access/user_role.dart';

/// Domain entity representing a successfully initiated registration awaiting OTP verification.
class RegistrationInitiatedEntity extends Equatable {
  final String phone;
  final String otpSessionId;
  final int resendCountdownSeconds;

  const RegistrationInitiatedEntity({
    required this.phone,
    required this.otpSessionId,
    this.resendCountdownSeconds = 30,
  });

  @override
  List<Object?> get props => [phone, otpSessionId, resendCountdownSeconds];
}

/// Domain entity representing a completed and verified Player registration.
///
/// Follows Platform Rules: A newly registered user strictly receives an independent
/// Player account. Coach, Academy, Venue, and other organization roles are never
/// automatically granted during self-registration.
class PlayerRegistrationSuccessEntity extends Equatable {
  final String userId;
  final String fullName;
  final String phone;
  final UserRole assignedRole;
  final DateTime createdAt;

  const PlayerRegistrationSuccessEntity({
    required this.userId,
    required this.fullName,
    required this.phone,
    this.assignedRole = UserRole.player,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [userId, fullName, phone, assignedRole, createdAt];
}
