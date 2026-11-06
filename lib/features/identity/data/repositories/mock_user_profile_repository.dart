import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/errors/exceptions.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/identity/data/datasources/user_profile_data_source.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Concrete mock implementation of [UserProfileRepository].
///
/// Converts exceptions from [UserProfileDataSource] into compile-safe [Result] types.
/// Demonstrates the standard Clean Architecture repository pattern for all 12 platform roles.
class MockUserProfileRepository implements UserProfileRepository {
  final UserProfileDataSource dataSource;

  const MockUserProfileRepository({required this.dataSource});

  @override
  Future<Result<UserProfile>> getUserProfile(String userId) async {
    try {
      final profile = await dataSource.getUserProfile(userId);
      return Success(profile);
    } on AppException catch (e) {
      return FailureResult(Failure.fromException(e));
    } catch (_) {
      return const FailureResult<UserProfile>(UnknownFailure());
    }
  }

  @override
  Future<Result<UserProfile>> updateUserProfile(UserProfile profile) async {
    try {
      final updated = await dataSource.updateUserProfile(profile);
      return Success(updated);
    } on AppException catch (e) {
      return FailureResult(Failure.fromException(e));
    } catch (_) {
      return const FailureResult<UserProfile>(UnknownFailure());
    }
  }

  @override
  Future<Result<List<UserRole>>> getUserRoles(String userId) async {
    try {
      final roles = await dataSource.getUserRoles(userId);
      return Success(roles);
    } on AppException catch (e) {
      return FailureResult(Failure.fromException(e));
    } catch (_) {
      return const FailureResult<List<UserRole>>(UnknownFailure());
    }
  }
}
