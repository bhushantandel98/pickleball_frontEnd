import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/domain/repositories/academy_repository.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_state.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

/// Cubit managing shared Academy Admin & Staff operations across Dashboard,
/// Branches & Batches, Coaches, Students, Enrollments, and Staff Management.
class AcademyCubit extends Cubit<AcademyState> {
  final AcademyRepository repository;

  AcademyCubit({
    required this.repository,
  }) : super(const AcademyInitial());

  Future<void> loadWorkspace({
    String academyId = 'acad_001',
    bool isAdmin = true,
    String? staffUserId,
  }) async {
    emit(const AcademyLoading());
    final result = await repository.getWorkspaceData(academyId: academyId);
    switch (result) {
      case Success(:final data):
        if (isAdmin) {
          emit(AcademyLoaded(data: data, isAdmin: true));
        } else {
          final staffMember = data.staffMembers
                  .where((m) =>
                      m.isActive &&
                      (m.userId == staffUserId || m.staffId == staffUserId))
                  .firstOrNull ??
              data.staffMembers.where((m) => m.isActive).firstOrNull;
          emit(
            AcademyLoaded(
              data: data,
              isAdmin: false,
              authorizedBranchIds: staffMember?.assignedBranchIds ?? const [],
              staffPermissions: staffMember?.permissions ?? const {},
              selectedBranchId: staffMember?.assignedBranchIds.firstOrNull,
            ),
          );
        }
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
    String contactPerson = '',
    String city = '',
    required String address,
    String operatingHours = '',
    int courtCount = 0,
    String contactPhone = '',
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    if (!current.canManageBranches) {
      return _deny('Only Academy Admin can create branches.');
    }
    final res = await repository.createBranch(
      academyId: current.data.profile.academyId,
      name: name,
      contactPerson: contactPerson,
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
    String contactPerson = '',
    String city = '',
    required String address,
    String operatingHours = '',
    int courtCount = 0,
    String contactPhone = '',
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    if (!current.canManageBranches) {
      return _deny('Only Academy Admin can edit branches.');
    }
    final res = await repository.updateBranch(
      academyId: current.data.profile.academyId,
      branchId: branchId,
      name: name,
      contactPerson: contactPerson,
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
    String programId = '',
    required String branchId,
    required String name,
    required BatchSkillLevel skillLevel,
    required List<String> daysOfWeek,
    required String startTime,
    required String endTime,
    required int capacity,
    String? assignedCoachId,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    if (!current.canManageBatches || !current.canAccessBranch(branchId)) {
      return _deny('You do not have permission to add batches to this branch.');
    }
    final res = await repository.createBatch(
      academyId: current.data.profile.academyId,
      programId: programId,
      branchId: branchId,
      name: name,
      skillLevel: skillLevel,
      daysOfWeek: daysOfWeek,
      startTime: startTime,
      endTime: endTime,
      capacity: capacity,
      assignedCoachId: assignedCoachId,
    );
    return _apply(res, 'Batch created.');
  }

  Future<bool> updateBatch({
    required String batchId,
    required String branchId,
    required String name,
    required BatchSkillLevel skillLevel,
    required List<String> daysOfWeek,
    required String startTime,
    required String endTime,
    required int capacity,
    String? assignedCoachId,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    if (!current.canManageBatches || !current.canAccessBranch(branchId)) {
      return _deny('You do not have permission to edit batches in this branch.');
    }
    final res = await repository.updateBatch(
      academyId: current.data.profile.academyId,
      batchId: batchId,
      branchId: branchId,
      name: name,
      skillLevel: skillLevel,
      daysOfWeek: daysOfWeek,
      startTime: startTime,
      endTime: endTime,
      capacity: capacity,
      assignedCoachId: assignedCoachId,
    );
    return _apply(res, 'Batch updated.');
  }

  Future<bool> assignCoachToBatch({
    required String batchId,
    required String branchId,
    String? coachId,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    if (!current.canManageBatches || !current.canAccessBranch(branchId)) {
      return _deny('You do not have permission to assign coaches in this branch.');
    }
    final res = await repository.assignCoachToBatch(
      academyId: current.data.profile.academyId,
      batchId: batchId,
      coachId: coachId,
    );
    return _apply(res, 'Coach assignment updated.');
  }

  Future<bool> sendCoachConnectionRequest({
    required String coachId,
    required List<String> branchIds,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    if (!current.canManageCoaches) {
      return _deny('Only Academy Admin can send coach connection requests.');
    }
    final res = await repository.sendCoachConnectionRequest(
      academyId: current.data.profile.academyId,
      coachId: coachId,
      branchIds: branchIds,
    );
    return _apply(res, 'Connection request sent to coach.');
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

  Future<bool> addStaffMember({
    required String name,
    required String email,
    required String phone,
    required String roleTitle,
    required List<String> assignedBranchIds,
    required Set<AcademyStaffPermission> permissions,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    if (!current.canManageStaff) {
      return _deny('Only Academy Admin can manage staff.');
    }
    final res = await repository.addStaffMember(
      academyId: current.data.profile.academyId,
      name: name,
      email: email,
      phone: phone,
      roleTitle: roleTitle,
      assignedBranchIds: assignedBranchIds,
      permissions: permissions,
    );
    return _apply(res, 'Staff member added.');
  }

  Future<bool> updateStaffMember({
    required String staffId,
    required String roleTitle,
    required List<String> assignedBranchIds,
    required Set<AcademyStaffPermission> permissions,
    required bool isActive,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    if (!current.canManageStaff) {
      return _deny('Only Academy Admin can update staff.');
    }
    final res = await repository.updateStaffMember(
      academyId: current.data.profile.academyId,
      staffId: staffId,
      roleTitle: roleTitle,
      assignedBranchIds: assignedBranchIds,
      permissions: permissions,
      isActive: isActive,
    );
    return _apply(res, 'Staff member updated.');
  }

  Future<bool> recordStudentAssessment({
    required String studentId,
    required String coachId,
    required String coachName,
    required String focusArea,
    required Map<String, int> aspectRatings,
    required String feedback,
  }) async {
    final current = state;
    if (current is! AcademyLoaded) return false;
    final student = current.data.students
        .where((s) => s.id == studentId)
        .firstOrNull;
    if (student == null ||
        !current.canRecordAssessment ||
        !current.canAccessBranch(student.branchId)) {
      return _deny('You do not have permission to record assessments for this student.');
    }
    final res = await repository.recordStudentAssessment(
      academyId: current.data.profile.academyId,
      studentId: studentId,
      coachId: coachId,
      coachName: coachName,
      focusArea: focusArea,
      aspectRatings: aspectRatings,
      feedback: feedback,
    );
    return _apply(res, 'Performance assessment recorded.');
  }

  bool _deny(String message) {
    final current = state;
    if (current is AcademyLoaded) {
      emit(current.copyWith(feedbackMessage: message, isErrorFeedback: true));
    }
    return false;
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
