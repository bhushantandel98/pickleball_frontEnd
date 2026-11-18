import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_state.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Cubit managing presentation state for user profile view and editing workflows.
class ProfileCubit extends Cubit<ProfileState> {
  final UserProfileRepository repository;
  final AuthRepository? authRepository;

  ProfileCubit({
    required this.repository,
    this.authRepository,
  }) : super(const ProfileInitial());

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

  /// Persists privacy visibility preferences through [UserProfileRepository].
  Future<Result<UserProfile>> updatePrivacyPreferences({
    required bool publicPlayerProfile,
    required bool showMatchHistory,
  }) async {
    final currentProfile = switch (state) {
      ProfileLoaded(profile: final profile) => profile,
      ProfileUpdating(currentProfile: final profile) => profile,
      ProfileFailure(fallbackProfile: final profile) => profile,
      _ => null,
    };

    if (currentProfile == null) {
      return const FailureResult<UserProfile>(
        UnknownFailure(message: 'User profile must be loaded before saving preferences.'),
      );
    }

    final updated = currentProfile.copyWith(
      publicPlayerProfile: publicPlayerProfile,
      showMatchHistory: showMatchHistory,
    );

    final result = await repository.updateUserProfile(updated);
    switch (result) {
      case Success<UserProfile>(data: final saved):
        emit(ProfileLoaded(profile: saved));
        return Success<UserProfile>(saved);
      case FailureResult<UserProfile>(failure: final failure):
        emit(ProfileLoaded(profile: currentProfile));
        return FailureResult<UserProfile>(failure);
    }
  }

  /// Updates the user's password via [AuthRepository].
  Future<Result<void>> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final repo = authRepository ??
        (sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : null);
    if (repo == null) {
      return const FailureResult<void>(
        UnknownFailure(message: 'Password service is unavailable.'),
      );
    }
    return repo.changePassword(
      userId: userId,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
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
