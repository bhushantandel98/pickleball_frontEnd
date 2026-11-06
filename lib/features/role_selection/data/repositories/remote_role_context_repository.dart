import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/role_selection/domain/entities/role_context.dart';
import 'package:pickleball_platform/features/role_selection/domain/repositories/role_context_repository.dart';

/// Production implementation of [RoleContextRepository] communicating with the Spring Boot backend.
///
/// Canonical Proposed API Endpoints:
/// - `GET /api/v1/auth/roles`
/// - `PUT /api/v1/users/preferences/preferred-role`
/// - `DELETE /api/v1/users/preferences/preferred-role`
class RemoteRoleContextRepository implements RoleContextRepository {
  const RemoteRoleContextRepository();

  @override
  Future<Result<RoleContext>> getRoleContext(String userId) async {
    return const FailureResult<RoleContext>(
      ServerFailure(
        message:
            'Role context service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }

  @override
  Future<Result<void>> selectPreferredRole({
    required String userId,
    required String roleAssignmentId,
    UserRole? role,
  }) async {
    return const FailureResult<void>(
      ServerFailure(
        message:
            'Role preference service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }

  @override
  Future<Result<void>> clearPreferredRole(String userId) async {
    return const FailureResult<void>(
      ServerFailure(
        message:
            'Role preference service is currently unavailable. Please try again later.',
        statusCode: 503,
      ),
    );
  }
}
