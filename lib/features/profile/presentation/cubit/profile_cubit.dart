import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_state.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Cubit managing presentation state for user profile view and editing workflows.
class ProfileCubit extends Cubit<ProfileState> {
  final UserProfileRepository repository;

  ProfileCubit({required this.repository}) : super(const ProfileInitial());

  /// Loads profile information for [userId].
  ///
  /// Falls back to default multi-role mock identifier `user_multi_001` if not provided.
  Future<void> loadProfile({String? userId}) async {
    final effectiveId = (userId != null && userId.isNotEmpty)
        ? userId
        : 'user_multi_001';

    emit(const ProfileLoading());

    final result = await repository.getUserProfile(effectiveId);

    switch (result) {
      case Success<UserProfile>(data: final profile):
        emit(ProfileLoaded(profile: profile));
      case FailureResult<UserProfile>(failure: final failure):
        emit(ProfileFailure(message: failure.message));
    }
  }

  /// Commits updated profile personal information.
  Future<bool> updateProfile(UserProfile updatedProfile) async {
    final currentProfile = state is ProfileLoaded
        ? (state as ProfileLoaded).profile
        : updatedProfile;

    emit(ProfileUpdating(currentProfile));

    final result = await repository.updateUserProfile(updatedProfile);

    switch (result) {
      case Success<UserProfile>(data: final saved):
        emit(ProfileLoaded(
          profile: saved,
          successMessage: 'Profile updated successfully',
        ));
        return true;
      case FailureResult<UserProfile>(failure: final failure):
        emit(ProfileFailure(
          message: failure.message,
          fallbackProfile: currentProfile,
        ));
        return false;
    }
  }

  /// Directly updates the active profile state with [updatedProfile] without a second repository call.
  void applyUpdatedProfile(UserProfile updatedProfile, {String? successMessage}) {
    emit(ProfileLoaded(
      profile: updatedProfile,
      successMessage: successMessage ?? 'Profile updated successfully',
    ));
  }

  /// Clears any transient feedback banner messages.
  void clearFeedbackMessage() {
    if (state is ProfileLoaded) {
      final current = state as ProfileLoaded;
      if (current.successMessage != null) {
        emit(ProfileLoaded(profile: current.profile));
      }
    }
  }
}
