import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/access/user_role.dart';

/// Domain entity representing an authenticated user session.
///
/// Encapsulates authentication credentials and multi-role assignments.
/// Follows platform principles: One account per person, multiple roles per account.
class AuthSession extends Equatable {
  final String userId;
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int? expiresIn;
  final String name;
  final String phone;
  final String? email;
  final List<UserRole> availableRoles;
  final UserRole? activeRole;
  final bool isSuspended;

  const AuthSession({
    required this.userId,
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn,
    required this.name,
    required this.phone,
    this.email,
    required this.availableRoles,
    this.activeRole,
    this.isSuspended = false,
  });

  /// True if the authenticated user possesses more than one role.
  bool get hasMultipleRoles => availableRoles.length > 1;

  @override
  List<Object?> get props => [
        userId,
        accessToken,
        refreshToken,
        tokenType,
        expiresIn,
        name,
        phone,
        email,
        availableRoles,
        activeRole,
        isSuspended,
      ];
}
