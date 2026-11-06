import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Real remote API implementation of [UserProfileRepository].
///
/// Registered in [initRemoteServiceLocator] when live backend endpoints are connected.
/// Demonstrates the exact drop-in replacement architecture: presentations and Blocs
/// depend exclusively on [UserProfileRepository], with zero code changes required
/// to switch from [MockUserProfileRepository] to [RemoteUserProfileRepository].
class RemoteUserProfileRepository implements UserProfileRepository {
  // Real HTTP client / Dio client will be injected here during Phase 1+
  // final ApiClient apiClient;

  const RemoteUserProfileRepository();

  @override
  Future<Result<UserProfile>> getUserProfile(String userId) async {
    // When live APIs are connected in Phase 1, execute HTTP GET /api/v1/users/:id
    return const FailureResult(
      ServerFailure(message: 'Remote API endpoints will be connected in Phase 1.'),
    );
  }

  @override
  Future<Result<UserProfile>> updateUserProfile(UserProfile profile) async {
    // When live APIs are connected in Phase 1, execute HTTP PUT /api/v1/users/:id
    return const FailureResult(
      ServerFailure(message: 'Remote API endpoints will be connected in Phase 1.'),
    );
  }

  @override
  Future<Result<List<UserRole>>> getUserRoles(String userId) async {
    // When live APIs are connected in Phase 1, execute HTTP GET /api/v1/users/:id/roles
    return const FailureResult(
      ServerFailure(message: 'Remote API endpoints will be connected in Phase 1.'),
    );
  }
}
