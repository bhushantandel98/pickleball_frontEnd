import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/access/user_role.dart';

/// Metadata and organizational context for an assigned platform role.
class RoleProfile extends Equatable {
  final String roleAssignmentId;
  final UserRole role;
  final String? organizationId;
  final String? organizationName;
  final String? tournamentId;
  final String? tournamentName;
  final bool isActive;
  final String? _customDescription;

  const RoleProfile({
    required this.roleAssignmentId,
    required this.role,
    this.organizationId,
    this.organizationName,
    this.tournamentId,
    this.tournamentName,
    this.isActive = true,
    String? description,
  }) : _customDescription = description;

  String get description => _customDescription ?? defaultDescriptionFor(role);

  /// Primary context title for this assignment (tournament or organization name).
  String? get operationalContextName => tournamentName ?? organizationName;

  static String defaultDescriptionFor(UserRole role) =>
      _defaultDescriptions[role] ?? '';

  static const Map<UserRole, String> _defaultDescriptions = {
    UserRole.player:
        'Book courts, join coaching programs, enter tournaments, and track match scores.',
    UserRole.coach:
        'Manage training batches, player attendance, session schedules, and performance evaluations.',
    UserRole.academy:
        'Manage multi-branch coaching facilities, programs, coaches, and student enrollments.',
    UserRole.academyStaff:
        'Coordinate day-to-day academy branch operations, schedules, and attendance.',
    UserRole.venuePartner:
        'Manage venue court facilities, operational schedules, slot pricing, and reservations.',
    UserRole.venueStaff:
        'Oversee front-desk court check-ins, walk-in bookings, and facility operations.',
    UserRole.tournamentOrganizer:
        'Create tournaments, configure draws and brackets, and manage participant registrations.',
    UserRole.tournamentStaff:
        'Assist with tournament court assignments, participant check-ins, and desk coordination.',
    UserRole.referee:
        'Officiate tournament matches, log court scores, verify line calls, and finalize match results.',
    UserRole.marketplaceSeller:
        'Manage equipment catalogs, orders, shipments, and customer gear fulfillment.',
    UserRole.applicationStaff:
        'Monitor platform operations, user support escalations, and system workflows.',
    UserRole.applicationAdmin:
        'Complete platform administration, global role governance, and security oversight.',
  };

  @override
  List<Object?> get props => [
        roleAssignmentId,
        role,
        organizationId,
        organizationName,
        tournamentId,
        tournamentName,
        isActive,
        description,
      ];
}

/// Domain entity encapsulating the authenticated user's identity and active role contexts.
class RoleContext extends Equatable {
  final String userId;
  final String displayName;
  final String phone;
  final String? email;
  final List<RoleProfile> roleProfiles;
  final String? preferredRoleAssignmentId;
  final UserRole? preferredRole;

  const RoleContext({
    required this.userId,
    required this.displayName,
    required this.phone,
    this.email,
    required this.roleProfiles,
    this.preferredRoleAssignmentId,
    this.preferredRole,
  });

  /// All currently active and authorized role profiles.
  List<RoleProfile> get activeProfiles =>
      roleProfiles.where((p) => p.isActive).toList();

  /// All currently active and authorized [UserRole] enums.
  List<UserRole> get activeRoles =>
      activeProfiles.map((p) => p.role).toList();

  /// True if the user has more than one active role assignment available.
  bool get hasMultipleRoles => activeProfiles.length > 1;

  /// True if the user has no active roles assigned.
  bool get hasNoRoles => activeProfiles.isEmpty;

  /// Finds the [RoleProfile] for a specific role assignment ID, or null.
  RoleProfile? profileForAssignment(String assignmentId) {
    for (final profile in roleProfiles) {
      if (profile.roleAssignmentId == assignmentId) return profile;
    }
    return null;
  }

  /// Finds the first [RoleProfile] for a specific role, or null if unassigned.
  RoleProfile? profileFor(UserRole role) {
    for (final profile in roleProfiles) {
      if (profile.role == role) return profile;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        phone,
        email,
        roleProfiles,
        preferredRoleAssignmentId,
        preferredRole,
      ];
}
