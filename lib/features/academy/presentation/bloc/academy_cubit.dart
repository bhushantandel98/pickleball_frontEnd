import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/domain/repositories/academy_repository.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_state.dart';

/// Cubit managing Academy operations across Dashboard, Branches, Programs/Batches,
/// Coach Affiliations, and Student Enrollments/Tuition.
class AcademyCubit extends Cubit<AcademyState> {
  final AcademyRepository repository;

  AcademyCubit({
    required this.repository,
  }) : super(const AcademyInitial());

  Future<void> loadWorkspace({String academyId = 'acad_001'}) async {
    emit(const AcademyLoading());
    final result = await repository.getWorkspaceData(academyId: academyId);
    switch (result) {
      case Success(:final data):
        emit(AcademyLoaded(data: data));
      case FailureResult(:final failure):
        emit(AcademyFailure(failure));
    }
  }

  Future<void> refreshWorkspace({String? academyId}) async {
    final current = state;
    final id = academyId ??
        (current is AcademyLoaded ? current.data.profile.academyId : 'acad_001');
    final result = await repository.getWorkspaceData(academyId: id);
    switch (result) {
      case Success(:final data):
        if (current is AcademyLoaded) {
          emit(current.copyWith(data: data, clearFeedback: true));
        } else {
          emit(AcademyLoaded(data: data));
        }
      case FailureResult(:final failure):
        emit(AcademyFailure(failure));
    }
  }

  void selectBranch(String? branchId) {
    final current = state;
    if (current is! AcademyLoaded) return;
    emit(
      current.copyWith(
        selectedBranchId: branchId,
        clearBranchFilter: branchId == null,
        clearFeedback: true,
      ),
    );
  }

  void setEnrollmentFilter(EnrollmentRequestStatus? status) {
    final current = state;
    if (current is! AcademyLoaded) return;
    emit(
      current.copyWith(
        enrollmentFilter: status,
        clearEnrollmentFilter: status == null,
        clearFeedback: true,
      ),
    );
  }

  void clearFeedback() {
    final current = state;
    if (current is AcademyLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<bool> createBranch({
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int courtCount,
    required String contactPhone,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.createBranch(
      academyId: current.data.profile.academyId,
      name: name,
      city: city,
      address: address,
      operatingHours: operatingHours,
      courtCount: courtCount,
      contactPhone: contactPhone,
    );
    return _apply(res, 'Branch created.');
  }

  Future<bool> updateBranch({
    required String branchId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int courtCount,
    required String contactPhone,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.updateBranch(
      academyId: current.data.profile.academyId,
      branchId: branchId,
      name: name,
      city: city,
      address: address,
      operatingHours: operatingHours,
      courtCount: courtCount,
      contactPhone: contactPhone,
    );
    return _apply(res, 'Branch updated.');
  }

  Future<bool> toggleBranchStatus(String branchId, bool isActive) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.toggleBranchStatus(
      academyId: current.data.profile.academyId,
      branchId: branchId,
      isActive: isActive,
    );
    return _apply(
      res,
      isActive ? 'Branch activated.' : 'Branch paused.',
    );
  }

  Future<bool> createProgram({
    required String branchId,
    required String title,
    required String skillLevel,
    required String ageGroup,
    required String description,
    required double monthlyTuitionInr,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.createProgram(
      academyId: current.data.profile.academyId,
      branchId: branchId,
      title: title,
      skillLevel: skillLevel,
      ageGroup: ageGroup,
      description: description,
      monthlyTuitionInr: monthlyTuitionInr,
    );
    return _apply(res, 'Program created.');
  }

  Future<bool> toggleProgramStatus(String programId, bool isActive) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.toggleProgramStatus(
      academyId: current.data.profile.academyId,
      programId: programId,
      isActive: isActive,
    );
    return _apply(
      res,
      isActive ? 'Program activated.' : 'Program paused.',
    );
  }

  Future<bool> createBatch({
    required String programId,
    required String name,
    required String scheduleLabel,
    required int capacity,
    String? assignedCoachId,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.createBatch(
      academyId: current.data.profile.academyId,
      programId: programId,
      name: name,
      scheduleLabel: scheduleLabel,
      capacity: capacity,
      assignedCoachId: assignedCoachId,
    );
    return _apply(res, 'Batch created.');
  }

  Future<bool> inviteCoach({
    required String coachName,
    required String coachContact,
    required String specialization,
    required List<String> branchIds,
    required bool canModifyOfficialSchedule,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.inviteCoach(
      academyId: current.data.profile.academyId,
      coachName: coachName,
      coachContact: coachContact,
      specialization: specialization,
      branchIds: branchIds,
      canModifyOfficialSchedule: canModifyOfficialSchedule,
    );
    return _apply(
      res,
      'Coach invitation sent (Pending Coach Acceptance).',
    );
  }

  Future<bool> updateCoachAssignment({
    required String affiliationId,
    required List<String> branchIds,
    required bool canModifyOfficialSchedule,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.updateCoachAssignment(
      academyId: current.data.profile.academyId,
      affiliationId: affiliationId,
      branchIds: branchIds,
      canModifyOfficialSchedule: canModifyOfficialSchedule,
    );
    return _apply(res, 'Coach branch assignment updated.');
  }

  Future<bool> revokeCoachAffiliation(String affiliationId) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.revokeCoachAffiliation(
      academyId: current.data.profile.academyId,
      affiliationId: affiliationId,
    );
    return _apply(res, 'Coach affiliation revoked.');
  }

  Future<bool> updateEnrollmentStatus({
    required String enrollmentId,
    required EnrollmentRequestStatus newStatus,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.updateEnrollmentStatus(
      academyId: current.data.profile.academyId,
      enrollmentId: enrollmentId,
      newStatus: newStatus,
    );
    return _apply(res, 'Enrollment status updated to ${newStatus.label}.');
  }

  Future<bool> recordTuitionPayment({
    required String enrollmentId,
    required TuitionFeeStatus feeStatus,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final res = await repository.recordTuitionPayment(
      academyId: current.data.profile.academyId,
      enrollmentId: enrollmentId,
      feeStatus: feeStatus,
    );
    return _apply(res, 'Tuition status updated to ${feeStatus.label}.');
  }

  bool _apply(Result<AcademyWorkspaceData> result, String successMessage) {
    final current = state;
    if (current is! AcademyLoaded) return false;

    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            data: data,
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
