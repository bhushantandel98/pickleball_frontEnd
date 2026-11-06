import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Abstract data source interface for UserProfile operations.
///
/// Both [MockUserProfileDataSource] and future [RemoteUserProfileDataSource]
/// implement this exact contract.
abstract interface class UserProfileDataSource {
  /// Fetches a user profile raw entity/model by [userId].
  Future<UserProfile> getUserProfile(String userId);

  /// Updates profile details and returns the updated user profile.
  Future<UserProfile> updateUserProfile(UserProfile profile);

  /// Retrieves authorized roles for [userId].
  Future<List<UserRole>> getUserRoles(String userId);
}
