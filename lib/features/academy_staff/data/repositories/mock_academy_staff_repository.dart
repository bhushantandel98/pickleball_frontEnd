import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';
import 'package:pickleball_platform/features/academy_staff/domain/repositories/academy_staff_repository.dart';

/// Mock implementation of [AcademyStaffRepository] for Phase 3 — Feature 3.6.
///
/// Enforces:
/// - Academy ownership (`academyId` must match the staff member's academy).
/// - Branch-level scoping (`assignedBranchIds` only; e.g. `branch_andheri` is
///   accessible to Rachel Zane while `branch_bandra` is excluded).
/// - Delegated permission checks at the repository boundary.
/// - Strict separation from Coach personal coaching records and Academy owner-only
///   operations (no branch CRUD, no coach invitations/revocations, no self-escalation).
class MockAcademyStaffRepository implements AcademyStaffRepository {
  bool shouldFail;

  late AcademyStaffProfile _staffProfile;
  late List<AcademyBranch> _allAcademyBranches;
  late List<AcademyProgram> _allAcademyPrograms;
  late List<AcademyBatch> _allAcademyBatches;
  late List<AcademyCoachAffiliation> _allAcademyCoaches;
  late List<AcademyEnrollmentRecord> _allAcademyEnrollments;
  late List<StaffSessionAttendance> _attendanceRecords;

  MockAcademyStaffRepository({
    this.shouldFail = false,
    AcademyStaffProfile? customStaffProfile,
  }) {
    _seedData(customStaffProfile: customStaffProfile);
  }

