import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/access/user_role.dart';

/// Immutable model representing the active authentication and role session context.
///
/// Designed to be consumed by route guards, navigation shells, and DI singletons.
class SessionContext extends Equatable {
  final String? userId;
  final String? email;
  final String? displayName;
  final bool isAuthenticated;
  final bool isSuspended;
  final List<UserRole> availableRoles;
  final UserRole? activeRole;
  final String? activeRoleAssignmentId;
  final String? activeOrganizationId;
  final String? activeOrganizationName;
  final String? activeTournamentId;
  final String? activeTournamentName;
  final bool rememberPreferredRole;

  const SessionContext({
    this.userId,
    this.email,
    this.displayName,
    this.isAuthenticated = false,
    this.isSuspended = false,
    this.availableRoles = const [],
    this.activeRole,
    this.activeRoleAssignmentId,
    this.activeOrganizationId,
    this.activeOrganizationName,
    this.activeTournamentId,
    this.activeTournamentName,
    this.rememberPreferredRole = false,
  });

  /// Factory for an unauthenticated visitor session.
  const SessionContext.unauthenticated()
      : userId = null,
        email = null,
        displayName = null,
        isAuthenticated = false,
        isSuspended = false,
        availableRoles = const [],
        activeRole = null,
        activeRoleAssignmentId = null,
        activeOrganizationId = null,
        activeOrganizationName = null,
        activeTournamentId = null,
        activeTournamentName = null,
        rememberPreferredRole = false;

  /// Factory for an active authenticated user session.
  const SessionContext.authenticated({
    required this.userId,
    required this.email,
    this.displayName,
    required this.availableRoles,
    this.activeRole,
    this.activeRoleAssignmentId,
    this.activeOrganizationId,
    this.activeOrganizationName,
    this.activeTournamentId,
    this.activeTournamentName,
    this.rememberPreferredRole = false,
  })  : isAuthenticated = true,
        isSuspended = false;

  /// Factory for an authenticated but suspended user session.
  const SessionContext.suspended({
    required this.userId,
    required this.email,
    this.displayName,
    this.availableRoles = const [],
    this.activeRole,
    this.activeRoleAssignmentId,
    this.activeOrganizationId,
    this.activeOrganizationName,
    this.activeTournamentId,
    this.activeTournamentName,
  })  : isAuthenticated = true,
        isSuspended = true,
        rememberPreferredRole = false;

  /// Whether the user possesses the specified [role] in their assigned roles.
  bool hasRole(UserRole role) => availableRoles.contains(role);

  SessionContext copyWith({
    String? userId,
    String? email,
    String? displayName,
    bool? isAuthenticated,
    bool? isSuspended,
    List<UserRole>? availableRoles,
    UserRole? activeRole,
    bool clearActiveRole = false,
    String? activeRoleAssignmentId,
    bool clearActiveRoleAssignmentId = false,
    String? activeOrganizationId,
    bool clearActiveOrganizationId = false,
    String? activeOrganizationName,
    bool clearActiveOrganizationName = false,
    String? activeTournamentId,
    bool clearActiveTournamentId = false,
    String? activeTournamentName,
    bool clearActiveTournamentName = false,
    bool? rememberPreferredRole,
  }) {
    return SessionContext(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isSuspended: isSuspended ?? this.isSuspended,
      availableRoles: availableRoles ?? this.availableRoles,
      activeRole: clearActiveRole ? null : (activeRole ?? this.activeRole),
      activeRoleAssignmentId: clearActiveRoleAssignmentId
          ? null
          : (activeRoleAssignmentId ?? this.activeRoleAssignmentId),
      activeOrganizationId: clearActiveOrganizationId
          ? null
          : (activeOrganizationId ?? this.activeOrganizationId),
      activeOrganizationName: clearActiveOrganizationName
          ? null
          : (activeOrganizationName ?? this.activeOrganizationName),
      activeTournamentId: clearActiveTournamentId
          ? null
          : (activeTournamentId ?? this.activeTournamentId),
      activeTournamentName: clearActiveTournamentName
          ? null
          : (activeTournamentName ?? this.activeTournamentName),
      rememberPreferredRole:
          rememberPreferredRole ?? this.rememberPreferredRole,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        email,
        displayName,
        isAuthenticated,
        isSuspended,
        availableRoles,
        activeRole,
        activeRoleAssignmentId,
        activeOrganizationId,
        activeOrganizationName,
        activeTournamentId,
        activeTournamentName,
        rememberPreferredRole,
      ];
}
