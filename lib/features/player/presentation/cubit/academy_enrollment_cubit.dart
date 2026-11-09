import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_enrollment_state.dart';

class AcademyEnrollmentCubit extends Cubit<AcademyEnrollmentState> {
  final CoachingAcademyRepository _repository;

  AcademyEnrollmentCubit(this._repository) : super(const AcademyEnrollmentInitial());

  Future<void> init({
    required String branchId,
    required String programId,
    required String batchId,
  }) async {
    final branchResult = await _repository.getAcademyBranchById(branchId);
    if (branchResult is! Success<AcademyBranch>) {
      emit(const AcademyEnrollmentFailure('Academy branch details could not be loaded.'));
      return;
    }

    final branch = branchResult.data;
    final program = branch.programs.where((p) => p.id == programId).firstOrNull;
    if (program == null) {
      emit(const AcademyEnrollmentFailure('Selected academy program was not found.'));
      return;
    }

    final batch = program.batches.where((b) => b.id == batchId).firstOrNull;
    if (batch == null) {
      emit(const AcademyEnrollmentFailure('Selected batch was not found.'));
      return;
    }

    emit(AcademyEnrollmentReady(
      branch: branch,
      program: program,
      batch: batch,
    ));
  }

  Future<bool> submitEnrollment({
    required String playerName,
    required String playerPhone,
    String playerEmail = '',
    double? playerRating,
    required String emergencyContactName,
    required String emergencyContactPhone,
    String? notes,
  }) async {
    final current = state;
    if (current is! AcademyEnrollmentReady) return false;

    if (playerName.trim().isEmpty) {
      emit(current.copyWith(errorMessage: 'Please enter your full name.'));
      return false;
    }
    if (playerPhone.trim().isEmpty || playerPhone.trim().length < 8) {
      emit(current.copyWith(errorMessage: 'Please enter a valid phone number.'));
      return false;
    }
    if (emergencyContactName.trim().isEmpty) {
      emit(current.copyWith(errorMessage: 'Please enter an emergency contact name.'));
      return false;
    }
    if (emergencyContactPhone.trim().isEmpty || emergencyContactPhone.trim().length < 8) {
      emit(current.copyWith(errorMessage: 'Please enter an emergency contact phone number.'));
      return false;
    }

    // Business rule: waitlist only when batch is full and waitlist is enabled
    final isBatchFull = current.batch.isFull;
    if (isBatchFull && !current.batch.isWaitlistEnabled) {
      emit(current.copyWith(
        errorMessage: 'This batch has reached capacity and enrollment is closed.',
      ));
      return false;
    }

    emit(current.copyWith(isSubmitting: true, errorMessage: null));

    final result = await _repository.submitEnrollmentRequest(
      branchId: current.branch.id,
      programId: current.program.id,
      batchId: current.batch.id,
      playerName: playerName.trim(),
      playerPhone: playerPhone.trim(),
      playerEmail: playerEmail.trim(),
      playerRating: playerRating,
      emergencyContactName: emergencyContactName.trim(),
      emergencyContactPhone: emergencyContactPhone.trim(),
      notes: notes,
      isWaitlist: isBatchFull,
    );

    switch (result) {
      case Success(:final data):
        emit(AcademyEnrollmentSuccess(data));
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