  void _seedData({AcademyStaffProfile? customStaffProfile}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _staffProfile = customStaffProfile ??
        const AcademyStaffProfile(
          staffId: 'user_acad_staff_001',
          academyId: 'acad_001',
          academyName: 'Pinnacle Sports Academy',
          staffName: 'Rachel Zane',
          staffEmail: 'rachel.zane@pinnaclesports.com',
          roleTitle: 'Branch Operations Coordinator',
          assignedBranchIds: ['branch_andheri'],
          assignedBranchNames: ['Andheri West Branch'],
          permissions: {
            AcademyStaffPermission.viewDashboard,
            AcademyStaffPermission.manageAttendance,
            AcademyStaffPermission.manageBatches,
            AcademyStaffPermission.manageEnrollments,
            AcademyStaffPermission.viewStudents,
            AcademyStaffPermission.viewCoaches,
            AcademyStaffPermission.recordTuition,
          },
          isActive: true,
        );

    _allAcademyBranches = const [
      AcademyBranch(
        id: 'branch_andheri',
        academyId: 'acad_001',
        name: 'Andheri West Branch',
        city: 'Mumbai',
        address: 'Plot 18, Veera Desai Road, Andheri West',
        operatingHours: '06:00 AM – 10:00 PM',
        courtCount: 6,
        contactPhone: '+91 98200 11223',
        isActive: true,
      ),
      // Unassigned branch for this staff member — must never be exposed or mutated.
      AcademyBranch(
        id: 'branch_bandra',
        academyId: 'acad_001',
        name: 'Bandra Kurla Complex',
        city: 'Mumbai',
        address: 'G-Block, BKC Sports Complex, Bandra East',
        operatingHours: '06:30 AM – 09:30 PM',
        courtCount: 4,
        contactPhone: '+91 98200 44556',
        isActive: true,
      ),
    ];

    _allAcademyPrograms = const [
      AcademyProgram(
        id: 'prog_001',
        academyId: 'acad_001',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        title: 'Intermediate Doubles Mastery',
        skillLevel: 'Intermediate (3.5+)',
        ageGroup: '16+ Adults',
        description:
            'Tactical third-shot drops, transition footwork, and doubles stacking.',
        monthlyTuitionInr: 4500,
        isActive: true,
      ),
      AcademyProgram(
        id: 'prog_002',
        academyId: 'acad_001',
        branchId: 'branch_bandra',
        branchName: 'Bandra Kurla Complex',
        title: 'Junior Foundations Academy',
        skillLevel: 'Beginner (1.0 – 2.5)',
        ageGroup: '8–15 Years',
        description:
            'Core grip mechanics, serve consistency, and kitchen dinking games.',
        monthlyTuitionInr: 3200,
        isActive: true,
      ),
      AcademyProgram(
        id: 'prog_003',
        academyId: 'acad_001',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        title: 'High-Performance DUPR Squad',
        skillLevel: 'Advanced (4.5+)',
        ageGroup: 'Open',
        description:
            'Match-play pressure drills, video review, and tournament prep.',
        monthlyTuitionInr: 6500,
        isActive: true,
      ),
    ];

    _allAcademyBatches = const [
      AcademyBatch(
        id: 'batch_b2',
        academyId: 'acad_001',
        programId: 'prog_001',
        programTitle: 'Intermediate Doubles Mastery',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        name: 'Batch B2 — Evening',
        scheduleLabel: 'Tue / Thu / Sat • 06:00 PM – 07:30 PM',
        capacity: 12,
        enrolledCount: 10,
        assignedCoachId: 'coach_001',
        assignedCoachName: 'Aarav Mehta',
      ),
      AcademyBatch(
        id: 'batch_j1',
        academyId: 'acad_001',
        programId: 'prog_002',
        programTitle: 'Junior Foundations Academy',
        branchId: 'branch_bandra',
        branchName: 'Bandra Kurla Complex',
        name: 'Junior A1 — Morning',
        scheduleLabel: 'Mon / Wed / Fri • 04:30 PM – 05:30 PM',
        capacity: 10,
        enrolledCount: 8,
        assignedCoachId: 'coach_002',
        assignedCoachName: 'Neha Sharma',
      ),
      AcademyBatch(
        id: 'batch_hp1',
        academyId: 'acad_001',
        programId: 'prog_003',
        programTitle: 'High-Performance DUPR Squad',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        name: 'DUPR Elite A1',
        scheduleLabel: 'Mon / Wed / Fri • 07:00 AM – 09:00 AM',
        capacity: 8,
        enrolledCount: 8,
        assignedCoachId: 'coach_001',
        assignedCoachName: 'Aarav Mehta',
      ),
    ];

    _allAcademyCoaches = [
      AcademyCoachAffiliation(
        id: 'aff_001',
        academyId: 'acad_001',
        coachId: 'coach_001',
        coachName: 'Aarav Mehta',
        coachContact: '+91 98201 55667',
        specialization: 'Doubles Strategy & DUPR Prep',
        assignedBranchIds: const ['branch_andheri'],
        assignedBranchNames: const ['Andheri West Branch'],
        canModifyOfficialSchedule: true,
        status: CoachAffiliationStatus.accepted,
        invitedAt: now.subtract(const Duration(days: 60)),
      ),
      AcademyCoachAffiliation(
        id: 'aff_002',
        academyId: 'acad_001',
        coachId: 'coach_002',
        coachName: 'Neha Sharma',
        coachContact: '+91 98202 33445',
        specialization: 'Junior Development & Fundamentals',
        assignedBranchIds: const ['branch_bandra'],
        assignedBranchNames: const ['Bandra Kurla Complex'],
        canModifyOfficialSchedule: false,
        status: CoachAffiliationStatus.accepted,
        invitedAt: now.subtract(const Duration(days: 45)),
      ),
    ];

    _allAcademyEnrollments = [
      AcademyEnrollmentRecord(
        id: 'enr_001',
        academyId: 'acad_001',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        programId: 'prog_001',
        programTitle: 'Intermediate Doubles Mastery',
        batchId: 'batch_b2',
        batchName: 'Batch B2 — Evening',
        studentName: 'Rohan Kapoor',
        studentContact: '+91 98204 12345',
        status: EnrollmentRequestStatus.approved,
        feeStatus: TuitionFeeStatus.paid,
        tuitionAmountInr: 4500,
        requestedAt: now.subtract(const Duration(days: 10)),
      ),
      AcademyEnrollmentRecord(
        id: 'enr_002',
        academyId: 'acad_001',
        branchId: 'branch_bandra',
        branchName: 'Bandra Kurla Complex',
        programId: 'prog_002',
        programTitle: 'Junior Foundations Academy',
        batchId: 'batch_j1',
        batchName: 'Junior A1 — Morning',
        studentName: 'Ananya Verma',
        studentContact: '+91 98205 67890',
        status: EnrollmentRequestStatus.pending,
        feeStatus: TuitionFeeStatus.pending,
        tuitionAmountInr: 3200,
        requestedAt: now.subtract(const Duration(days: 2)),
      ),
      AcademyEnrollmentRecord(
        id: 'enr_003',
        academyId: 'acad_001',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        programId: 'prog_003',
        programTitle: 'High-Performance DUPR Squad',
        batchId: 'batch_hp1',
        batchName: 'DUPR Elite A1',
        studentName: 'Karan Malhotra',
        studentContact: '+91 98207 99881',
        status: EnrollmentRequestStatus.pending,
        feeStatus: TuitionFeeStatus.pending,
        tuitionAmountInr: 6500,
        requestedAt: now.subtract(const Duration(hours: 14)),
      ),
      AcademyEnrollmentRecord(
        id: 'enr_004',
        academyId: 'acad_001',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        programId: 'prog_001',
        programTitle: 'Intermediate Doubles Mastery',
        batchId: 'batch_b2',
        batchName: 'Batch B2 — Evening',
        studentName: 'Sanya Bhatia',
        studentContact: '+91 98198 77665',
        status: EnrollmentRequestStatus.waitlisted,
        waitlistPosition: 1,
        feeStatus: TuitionFeeStatus.pending,
        tuitionAmountInr: 4500,
        requestedAt: now.subtract(const Duration(days: 1)),
      ),
      AcademyEnrollmentRecord(
        id: 'enr_005',
        academyId: 'acad_001',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        programId: 'prog_003',
        programTitle: 'High-Performance DUPR Squad',
        batchId: 'batch_hp1',
        batchName: 'DUPR Elite A1',
        studentName: 'Vikram Joshi',
        studentContact: '+91 98209 44112',
        status: EnrollmentRequestStatus.approved,
        feeStatus: TuitionFeeStatus.overdue,
        tuitionAmountInr: 6500,
        requestedAt: now.subtract(const Duration(days: 18)),
      ),
    ];

    _attendanceRecords = [
      StaffSessionAttendance(
        id: 'att_001',
        academyId: 'acad_001',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        batchId: 'batch_b2',
        batchName: 'Batch B2 — Evening',
        studentId: 'stu_001',
        studentName: 'Rohan Kapoor',
        sessionDate: today,
        status: StaffAttendanceStatus.present,
        notes: 'Checked in on Court 2.',
        markedByStaffId: _staffProfile.staffId,
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      StaffSessionAttendance(
        id: 'att_002',
        academyId: 'acad_001',
        branchId: 'branch_andheri',
        branchName: 'Andheri West Branch',
        batchId: 'batch_hp1',
        batchName: 'DUPR Elite A1',
        studentId: 'stu_005',
        studentName: 'Vikram Joshi',
        sessionDate: today,
        status: StaffAttendanceStatus.late,
        notes: 'Arrived 10 mins after warm-up.',
        markedByStaffId: _staffProfile.staffId,
        updatedAt: now.subtract(const Duration(hours: 4)),
      ),
      // Unassigned branch record to verify strict branch filtering on read.
      StaffSessionAttendance(
        id: 'att_003',
        academyId: 'acad_001',
        branchId: 'branch_bandra',
        branchName: 'Bandra Kurla Complex',
        batchId: 'batch_j1',
        batchName: 'Junior A1 — Morning',
        studentId: 'stu_002',
        studentName: 'Ananya Verma',
        sessionDate: today,
        status: StaffAttendanceStatus.present,
        markedByStaffId: 'other_staff',
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }

  FailureResult<AcademyStaffWorkspaceData>? _validateStaffContext({
    required String academyId,
    required String staffId,
  }) {
    if (academyId.trim().isEmpty || academyId != _staffProfile.academyId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Unauthorized: academy context mismatch.',
        ),
      );
    }
    if (staffId.trim().isEmpty || staffId != _staffProfile.staffId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Unauthorized: staff identity mismatch.',
        ),
      );
    }
    if (!_staffProfile.isActive) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Access revoked: staff account is inactive.',
        ),
      );
    }
    return null;
  }

  FailureResult<AcademyStaffWorkspaceData>? _requirePermission(
    AcademyStaffPermission permission,
  ) {
    if (!_staffProfile.hasPermission(permission)) {
      return FailureResult(
        ForbiddenFailure(
          message:
              'Permission denied: "${permission.label}" is not delegated to your staff role.',
        ),
      );
    }
    return null;
  }

  FailureResult<AcademyStaffWorkspaceData>? _requireBranchAccess(
    String branchId,
  ) {
    if (!_staffProfile.canAccessBranch(branchId)) {
      return const FailureResult(
        ForbiddenFailure(
          message:
              'Unauthorized: you are not assigned to this academy branch.',
        ),
      );
    }
    return null;
  }

  AcademyStaffWorkspaceData _buildScopedWorkspace() {
    final allowedBranches = _staffProfile.assignedBranchIds.toSet();
    final academyId = _staffProfile.academyId;

    final branches = _allAcademyBranches
        .where((b) => b.academyId == academyId && allowedBranches.contains(b.id))
        .toList();

    final programs = _allAcademyPrograms
        .where((p) =>
            p.academyId == academyId && allowedBranches.contains(p.branchId))
        .toList();

    final batches = _allAcademyBatches
        .where((b) =>
            b.academyId == academyId && allowedBranches.contains(b.branchId))
        .toList();

    final coaches = _staffProfile.hasPermission(AcademyStaffPermission.viewCoaches)
        ? _allAcademyCoaches
            .where((c) =>
                c.academyId == academyId &&
                c.status == CoachAffiliationStatus.accepted &&
                c.assignedBranchIds.any(allowedBranches.contains))
            .toList()
        : const <AcademyCoachAffiliation>[];

    final canSeeStudents =
        _staffProfile.hasPermission(AcademyStaffPermission.viewStudents) ||
            _staffProfile.hasPermission(AcademyStaffPermission.manageEnrollments) ||
            _staffProfile.hasPermission(AcademyStaffPermission.recordTuition);

    final enrollments = canSeeStudents
        ? _allAcademyEnrollments
            .where((e) =>
                e.academyId == academyId &&
                allowedBranches.contains(e.branchId))
            .toList()
        : const <AcademyEnrollmentRecord>[];

    final attendance =
        _staffProfile.hasPermission(AcademyStaffPermission.manageAttendance)
            ? _attendanceRecords
                .where((a) =>
                    a.academyId == academyId &&
                    allowedBranches.contains(a.branchId))
                .toList()
            : const <StaffSessionAttendance>[];

    final todaySessions = batches
        .map(
          (b) => StaffBatchScheduleItem(
            batchId: b.id,
            academyId: b.academyId,
            branchId: b.branchId,
            branchName: b.branchName,
            programId: b.programId,
            programTitle: b.programTitle,
            batchName: b.name,
            scheduleLabel: b.scheduleLabel,
            assignedCoachName: b.assignedCoachName,
            capacity: b.capacity,
            enrolledCount: b.enrolledCount,
          ),
        )
        .toList();

    return AcademyStaffWorkspaceData(
      staffProfile: _staffProfile,
      assignedBranches: branches,
      programs: programs,
      batches: batches,
      coaches: coaches,
      enrollments: enrollments,
      attendanceRecords: attendance,
      todaySessions: todaySessions,
    );
  }

  @override
  Future<Result<AcademyStaffWorkspaceData>> getWorkspaceData({
    required String academyId,
    required String staffId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load Academy Staff workspace.'),
      );
    }
    final contextError = _validateStaffContext(
      academyId: academyId,
      staffId: staffId,
    );
    if (contextError != null) return contextError;

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<AcademyStaffWorkspaceData>> markAttendance({
    required String academyId,
    required String staffId,
    required String attendanceId,
    required StaffAttendanceStatus status,
    String? notes,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update attendance record.'),
      );
    }
    final contextError = _validateStaffContext(
      academyId: academyId,
      staffId: staffId,
    );
    if (contextError != null) return contextError;

    final permError = _requirePermission(AcademyStaffPermission.manageAttendance);
    if (permError != null) return permError;

    final existing = _attendanceRecords
        .where((a) => a.id == attendanceId && a.academyId == academyId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Attendance record not found for this academy.'),
      );
    }

    final branchError = _requireBranchAccess(existing.branchId);
    if (branchError != null) return branchError;

    _attendanceRecords = _attendanceRecords.map((a) {
      if (a.id != attendanceId) return a;
      return a.copyWith(
        status: status,
        notes: notes?.trim(),
        markedByStaffId: staffId,
        updatedAt: DateTime.now(),
      );
    }).toList();

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<AcademyStaffWorkspaceData>> updateBatchScheduleLabel({
    required String academyId,
    required String staffId,
    required String batchId,
    required String scheduleLabel,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update batch schedule.'),
      );
    }
    final contextError = _validateStaffContext(
      academyId: academyId,
      staffId: staffId,
    );
    if (contextError != null) return contextError;

    final permError = _requirePermission(AcademyStaffPermission.manageBatches);
    if (permError != null) return permError;

    if (scheduleLabel.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Schedule timing label is required.'),
      );
    }

    final batch = _allAcademyBatches
        .where((b) => b.id == batchId && b.academyId == academyId)
        .firstOrNull;
    if (batch == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Batch not found for this academy.'),
      );
    }

    final branchError = _requireBranchAccess(batch.branchId);
    if (branchError != null) return branchError;

    _allAcademyBatches = _allAcademyBatches.map((b) {
      if (b.id != batchId) return b;
      return AcademyBatch(
        id: b.id,
        academyId: b.academyId,
        programId: b.programId,
        programTitle: b.programTitle,
        branchId: b.branchId,
        branchName: b.branchName,
        name: b.name,
        scheduleLabel: scheduleLabel.trim(),
        capacity: b.capacity,
        enrolledCount: b.enrolledCount,
        assignedCoachId: b.assignedCoachId,
        assignedCoachName: b.assignedCoachName,
      );
    }).toList();

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<AcademyStaffWorkspaceData>> updateEnrollmentStatus({
    required String academyId,
    required String staffId,
    required String enrollmentId,
    required EnrollmentRequestStatus newStatus,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update enrollment status.'),
      );
    }
    final contextError = _validateStaffContext(
      academyId: academyId,
      staffId: staffId,
    );
    if (contextError != null) return contextError;

    final permError =
        _requirePermission(AcademyStaffPermission.manageEnrollments);
    if (permError != null) return permError;

    final enr = _allAcademyEnrollments
        .where((e) => e.id == enrollmentId && e.academyId == academyId)
        .firstOrNull;
    if (enr == null) {
      return const FailureResult(
        NotFoundFailure(
            message: 'Enrollment record not found for this academy.'),
      );
    }

    final branchError = _requireBranchAccess(enr.branchId);
    if (branchError != null) return branchError;

    // Idempotent guard — prevents duplicate increments/decrements.
    if (enr.status == newStatus) {
      return Success(_buildScopedWorkspace());
    }

    final batch = _allAcademyBatches
        .where((b) => b.id == enr.batchId && b.academyId == academyId)
        .firstOrNull;
    if (batch == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Batch not found for enrollment.'),
      );
    }

    final wasApproved = enr.status == EnrollmentRequestStatus.approved;
    final willBeApproved = newStatus == EnrollmentRequestStatus.approved;

    var updatedBatches = _allAcademyBatches;
    int? nextWaitlistPos;
    var clearWaitlist = false;

    if (!wasApproved && willBeApproved) {
      if (batch.isFull) {
        return const FailureResult(
          ValidationFailure(
            message:
                'Batch is at full capacity. Move student to Waitlisted instead.',
          ),
        );
      }
      updatedBatches = _allAcademyBatches
          .map((b) => b.id == batch.id
              ? b.copyWith(enrolledCount: b.enrolledCount + 1)
              : b)
          .toList();
      clearWaitlist = true;
    } else if (wasApproved && !willBeApproved) {
      updatedBatches = _allAcademyBatches
          .map((b) => b.id == batch.id
              ? b.copyWith(
                  enrolledCount:
                      (b.enrolledCount - 1).clamp(0, b.capacity).toInt(),
                )
              : b)
          .toList();
    }

    if (newStatus == EnrollmentRequestStatus.waitlisted) {
      final currentWaitlisted = _allAcademyEnrollments
          .where((e) =>
              e.academyId == academyId &&
              e.batchId == enr.batchId &&
              e.status == EnrollmentRequestStatus.waitlisted)
          .length;
      nextWaitlistPos = enr.waitlistPosition ?? (currentWaitlisted + 1);
    } else {
      clearWaitlist = true;
    }

    _allAcademyBatches = updatedBatches;
    _allAcademyEnrollments = _allAcademyEnrollments.map((e) {
      if (e.id != enrollmentId) return e;
      return e.copyWith(
        status: newStatus,
        waitlistPosition: nextWaitlistPos,
        clearWaitlistPosition: clearWaitlist,
      );
    }).toList();

    return Success(_buildScopedWorkspace());
  }

  @override
  Future<Result<AcademyStaffWorkspaceData>> recordTuitionPayment({
    required String academyId,
    required String staffId,
    required String enrollmentId,
    required TuitionFeeStatus feeStatus,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to record tuition payment.'),
      );
    }
    final contextError = _validateStaffContext(
      academyId: academyId,
      staffId: staffId,
    );
    if (contextError != null) return contextError;

    final permError = _requirePermission(AcademyStaffPermission.recordTuition);
    if (permError != null) return permError;

    final enr = _allAcademyEnrollments
        .where((e) => e.id == enrollmentId && e.academyId == academyId)
        .firstOrNull;
    if (enr == null) {
      return const FailureResult(
        NotFoundFailure(
            message: 'Enrollment record not found for this academy.'),
      );
    }

    final branchError = _requireBranchAccess(enr.branchId);
    if (branchError != null) return branchError;

    _allAcademyEnrollments = _allAcademyEnrollments.map((e) {
      if (e.id != enrollmentId) return e;
      return e.copyWith(feeStatus: feeStatus);
    }).toList();

    return Success(_buildScopedWorkspace());
  }
}
