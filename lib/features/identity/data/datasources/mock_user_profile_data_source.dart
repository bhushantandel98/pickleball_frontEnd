import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/errors/exceptions.dart';
import 'package:pickleball_platform/core/mock/data/mock_data.dart';
import 'package:pickleball_platform/core/mock/mock_network_harness.dart';
import 'package:pickleball_platform/features/identity/data/datasources/user_profile_data_source.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Concrete mock data source for user profiles.
///
/// Wraps all memory access with [MockNetworkHarness] to simulate configurable
/// latency, offline timeouts, 401/403/500 errors, and validation responses.
class MockUserProfileDataSource implements UserProfileDataSource {
  final MockNetworkHarness harness;
  final List<UserProfile> _users;

  MockUserProfileDataSource({MockNetworkHarness? harness})
      : harness = harness ?? MockNetworkHarness(),
        _users = List.of(MockData.allUsers);

  UserProfile _findUser(String userId) {
    final match = _users.where((u) => u.id == userId || u.email == userId);
    if (match.isEmpty) {
      throw NotFoundException(
        message: 'User profile with identifier "$userId" not found in mock store.',
      );
    }
    return match.first;
  }

  @override
  Future<UserProfile> getUserProfile(String userId) {
    return harness.request(() async => _findUser(userId));
  }

  @override
  Future<UserProfile> updateUserProfile(UserProfile profile) {
    return harness.request(() async {
      if (profile.name.trim().isEmpty) {
        throw const ValidationException(
          message: 'Validation failed: Name cannot be empty.',
          errors: {'name': 'Full name is required.'},
        );
      }

      final index = _users.indexWhere((u) => u.id == profile.id);
      if (index == -1) {
        throw NotFoundException(
          message: 'Cannot update profile: User "${profile.id}" not found.',
        );
      }

      _users[index] = profile;
      return profile;
    });
  }

  @override
  Future<List<UserRole>> getUserRoles(String userId) {
    return harness.request(() async {
      final user = _findUser(userId);
      return user.availableRoles;
    });
  }
}
