import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_inquiry_state.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

class CoachInquiryCubit extends Cubit<CoachInquiryState> {
  final CoachingAcademyRepository _repository;
  final UserProfileRepository? userProfileRepository;
  final SessionCubit? sessionCubit;

  CoachInquiryCubit(
    this._repository, {
    this.userProfileRepository,
    this.sessionCubit,
  }) : super(const CoachInquiryInitial());

  Future<void> init({
    required String coachId,
    String? preSelectedServiceId,
    String? userId,
  }) async {
    final result = await _repository.getCoachById(coachId);
    if (result is Success<CoachItem>) {
      UserProfile? profile;
      final targetUserId = userId ??
          (sessionCubit?.state.isAuthenticated == true
              ? sessionCubit?.state.userId
              : null);

      final profileRepo = userProfileRepository;
      if (targetUserId != null && profileRepo != null) {
        final profileResult = await profileRepo.getUserProfile(targetUserId);
        if (profileResult is Success<UserProfile>) {
          profile = profileResult.data;
        }
      }

      emit(CoachInquiryReady(
        coach: result.data,
        selectedServiceId: preSelectedServiceId ??
            (result.data.services.isNotEmpty ? result.data.services.first.id : null),
        applicantProfile: profile,
      ));
    } else {
      emit(const CoachInquiryFailure('Unable to load coach details.'));
    }
  }

  void selectService(String serviceId) {
    final current = state;
    if (current is CoachInquiryReady) {
      emit(current.copyWith(selectedServiceId: serviceId));
    }
  }

  Future<bool> submitInquiry({
    required String playerName,
    required String playerPhone,
    String playerEmail = '',
    required String preferredDays,
    double? playerRating,
    required String trainingGoal,
    required String message,
  }) async {
    final current = state;
    if (current is! CoachInquiryReady) return false;

    if (playerName.trim().isEmpty) {
      emit(current.copyWith(errorMessage: 'Please enter your name.'));
      return false;
    }
    if (playerPhone.trim().isEmpty || playerPhone.trim().length < 8) {
      emit(current.copyWith(errorMessage: 'Please enter a valid contact phone number.'));
      return false;
    }
    if (preferredDays.trim().isEmpty) {
      emit(current.copyWith(errorMessage: 'Please indicate your preferred days or times.'));
      return false;
    }
    if (trainingGoal.trim().isEmpty) {
      emit(current.copyWith(errorMessage: 'Please specify your primary training objective.'));
      return false;
    }
    if (message.trim().isEmpty) {
      emit(current.copyWith(errorMessage: 'Please write a brief note for the coach.'));
      return false;
    }

    emit(current.copyWith(isSubmitting: true, errorMessage: null));

    final result = await _repository.submitCoachInquiry(
      coachId: current.coach.id,
      serviceId: current.selectedServiceId,
      playerName: playerName.trim(),
      playerPhone: playerPhone.trim(),
      playerEmail: playerEmail.trim(),
      preferredDays: preferredDays.trim(),
      playerRating: playerRating,
      trainingGoal: trainingGoal.trim(),
      message: message.trim(),
    );

    switch (result) {
      case Success(:final data):
        emit(CoachInquirySuccess(data));
        return true;
      case FailureResult(:final failure):
        emit(current.copyWith(
          isSubmitting: false,
          errorMessage: failure.message,
        ));
        return false;
    }
  }
}
