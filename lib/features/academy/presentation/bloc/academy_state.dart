import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';

/// Base state hierarchy for the Academy Role module.
sealed class AcademyState extends Equatable {
  const AcademyState();

  @override
  List<Object?> get props => [];
}

class AcademyInitial extends AcademyState {
  const AcademyInitial();
}

class AcademyLoading extends AcademyState {
  const AcademyLoading();
}

class AcademyLoaded extends AcademyState {
  final AcademyWorkspaceData data;
  final String? selectedBranchId;
  final EnrollmentRequestStatus? enrollmentFilter;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const AcademyLoaded({
    required this.data,
    this.selectedBranchId,
    this.enrollmentFilter,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  List<AcademyProgram> get scopedPrograms {
    if (selectedBranchId == null) return data.programs;
    return data.programs.where((p) => p.branchId == selectedBranchId).toList();
  }

  List<AcademyBatch> get scopedBatches {
    if (selectedBranchId == null) return data.batches;
    return data.batches.where((b) => b.branchId == selectedBranchId).toList();
  }

  List<AcademyCoachAffiliation> get scopedAffiliations {
    if (selectedBranchId == null) return data.coachAffiliations;
    return data.coachAffiliations
        .where((c) => c.assignedBranchIds.contains(selectedBranchId))
        .toList();
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

  int get activeBranchCount => data.branches.where((b) => b.isActive).length;

  int get acceptedCoachCount => scopedAffiliations
      .where((c) => c.status == CoachAffiliationStatus.accepted)
      .length;

  int get pendingCoachInviteCount => scopedAffiliations
      .where((c) => c.status == CoachAffiliationStatus.pendingAcceptance)
      .length;

  int get activeStudentCount => data.enrollments
      .where((e) =>
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          e.status == EnrollmentRequestStatus.approved)
      .length;

  int get pendingEnrollmentCount => data.enrollments
      .where((e) =>
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          (e.status == EnrollmentRequestStatus.pending ||
              e.status == EnrollmentRequestStatus.waitlisted))
      .length;

  double get collectedTuitionInr => data.enrollments
      .where((e) =>
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          e.status == EnrollmentRequestStatus.approved &&
          e.feeStatus == TuitionFeeStatus.paid)
      .fold<double>(0, (sum, e) => sum + e.tuitionAmountInr);

  double get pendingTuitionInr => data.enrollments
      .where((e) =>
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          e.status == EnrollmentRequestStatus.approved &&
          e.feeStatus != TuitionFeeStatus.paid)
      .fold<double>(0, (sum, e) => sum + e.tuitionAmountInr);

  AcademyLoaded copyWith({
    AcademyWorkspaceData? data,
    String? selectedBranchId,
    bool clearBranchFilter = false,
    EnrollmentRequestStatus? enrollmentFilter,
    bool clearEnrollmentFilter = false,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? isErrorFeedback,
  }) {
    return AcademyLoaded(
      data: data ?? this.data,
      selectedBranchId: clearBranchFilter
          ? null
          : (selectedBranchId ?? this.selectedBranchId),
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
        enrollmentFilter,
        feedbackMessage,
        isErrorFeedback,
      ];
}

class AcademyFailure extends AcademyState {
  final Failure failure;

  const AcademyFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
