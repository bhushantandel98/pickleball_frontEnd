import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';
import 'package:pickleball_platform/features/academy_staff/domain/repositories/academy_staff_repository.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/cubit/academy_staff_state.dart';

/// Cubit managing delegated Academy Staff operations across Dashboard,
/// Attendance, Batches, Enrollments, Tuition, and Coach/Student rosters.
class AcademyStaffCubit extends Cubit<AcademyStaffState> {
  final AcademyStaffRepository repository;

  AcademyStaffCubit({
    required this.repository,
  }) : super(const AcademyStaffInitial());

  Future<void> loadWorkspace({
    String academyId = 'acad_001',
    String staffId = 'user_acad_staff_001',
  }) async {
    emit(const AcademyStaffLoading());
    final result = await repository.getWorkspaceData(
      academyId: academyId,
      staffId: staffId,
    );
    switch (result) {
      case Success(:final data):
        emit(AcademyStaffLoaded(data: data));
      case FailureResult(:final failure):
        emit(AcademyStaffFailure(failure));
    }
  }

  Future<void> refreshWorkspace({
    String? academyId,
    String? staffId,
  }) async {
    final current = state;
    final resolvedAcademyId = academyId ??
        (current is AcademyStaffLoaded
            ? current.staffProfile.academyId
            : 'acad_001');
    final resolvedStaffId = staffId ??
        (current is AcademyStaffLoaded
            ? current.staffProfile.staffId
            : 'user_acad_staff_001');

    final result = await repository.getWorkspaceData(
      academyId: resolvedAcademyId,
      staffId: resolvedStaffId,
    );
    switch (result) {
      case Success(:final data):
        if (current is AcademyStaffLoaded) {
          emit(current.copyWith(data: data, clearFeedback: true));
        } else {
          emit(AcademyStaffLoaded(data: data));
        }
      case FailureResult(:final failure):
        emit(AcademyStaffFailure(failure));
    }
  }

  void selectBranch(String? branchId) {
    final current = state;
    if (current is! AcademyStaffLoaded) return;
    emit(
      current.copyWith(
        selectedBranchId: branchId,
        clearBranchFilter: branchId == null,
        clearBatchFilter: true,
        clearFeedback: true,
      ),
    );
  }

  void selectBatch(String? batchId) {
    final current = state;
    if (current is! AcademyStaffLoaded) return;
    emit(
      current.copyWith(
        selectedBatchId: batchId,
        clearBatchFilter: batchId == null,
        clearFeedback: true,
      ),
    );
  }

  void setEnrollmentFilter(EnrollmentRequestStatus? status) {
    final current = state;
    if (current is! AcademyStaffLoaded) return;
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
    if (current is AcademyStaffLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<bool> markAttendance({
    required String attendanceId,
    required StaffAttendanceStatus status,
    String? notes,
  }) async {
    final current = state;
    if (current is! AcademyStaffLoaded) return false;
    final res = await repository.markAttendance(
      academyId: current.staffProfile.academyId,
      staffId: current.staffProfile.staffId,
      attendanceId: attendanceId,
      status: status,
      notes: notes,
    );
    return _apply(res, 'Attendance updated to ${status.label}.');
  }

  Future<bool> updateBatchSchedule({
    required String batchId,
    required String scheduleLabel,
  }) async {
    final current = state;
    if (current is! AcademyStaffLoaded) return false;
    final res = await repository.updateBatchScheduleLabel(
      academyId: current.staffProfile.academyId,
      staffId: current.staffProfile.staffId,
      batchId: batchId,
      scheduleLabel: scheduleLabel,
    );
    return _apply(res, 'Batch schedule updated.');
  }

  Future<bool> updateEnrollmentStatus({
    required String enrollmentId,
    required EnrollmentRequestStatus newStatus,
  }) async {
    final current = state;
    if (current is! AcademyStaffLoaded) return false;
    final res = await repository.updateEnrollmentStatus(
      academyId: current.staffProfile.academyId,
      staffId: current.staffProfile.staffId,
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
    if (current is! AcademyStaffLoaded) return false;
    final res = await repository.recordTuitionPayment(
      academyId: current.staffProfile.academyId,
      staffId: current.staffProfile.staffId,
      enrollmentId: enrollmentId,
      feeStatus: feeStatus,
    );
    return _apply(res, 'Tuition fee status updated to ${feeStatus.label}.');
  }

  bool _apply(Result<AcademyStaffWorkspaceData> res, String successMsg) {
    final current = state;
    if (current is! AcademyStaffLoaded) return false;

    switch (res) {
      case Success(:final data):
        emit(
          current.copyWith(
            data: data,
            feedbackMessage: successMsg,
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
