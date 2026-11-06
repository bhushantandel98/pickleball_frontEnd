import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/role_selection/domain/entities/role_context.dart';

/// Clean Architecture domain repository interface for role context resolution
/// and preferred role assignment persistence.
abstract interface class RoleContextRepository {
  /// Fetches the authenticated user's identity and active role assignments.
  ///
  /// Proposed API Contract: `GET /api/v1/auth/roles`
  Future<Result<RoleContext>> getRoleContext(String userId);

  /// Persists the user's chosen preferred role assignment.
  ///
  /// Proposed API Contract: `PUT /api/v1/users/preferences/preferred-role`
  /// Request body: `{ "roleAssignmentId": roleAssignmentId }`
  Future<Result<void>> selectPreferredRole({
    required String userId,
    required String roleAssignmentId,
    UserRole? role,
  });

  /// Clears the user's preferred role assignment.
  ///
  /// Proposed API Contract: `DELETE /api/v1/users/preferences/preferred-role`
  Future<Result<void>> clearPreferredRole(String userId);
}
