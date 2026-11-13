import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

/// State hierarchy for the Academy Staff module (Phase 3 — Feature 3.6).
sealed class AcademyStaffState extends Equatable {
  const AcademyStaffState();

  @override
  List<Object?> get props => [];
}

class AcademyStaffInitial extends AcademyStaffState {
  const AcademyStaffInitial();
}

class AcademyStaffLoading extends AcademyStaffState {
  const AcademyStaffLoading();
}

class AcademyStaffLoaded extends AcademyStaffState {
  final AcademyStaffWorkspaceData data;
  final String? selectedBranchId;
  final String? selectedBatchId;
  final EnrollmentRequestStatus? enrollmentFilter;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const AcademyStaffLoaded({
    required this.data,
    this.selectedBranchId,
    this.selectedBatchId,
    this.enrollmentFilter,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  AcademyStaffProfile get staffProfile => data.staffProfile;

  bool hasPermission(AcademyStaffPermission permission) =>
      data.staffProfile.hasPermission(permission);

  List<AcademyBatch> get scopedBatches {
    if (selectedBranchId == null) return data.batches;
    return data.batches.where((b) => b.branchId == selectedBranchId).toList();
  }

  List<StaffBatchScheduleItem> get scopedTodaySessions {
    if (selectedBranchId == null) return data.todaySessions;
    return data.todaySessions
        .where((s) => s.branchId == selectedBranchId)
        .toList();
  }

  List<StaffSessionAttendance> get scopedAttendance {
    return data.attendanceRecords.where((a) {
      if (selectedBranchId != null && a.branchId != selectedBranchId) {
        return false;
      }
      if (selectedBatchId != null && a.batchId != selectedBatchId) {
        return false;
      }
      return true;
    }).toList();
  }

  List<AcademyEnrollmentRecord> get scopedEnrollments {
    return data.enrollments.where((e) {
      if (selectedBranchId != null && e.branchId != selectedBranchId) {
        return false;
      }
      if (enrollmentFilter != null && e.status != enrollmentFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  List<AcademyCoachAffiliation> get scopedCoaches {
    if (selectedBranchId == null) return data.coaches;
    return data.coaches
        .where((c) => c.assignedBranchIds.contains(selectedBranchId))
        .toList();
  }

  int get pendingEnrollmentCount => data.enrollments
      .where((e) =>
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          (e.status == EnrollmentRequestStatus.pending ||
              e.status == EnrollmentRequestStatus.waitlisted))
      .length;

  int get overdueTuitionCount => data.enrollments
      .where((e) =>
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          e.status == EnrollmentRequestStatus.approved &&
          e.feeStatus == TuitionFeeStatus.overdue)
      .length;

  int get presentTodayCount => scopedAttendance
      .where((a) => a.status == StaffAttendanceStatus.present)
      .length;

  AcademyStaffLoaded copyWith({
    AcademyStaffWorkspaceData? data,
    String? selectedBranchId,
    bool clearBranchFilter = false,
    String? selectedBatchId,
    bool clearBatchFilter = false,
    EnrollmentRequestStatus? enrollmentFilter,
    bool clearEnrollmentFilter = false,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? isErrorFeedback,
  }) {
    return AcademyStaffLoaded(
      data: data ?? this.data,
      selectedBranchId: clearBranchFilter
          ? null
          : (selectedBranchId ?? this.selectedBranchId),
      selectedBatchId:
          clearBatchFilter ? null : (selectedBatchId ?? this.selectedBatchId),
      enrollmentFilter: clearEnrollmentFilter
          ? null
          : (enrollmentFilter ?? this.enrollmentFilter),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isErrorFeedback:
          clearFeedback ? false : (isErrorFeedback ?? this.isErrorFeedback),
    );
  }

  @override
  List<Object?> get props => [
        data,
        selectedBranchId,
        selectedBatchId,
        enrollmentFilter,
        feedbackMessage,
        isErrorFeedback,
      ];
}

class AcademyStaffFailure extends AcademyStaffState {
  final Failure failure;

  const AcademyStaffFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
