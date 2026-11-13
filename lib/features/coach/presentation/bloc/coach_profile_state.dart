import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_profile.dart';

/// Base state hierarchy for Coach Profile.
sealed class CoachProfileState extends Equatable {
  const CoachProfileState();

  @override
  List<Object?> get props => [];
}

class CoachProfileInitial extends CoachProfileState {
  const CoachProfileInitial();
}

class CoachProfileLoading extends CoachProfileState {
  const CoachProfileLoading();
}

class CoachProfileLoaded extends CoachProfileState {
  final CoachProfile profile;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const CoachProfileLoaded({
    required this.profile,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  CoachProfileLoaded copyWith({
    CoachProfile? profile,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? isErrorFeedback,
  }) {
    return CoachProfileLoaded(
      profile: profile ?? this.profile,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isErrorFeedback:
          clearFeedback ? false : (isErrorFeedback ?? this.isErrorFeedback),
    );
  }

  @override
  List<Object?> get props => [profile, feedbackMessage, isErrorFeedback];
}

class CoachProfileEmpty extends CoachProfileState {
  final String message;

  const CoachProfileEmpty({
    this.message = 'No coach profile found. Please complete coach onboarding.',
  });

  @override
  List<Object?> get props => [message];
}

class CoachProfileFailure extends CoachProfileState {
  final Failure failure;

  const CoachProfileFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
