import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/features/role_selection/domain/entities/role_context.dart';

/// DTO representing an individual role assignment in API responses.
///
/// Follows strict parsing rules:
/// - Missing or null `role` is NEVER defaulted to `player`.
/// - Missing or null `isActive` is NEVER defaulted to `true`.
/// - Incomplete or invalid role assignments can never become active or selectable.
class RoleProfileModel extends Equatable {
  final String? roleAssignmentId;
  final String? role;
  final String? organizationId;
  final String? organizationName;
  final String? tournamentId;
  final String? tournamentName;
  final bool? isActive;
  final String? description;

  const RoleProfileModel({
    this.roleAssignmentId,
    this.role,
    this.organizationId,
    this.organizationName,
    this.tournamentId,
    this.tournamentName,
    this.isActive,
    this.description,
  });

  factory RoleProfileModel.fromJson(Map<String, dynamic> json) {
    return RoleProfileModel(
      roleAssignmentId: json['roleAssignmentId'] as String?,
      role: json['role'] as String?,
      organizationId: json['organizationId'] as String?,
      organizationName: json['organizationName'] as String?,
      tournamentId: json['tournamentId'] as String?,
      tournamentName: json['tournamentName'] as String?,
      isActive: json['isActive'] is bool ? json['isActive'] as bool : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (roleAssignmentId != null) 'roleAssignmentId': roleAssignmentId,
        if (role != null) 'role': role,
        if (organizationId != null) 'organizationId': organizationId,
        if (organizationName != null) 'organizationName': organizationName,
        if (tournamentId != null) 'tournamentId': tournamentId,
        if (tournamentName != null) 'tournamentName': tournamentName,
        if (isActive != null) 'isActive': isActive,
        if (description != null) 'description': description,
      };

  RoleProfile? toEntity() {
    // 1. Missing or empty role string cannot be resolved
    if (role == null || role!.trim().isEmpty) return null;

    // 2. Resolve UserRole enum
    final normalized = role!.toLowerCase().replaceAll('_', '-');
    UserRole? userRole = UserRole.fromId(role!) ?? UserRole.fromId(normalized);
    if (userRole == null) {
      for (final r in UserRole.values) {
        if (r.name.toLowerCase() == role!.toLowerCase()) {
          userRole = r;
          break;
        }
      }
    }
    if (userRole == null) return null;

    // 3. Strict active status: Only explicit true is active; null/missing or false is false
    final active = isActive == true;

    // 4. Role assignment ID: use provided unique ID or fallback to deterministic format
    final assignmentId =
        roleAssignmentId != null && roleAssignmentId!.trim().isNotEmpty
            ? roleAssignmentId!
            : 'assign_${userRole.id}_${organizationId ?? "default"}';

    return RoleProfile(
      roleAssignmentId: assignmentId,
      role: userRole,
      organizationId: organizationId,
      organizationName: organizationName,
      tournamentId: tournamentId,
      tournamentName: tournamentName,
      isActive: active,
      description: description,
    );
  }

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

/// DTO representing the user identity and assigned role contexts.
class RoleContextModel extends Equatable {
  final String userId;
  final String displayName;
  final String phone;
  final String? email;
  final List<RoleProfileModel> roles;
  final String? preferredRoleAssignmentId;
  final String? preferredRoleId;

  const RoleContextModel({
    required this.userId,
    required this.displayName,
    required this.phone,
    this.email,
    required this.roles,
    this.preferredRoleAssignmentId,
    this.preferredRoleId,
  });

  factory RoleContextModel.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'] as List<dynamic>? ?? [];
    return RoleContextModel(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      roles: rolesRaw
          .whereType<Map<String, dynamic>>()
          .map(RoleProfileModel.fromJson)
          .toList(),
      preferredRoleAssignmentId: json['preferredRoleAssignmentId'] as String?,
      preferredRoleId: json['preferredRoleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'displayName': displayName,
        'phone': phone,
        if (email != null) 'email': email,
        'roles': roles.map((r) => r.toJson()).toList(),
        if (preferredRoleAssignmentId != null)
          'preferredRoleAssignmentId': preferredRoleAssignmentId,
        if (preferredRoleId != null) 'preferredRoleId': preferredRoleId,
      };

  RoleContext toEntity() {
    final profiles = roles
        .map((m) => m.toEntity())
        .whereType<RoleProfile>()
        .toList();

    UserRole? preferred;
    if (preferredRoleId != null) {
      final normalized = preferredRoleId!.toLowerCase().replaceAll('_', '-');
      preferred =
          UserRole.fromId(preferredRoleId!) ?? UserRole.fromId(normalized);
      if (preferred == null) {
        for (final r in UserRole.values) {
          if (r.name.toLowerCase() == preferredRoleId!.toLowerCase()) {
            preferred = r;
            break;
          }
        }
      }
    }

    return RoleContext(
      userId: userId,
      displayName: displayName,
      phone: phone,
      email: email,
      roleProfiles: profiles,
      preferredRoleAssignmentId: preferredRoleAssignmentId,
      preferredRole: preferred,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        displayName,
        phone,
        email,
        roles,
        preferredRoleAssignmentId,
        preferredRoleId,
      ];
}
