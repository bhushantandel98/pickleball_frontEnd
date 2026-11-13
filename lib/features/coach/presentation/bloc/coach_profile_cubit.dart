import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_profile.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/coach_profile_repository.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_profile_state.dart';

/// Cubit managing Coach Profile viewing and editing (Phase 3 — Feature 3.2).
class CoachProfileCubit extends Cubit<CoachProfileState> {
  final CoachProfileRepository repository;

  CoachProfileCubit({
    required this.repository,
  }) : super(const CoachProfileInitial());

  Future<void> loadProfile({String? coachId}) async {
    emit(const CoachProfileLoading());
    final result = await repository.getCoachProfile(coachId: coachId);
    switch (result) {
      case Success(:final data):
        emit(CoachProfileLoaded(profile: data));
      case FailureResult(:final failure):
        if (failure is NotFoundFailure) {
          emit(CoachProfileEmpty(message: failure.message));
        } else {
          emit(CoachProfileFailure(failure));
        }
    }
  }

  Future<void> refreshProfile({String? coachId}) async {
    final result = await repository.getCoachProfile(coachId: coachId);
    switch (result) {
      case Success(:final data):
        emit(CoachProfileLoaded(profile: data));
      case FailureResult(:final failure):
        if (failure is NotFoundFailure) {
          emit(CoachProfileEmpty(message: failure.message));
        } else {
          emit(CoachProfileFailure(failure));
        }
    }
  }

  void clearFeedback() {
    final current = state;
    if (current is CoachProfileLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<bool> updatePersonalDetails({
    required String fullName,
    required String phone,
    required String email,
    required String city,
    required String bio,
  }) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.updatePersonalDetails(
      coachId: current.profile.coachId,
      fullName: fullName,
      phone: phone,
      email: email,
      city: city,
      bio: bio,
      avatarUrl: current.profile.avatarUrl,
    );
    return _applyMutationResult(result, 'Personal details updated.');
  }

  Future<bool> updateAvatar(String? avatarUrl) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.updatePersonalDetails(
      coachId: current.profile.coachId,
      fullName: current.profile.fullName,
      phone: current.profile.phone,
      email: current.profile.email,
      city: current.profile.city,
      bio: current.profile.bio,
      avatarUrl: avatarUrl,
      clearAvatar: avatarUrl == null,
    );
    return _applyMutationResult(result, 'Profile photo updated.');
  }

  Future<bool> updateExperience({
    required int yearsOfExperience,
    required String coachingExperienceSummary,
    required String professionalBackground,
  }) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.updateExperience(
      coachId: current.profile.coachId,
      yearsOfExperience: yearsOfExperience,
      coachingExperienceSummary: coachingExperienceSummary,
      professionalBackground: professionalBackground,
    );
    return _applyMutationResult(result, 'Experience details updated.');
  }

  Future<bool> addCertification(CoachCertification certification) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.addCertification(
      coachId: current.profile.coachId,
      certification: certification,
    );
    return _applyMutationResult(result, 'Certification added.');
  }

  Future<bool> updateCertification(CoachCertification certification) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.updateCertification(
      coachId: current.profile.coachId,
      certification: certification,
    );
    return _applyMutationResult(result, 'Certification updated.');
  }

  Future<bool> removeCertification(String certificationId) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.removeCertification(
      coachId: current.profile.coachId,
      certificationId: certificationId,
    );
    return _applyMutationResult(result, 'Certification removed.');
  }

  Future<bool> addSpecialization(String specialization) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;
    final trimmed = specialization.trim();
    if (trimmed.isEmpty) {
      emit(
        current.copyWith(
          feedbackMessage: 'Specialization cannot be empty.',
          isErrorFeedback: true,
        ),
      );
      return false;
    }

    if (current.profile.specializations
        .any((s) => s.toLowerCase() == trimmed.toLowerCase())) {
      emit(
        current.copyWith(
          feedbackMessage: 'This specialization is already listed.',
          isErrorFeedback: true,
        ),
      );
      return false;
    }

    final result = await repository.updateSpecializations(
      coachId: current.profile.coachId,
      specializations: [...current.profile.specializations, trimmed],
    );
    return _applyMutationResult(result, 'Specialization added.');
  }

  Future<bool> removeSpecialization(String specialization) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final updated = current.profile.specializations
        .where((s) => s != specialization)
        .toList();
    final result = await repository.updateSpecializations(
      coachId: current.profile.coachId,
      specializations: updated,
    );
    return _applyMutationResult(result, 'Specialization removed.');
  }

  Future<bool> addService(CoachServiceOffering service) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.addService(
      coachId: current.profile.coachId,
      service: service,
    );
    return _applyMutationResult(result, 'Coaching service added.');
  }

  Future<bool> updateService(CoachServiceOffering service) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.updateService(
      coachId: current.profile.coachId,
      service: service,
    );
    return _applyMutationResult(result, 'Coaching service updated.');
  }

  Future<bool> removeService(String serviceId) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.removeService(
      coachId: current.profile.coachId,
      serviceId: serviceId,
    );
    return _applyMutationResult(result, 'Coaching service removed.');
  }

  Future<bool> updateFees({
    required double defaultHourlyFee,
    required String feeNotes,
  }) async {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    final result = await repository.updateFees(
      coachId: current.profile.coachId,
      defaultHourlyFee: defaultHourlyFee,
      feeNotes: feeNotes,
    );
    return _applyMutationResult(result, 'Personal coaching fees updated.');
  }

  bool _applyMutationResult(
    Result<CoachProfile> result,
    String successMessage,
  ) {
    final current = state;
    if (current is! CoachProfileLoaded) return false;

    switch (result) {
      case Success(:final data):
        emit(
          CoachProfileLoaded(
            profile: data,
            feedbackMessage: successMessage,
            isErrorFeedback: false,
          ),
        );
        return true;
      case FailureResult(:final failure):
        emit(
          current.copyWith(
            feedbackMessage: failure.message,
            isErrorFeedback: true,
          ),
        );
        return false;
    }
  }
}
