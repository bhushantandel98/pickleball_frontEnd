import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

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
  final bool isAdmin;
  final List<String>? authorizedBranchIds;
  final Set<AcademyStaffPermission> staffPermissions;
  final String? selectedBranchId;
  final EnrollmentRequestStatus? enrollmentFilter;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const AcademyLoaded({
    required this.data,
    this.isAdmin = true,
    this.authorizedBranchIds,
    this.staffPermissions = const {},
    this.selectedBranchId,
    this.enrollmentFilter,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  bool hasPermission(AcademyStaffPermission permission) =>
      isAdmin || staffPermissions.contains(permission);

  bool get canManageBranches => isAdmin;
  bool get canManageStaff => isAdmin;
  bool get canManageCoaches => isAdmin;
  bool get canManageBatches =>
      isAdmin || hasPermission(AcademyStaffPermission.manageBatches);
  bool get canViewStudents =>
      isAdmin || hasPermission(AcademyStaffPermission.viewStudents);
  bool get canManageEnrollments =>
      isAdmin || hasPermission(AcademyStaffPermission.manageEnrollments);
  bool get canRecordTuition =>
      isAdmin || hasPermission(AcademyStaffPermission.recordTuition);

  bool canAccessBranch(String branchId) =>
      isAdmin || (authorizedBranchIds?.contains(branchId) ?? false);

  List<AcademyBranch> get scopedBranches =>
      data.branches.where((b) => canAccessBranch(b.id)).toList();

  List<AcademyBatch> get scopedBatches {
    return data.batches.where((b) {
      if (!canAccessBranch(b.branchId)) return false;
      if (selectedBranchId != null && b.branchId != selectedBranchId) {
        return false;
      }
      return true;
    }).toList();
  }

  List<AcademyCoachAffiliation> get scopedAffiliations {
    return data.coachAffiliations.where((c) {
      final hasBranchAccess =
          isAdmin || c.assignedBranchIds.any((id) => canAccessBranch(id));
      if (!hasBranchAccess) return false;
      if (selectedBranchId != null &&
          !c.assignedBranchIds.contains(selectedBranchId)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<AcademyStudent> get scopedStudents {
    return data.students.where((s) {
      if (!canAccessBranch(s.branchId)) return false;
      if (selectedBranchId != null && s.branchId != selectedBranchId) {
        return false;
      }
      return true;
    }).toList();
  }

  List<AcademyEnrollmentRecord> get scopedEnrollments {
    return data.enrollments.where((e) {
      if (!canAccessBranch(e.branchId)) return false;
      if (selectedBranchId != null && e.branchId != selectedBranchId) {
        return false;
      }
      if (enrollmentFilter != null && e.status != enrollmentFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  int get activeBranchCount => scopedBranches.where((b) => b.isActive).length;

  int get acceptedCoachCount => scopedAffiliations
      .where((c) => c.status == CoachAffiliationStatus.accepted)
      .length;

  int get pendingCoachInviteCount => scopedAffiliations
      .where((c) => c.status == CoachAffiliationStatus.pendingAcceptance)
      .length;

  int get activeStudentCount => data.enrollments
      .where((e) =>
          canAccessBranch(e.branchId) &&
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          e.status == EnrollmentRequestStatus.approved)
      .length;

  int get pendingEnrollmentCount => data.enrollments
      .where((e) =>
          canAccessBranch(e.branchId) &&
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          (e.status == EnrollmentRequestStatus.pending ||
              e.status == EnrollmentRequestStatus.waitlisted))
      .length;

  double get collectedTuitionInr => data.enrollments
      .where((e) =>
          canAccessBranch(e.branchId) &&
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          e.status == EnrollmentRequestStatus.approved &&
          e.feeStatus == TuitionFeeStatus.paid)
      .fold<double>(0, (sum, e) => sum + e.tuitionAmountInr);

  double get pendingTuitionInr => data.enrollments
      .where((e) =>
          canAccessBranch(e.branchId) &&
          (selectedBranchId == null || e.branchId == selectedBranchId) &&
          e.status == EnrollmentRequestStatus.approved &&
          e.feeStatus != TuitionFeeStatus.paid)
      .fold<double>(0, (sum, e) => sum + e.tuitionAmountInr);

  AcademyLoaded copyWith({
    AcademyWorkspaceData? data,
    bool? isAdmin,
    List<String>? authorizedBranchIds,
    Set<AcademyStaffPermission>? staffPermissions,
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
      isAdmin: isAdmin ?? this.isAdmin,
      authorizedBranchIds: authorizedBranchIds ?? this.authorizedBranchIds,
      staffPermissions: staffPermissions ?? this.staffPermissions,
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
        isAdmin,
        authorizedBranchIds,
        staffPermissions,
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
