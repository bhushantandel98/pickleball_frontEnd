import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Base class representing state transitions for profile viewing and editing.
sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state before profile data is requested.
final class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

/// State emitted while loading the user profile.
final class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

/// State emitted when the user profile is successfully loaded or saved.
final class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final String? successMessage;

  const ProfileLoaded({
    required this.profile,
    this.successMessage,
  });

  @override
  List<Object?> get props => [profile, successMessage];
}

/// State emitted while submitting updated profile data to the repository.
final class ProfileUpdating extends ProfileState {
  final UserProfile currentProfile;

  const ProfileUpdating(this.currentProfile);

  @override
  List<Object?> get props => [currentProfile];
}

/// State emitted when profile loading or updating fails.
final class ProfileFailure extends ProfileState {
  final String message;
  final UserProfile? fallbackProfile;

  const ProfileFailure({
    required this.message,
    this.fallbackProfile,
  });

  @override
  List<Object?> get props => [message, fallbackProfile];
}
