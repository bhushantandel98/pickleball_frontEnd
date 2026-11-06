import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Abstract repository contract for user profile and role operations.
///
/// Follows Clean Architecture by residing purely in the domain layer,
/// completely isolated from HTTP clients, SQLite/Hive caches, or mock implementations.
abstract interface class UserProfileRepository {
  /// Fetches a user profile by [userId].
  Future<Result<UserProfile>> getUserProfile(String userId);

  /// Updates profile details (name, phone, avatar) for a user.
  Future<Result<UserProfile>> updateUserProfile(UserProfile profile);

  /// Retrieves all authorized platform roles for [userId].
  Future<Result<List<UserRole>>> getUserRoles(String userId);
}
