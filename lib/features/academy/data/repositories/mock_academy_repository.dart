import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/domain/repositories/academy_repository.dart';

/// In-memory mock implementation of [AcademyRepository] for Phase 3 Feature 3.5.
class MockAcademyRepository implements AcademyRepository {
  final bool shouldFail;
  final bool simulateEmpty;
  AcademyWorkspaceData _data;

  MockAcademyRepository({
    this.shouldFail = false,
    this.simulateEmpty = false,
    AcademyWorkspaceData? initialData,
  }) : _data = initialData ??
            (simulateEmpty ? _buildEmptyData() : _buildSeedData());

  static AcademyWorkspaceData _buildEmptyData() {
    return const AcademyWorkspaceData(
      profile: AcademyProfileSummary(
        academyId: 'acad_001',
        academyName: 'Apex Pickleball Academy',
        ownerName: 'Siddharth Kapoor',
        primaryCity: 'Mumbai',
        contactEmail: 'admin@apexpickleball.in',
      ),
      branches: [],
      programs: [],
      batches: [],
      coachAffiliations: [],
      enrollments: [],
    );
  }

  static AcademyWorkspaceData _buildSeedData() {
    final now = DateTime.now();
    return AcademyWorkspaceData(
      profile: const AcademyProfileSummary(
        academyId: 'acad_001',
        academyName: 'Apex Pickleball Academy',
        ownerName: 'Siddharth Kapoor',
        primaryCity: 'Mumbai',
        contactEmail: 'admin@apexpickleball.in',
      ),
      branches: const [
        AcademyBranch(
          id: 'branch_andheri',
          academyId: 'acad_001',
          name: 'Andheri West Branch',
          city: 'Mumbai',
          address: '14 Link Road, Andheri West, Mumbai 400053',
          operatingHours: '06:00 AM – 10:30 PM',
          courtCount: 6,
          contactPhone: '+91 22 2634 8810',
          isActive: true,
        ),
        AcademyBranch(
          id: 'branch_bandra',
          academyId: 'acad_001',
          name: 'Bandra West Branch',
          city: 'Mumbai',
          address: '28 Chapel Road, Bandra West, Mumbai 400050',
          operatingHours: '06:30 AM – 10:00 PM',
          courtCount: 4,
          contactPhone: '+91 22 2640 5521',
          isActive: true,
        ),
        AcademyBranch(
          id: 'branch_powai',
          academyId: 'acad_001',
          name: 'Powai Training Annex',
          city: 'Mumbai',
          address: 'Hiranandani Gardens, Powai, Mumbai 400076',
          operatingHours: '07:00 AM – 09:00 PM',
          courtCount: 3,
          contactPhone: '+91 22 2570 9932',
          isActive: false,
        ),
      ],
      programs: const [
        AcademyProgram(
          id: 'prog_001',
          academyId: 'acad_001',
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          title: 'Intermediate Doubles Mastery',
          skillLevel: 'Intermediate (3.0–3.5)',
          ageGroup: 'Adults (18+)',
          description:
              'Structured third-shot drop, kitchen dink patterns, and doubles transition positioning.',
          monthlyTuitionInr: 4500,
          isActive: true,
        ),
        AcademyProgram(
          id: 'prog_002',
          academyId: 'acad_001',
          branchId: 'branch_bandra',
          branchName: 'Bandra West Branch',
          title: 'Junior Foundation Academy',
          skillLevel: 'Beginner (1.5–2.5)',
          ageGroup: 'Juniors (9–16)',
          description:
              'Footwork agility, grip fundamentals, rules, and rally consistency for young players.',
          monthlyTuitionInr: 3500,
          isActive: true,
        ),
        AcademyProgram(
          id: 'prog_003',
          academyId: 'acad_001',
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          title: 'High-Performance DUPR Squad',
          skillLevel: 'Advanced (4.0+)',
          ageGroup: 'Open Competitive',
          description:
              'High-tempo counter-attacking drills, video match analysis, and tournament prep.',
          monthlyTuitionInr: 6500,
          isActive: true,
        ),
      ],
      batches: const [
        AcademyBatch(
          id: 'batch_b2',
          academyId: 'acad_001',
          programId: 'prog_001',
          programTitle: 'Intermediate Doubles Mastery',
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          name: 'Batch B2 — Evening',
          scheduleLabel: 'Mon / Wed / Fri • 19:00 – 20:30',
          capacity: 8,
          enrolledCount: 8,
          assignedCoachId: 'coach_001',
          assignedCoachName: 'Aarav Sharma',
        ),
        AcademyBatch(
          id: 'batch_j1',
          academyId: 'acad_001',
          programId: 'prog_002',
          programTitle: 'Junior Foundation Academy',
          branchId: 'branch_bandra',
          branchName: 'Bandra West Branch',
          name: 'Junior Squad J1',
          scheduleLabel: 'Tue / Thu / Sat • 16:30 – 18:00',
          capacity: 10,
          enrolledCount: 7,
          assignedCoachId: 'coach_001',
          assignedCoachName: 'Aarav Sharma',
        ),
        AcademyBatch(
          id: 'batch_hp1',
          academyId: 'acad_001',
          programId: 'prog_003',
          programTitle: 'High-Performance DUPR Squad',
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          name: 'DUPR Elite A1',
          scheduleLabel: 'Sat / Sun • 07:00 – 09:00',
          capacity: 6,
          enrolledCount: 5,
          assignedCoachId: 'coach_002',
          assignedCoachName: 'Priya Nair',
        ),
      ],
      coachAffiliations: [
        AcademyCoachAffiliation(
          id: 'aff_001',
          academyId: 'acad_001',
          coachId: 'coach_001',
          coachName: 'Aarav Sharma',
          coachContact: '+91 98200 12345',
          specialization: 'Doubles Strategy & Third-Shot Drops',
          assignedBranchIds: const ['branch_andheri', 'branch_bandra'],
          assignedBranchNames: const [
            'Andheri West Branch',
            'Bandra West Branch',
          ],
          canModifyOfficialSchedule: false,
          status: CoachAffiliationStatus.accepted,
          invitedAt: now.subtract(const Duration(days: 45)),
        ),
        AcademyCoachAffiliation(
          id: 'aff_002',
          academyId: 'acad_001',
          coachId: 'coach_002',
          coachName: 'Priya Nair',
          coachContact: '+91 98211 67890',
          specialization: 'High-Performance & DUPR Match Play',
          assignedBranchIds: const ['branch_andheri'],
          assignedBranchNames: const ['Andheri West Branch'],
          canModifyOfficialSchedule: true,
          status: CoachAffiliationStatus.accepted,
          invitedAt: now.subtract(const Duration(days: 30)),
        ),
        AcademyCoachAffiliation(
          id: 'aff_003',
          academyId: 'acad_001',
          coachId: 'coach_003',
          coachName: 'Vikram Desai',
          coachContact: '+91 98190 33445',
          specialization: 'Junior Footwork & Agility',
          assignedBranchIds: const ['branch_bandra'],
          assignedBranchNames: const ['Bandra West Branch'],
          canModifyOfficialSchedule: false,
          status: CoachAffiliationStatus.pendingAcceptance,
          invitedAt: now.subtract(const Duration(days: 2)),
        ),
      ],
      enrollments: [
        AcademyEnrollmentRecord(
          id: 'enr_001',
          academyId: 'acad_001',
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          programId: 'prog_001',
          programTitle: 'Intermediate Doubles Mastery',
          batchId: 'batch_b2',
          batchName: 'Batch B2 — Evening',
          studentName: 'Rhea Kulkarni',
          studentContact: '+91 98205 11100',
          status: EnrollmentRequestStatus.approved,
          feeStatus: TuitionFeeStatus.paid,
          tuitionAmountInr: 4500,
          requestedAt: now.subtract(const Duration(days: 20)),
        ),
        AcademyEnrollmentRecord(
          id: 'enr_002',
          academyId: 'acad_001',
          branchId: 'branch_bandra',
          branchName: 'Bandra West Branch',
          programId: 'prog_002',
          programTitle: 'Junior Foundation Academy',
          batchId: 'batch_j1',
          batchName: 'Junior Squad J1',
          studentName: 'Aryan Verma',
          studentContact: '+91 98331 22445',
          guardianName: 'Neha Verma',
          status: EnrollmentRequestStatus.approved,
          feeStatus: TuitionFeeStatus.overdue,
          tuitionAmountInr: 3500,
          requestedAt: now.subtract(const Duration(days: 15)),
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
      ],
    );
  }

  FailureResult<AcademyWorkspaceData>? _validateAcademyOwnership(
    String academyId,
  ) {
    if (academyId.trim().isEmpty || academyId != _data.profile.academyId) {
      return const FailureResult(
        ForbiddenFailure(
          message: 'Unauthorized: academy context mismatch.',
        ),
      );
    }
    return null;
  }

  @override
  Future<Result<AcademyWorkspaceData>> getWorkspaceData({
    required String academyId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load academy workspace data.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> createBranch({
    required String academyId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int courtCount,
    required String contactPhone,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to create branch.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (name.trim().isEmpty || city.trim().isEmpty || address.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Branch name, city, and address are required.',
        ),
      );
    }
    if (courtCount <= 0) {
      return const FailureResult(
        ValidationFailure(message: 'Court count must be at least 1.'),
      );
    }

    final branch = AcademyBranch(
      id: 'branch_${DateTime.now().microsecondsSinceEpoch}',
      academyId: academyId,
      name: name.trim(),
      city: city.trim(),
      address: address.trim(),
      operatingHours: operatingHours.trim().isEmpty
          ? '06:00 AM – 10:00 PM'
          : operatingHours.trim(),
      courtCount: courtCount,
      contactPhone: contactPhone.trim(),
      isActive: true,
    );

    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: [..._data.branches, branch],
      programs: _data.programs,
      batches: _data.batches,
      coachAffiliations: _data.coachAffiliations,
      enrollments: _data.enrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> updateBranch({
    required String academyId,
    required String branchId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int courtCount,
    required String contactPhone,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update branch.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (name.trim().isEmpty || city.trim().isEmpty || address.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Branch name, city, and address are required.',
        ),
      );
    }
    if (courtCount <= 0) {
      return const FailureResult(
        ValidationFailure(message: 'Court count must be at least 1.'),
      );
    }
    final existing = _data.branches
        .where((b) => b.id == branchId && b.academyId == academyId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Branch not found for this academy.'),
      );
    }

    final updatedBranches = _data.branches.map((b) {
      if (b.id != branchId) return b;
      return b.copyWith(
        name: name.trim(),
        city: city.trim(),
        address: address.trim(),
        operatingHours: operatingHours.trim(),
        courtCount: courtCount,
        contactPhone: contactPhone.trim(),
      );
    }).toList();

    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: updatedBranches,
      programs: _data.programs,
      batches: _data.batches,
      coachAffiliations: _data.coachAffiliations,
      enrollments: _data.enrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> toggleBranchStatus({
    required String academyId,
    required String branchId,
    required bool isActive,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update branch status.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    final existing = _data.branches
        .where((b) => b.id == branchId && b.academyId == academyId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Branch not found for this academy.'),
      );
    }
    final updatedBranches = _data.branches
        .map((b) => b.id == branchId ? b.copyWith(isActive: isActive) : b)
        .toList();
    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: updatedBranches,
      programs: _data.programs,
      batches: _data.batches,
      coachAffiliations: _data.coachAffiliations,
      enrollments: _data.enrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> createProgram({
    required String academyId,
    required String branchId,
    required String title,
    required String skillLevel,
    required String ageGroup,
    required String description,
    required double monthlyTuitionInr,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to create program.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (title.trim().isEmpty || monthlyTuitionInr < 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Program title and non-negative tuition are required.',
        ),
      );
    }
    final branch = _data.branches
        .where((b) => b.id == branchId && b.academyId == academyId)
        .firstOrNull;
    if (branch == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Selected branch not found for this academy.'),
      );
    }

    final program = AcademyProgram(
      id: 'prog_${DateTime.now().microsecondsSinceEpoch}',
      academyId: academyId,
      branchId: branch.id,
      branchName: branch.name,
      title: title.trim(),
      skillLevel: skillLevel.trim().isEmpty ? 'All Levels' : skillLevel.trim(),
      ageGroup: ageGroup.trim().isEmpty ? 'Open' : ageGroup.trim(),
      description: description.trim(),
      monthlyTuitionInr: monthlyTuitionInr,
      isActive: true,
    );

    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: _data.branches,
      programs: [..._data.programs, program],
      batches: _data.batches,
      coachAffiliations: _data.coachAffiliations,
      enrollments: _data.enrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> toggleProgramStatus({
    required String academyId,
    required String programId,
    required bool isActive,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update program status.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    final existing = _data.programs
        .where((p) => p.id == programId && p.academyId == academyId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Program not found for this academy.'),
      );
    }
    final updatedPrograms = _data.programs
        .map((p) => p.id == programId ? p.copyWith(isActive: isActive) : p)
        .toList();
    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: _data.branches,
      programs: updatedPrograms,
      batches: _data.batches,
      coachAffiliations: _data.coachAffiliations,
      enrollments: _data.enrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> createBatch({
    required String academyId,
    required String programId,
    required String name,
    required String scheduleLabel,
    required int capacity,
    String? assignedCoachId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to create batch.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (name.trim().isEmpty || scheduleLabel.trim().isEmpty || capacity <= 0) {
      return const FailureResult(
        ValidationFailure(
          message: 'Batch name, schedule, and capacity (> 0) are required.',
        ),
      );
    }
    final program = _data.programs
        .where((p) => p.id == programId && p.academyId == academyId)
        .firstOrNull;
    if (program == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Program not found for this academy.'),
      );
    }

    AcademyCoachAffiliation? coach;
    if (assignedCoachId != null && assignedCoachId.isNotEmpty) {
      coach = _data.coachAffiliations
          .where((c) =>
              c.academyId == academyId &&
              c.coachId == assignedCoachId &&
              c.status == CoachAffiliationStatus.accepted)
          .firstOrNull;
      if (coach == null) {
        return const FailureResult(
          ValidationFailure(
            message: 'Only accepted affiliated coaches can be assigned to batches.',
          ),
        );
      }
      if (!coach.assignedBranchIds.contains(program.branchId)) {
        return FailureResult(
          ValidationFailure(
            message:
                'Coach must be assigned to ${program.branchName} before leading this batch.',
          ),
        );
      }
    }

    final batch = AcademyBatch(
      id: 'batch_${DateTime.now().microsecondsSinceEpoch}',
      academyId: academyId,
      programId: program.id,
      programTitle: program.title,
      branchId: program.branchId,
      branchName: program.branchName,
      name: name.trim(),
      scheduleLabel: scheduleLabel.trim(),
      capacity: capacity,
      enrolledCount: 0,
      assignedCoachId: coach?.coachId,
      assignedCoachName: coach?.coachName,
    );

    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: _data.branches,
      programs: _data.programs,
      batches: [..._data.batches, batch],
      coachAffiliations: _data.coachAffiliations,
      enrollments: _data.enrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> inviteCoach({
    required String academyId,
    required String coachName,
    required String coachContact,
    required String specialization,
    required List<String> branchIds,
    required bool canModifyOfficialSchedule,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to send coach invitation.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (coachName.trim().isEmpty || branchIds.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Coach name and at least one branch are required.',
        ),
      );
    }

    final uniqueBranchIds = branchIds.toSet().toList();
    final validBranches = _data.branches
        .where((b) => b.academyId == academyId && uniqueBranchIds.contains(b.id))
        .toList();
    if (validBranches.length != uniqueBranchIds.length) {
      return const FailureResult(
        NotFoundFailure(
          message:
              'One or more selected branches were not found for this academy.',
        ),
      );
    }
    final branchNames = validBranches.map((b) => b.name).toList();

    final affiliation = AcademyCoachAffiliation(
      id: 'aff_${DateTime.now().microsecondsSinceEpoch}',
      academyId: academyId,
      coachId: 'coach_${DateTime.now().microsecondsSinceEpoch}',
      coachName: coachName.trim(),
      coachContact: coachContact.trim(),
      specialization: specialization.trim().isEmpty
          ? 'General Pickleball Coaching'
          : specialization.trim(),
      assignedBranchIds: List<String>.from(branchIds),
      assignedBranchNames: branchNames,
      canModifyOfficialSchedule: canModifyOfficialSchedule,
      // Business rule: Coach must accept before becoming an active affiliation.
      status: CoachAffiliationStatus.pendingAcceptance,
      invitedAt: DateTime.now(),
    );

    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: _data.branches,
      programs: _data.programs,
      batches: _data.batches,
      coachAffiliations: [..._data.coachAffiliations, affiliation],
      enrollments: _data.enrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> updateCoachAssignment({
    required String academyId,
    required String affiliationId,
    required List<String> branchIds,
    required bool canModifyOfficialSchedule,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update coach assignment.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (branchIds.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Select at least one assigned branch.'),
      );
    }
    final existing = _data.coachAffiliations
        .where((c) => c.id == affiliationId && c.academyId == academyId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Coach affiliation not found for this academy.'),
      );
    }

    final uniqueBranchIds = branchIds.toSet().toList();
    final validBranches = _data.branches
        .where((b) => b.academyId == academyId && uniqueBranchIds.contains(b.id))
        .toList();
    if (validBranches.length != uniqueBranchIds.length) {
      return const FailureResult(
        NotFoundFailure(
          message:
              'One or more selected branches were not found for this academy.',
        ),
      );
    }
    final branchNames = validBranches.map((b) => b.name).toList();

    final updated = _data.coachAffiliations.map((c) {
      if (c.id != affiliationId) return c;
      return c.copyWith(
        assignedBranchIds: List<String>.from(uniqueBranchIds),
        assignedBranchNames: branchNames,
        canModifyOfficialSchedule: canModifyOfficialSchedule,
      );
    }).toList();

    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: _data.branches,
      programs: _data.programs,
      batches: _data.batches,
      coachAffiliations: updated,
      enrollments: _data.enrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> revokeCoachAffiliation({
    required String academyId,
    required String affiliationId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to revoke affiliation.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    final existing = _data.coachAffiliations
        .where((c) => c.id == affiliationId && c.academyId == academyId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Coach affiliation not found for this academy.'),
      );
    }
    final updated = _data.coachAffiliations.map((c) {
      if (c.id != affiliationId) return c;
      return c.copyWith(status: CoachAffiliationStatus.revoked);
    }).toList();

    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: _data.branches,
      programs: _data.programs,
      batches: _data.batches,
      coachAffiliations: updated,
      enrollments: _data.enrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> updateEnrollmentStatus({
    required String academyId,
    required String enrollmentId,
    required EnrollmentRequestStatus newStatus,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update enrollment status.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;

    final enr = _data.enrollments
        .where((e) => e.id == enrollmentId && e.academyId == academyId)
        .firstOrNull;
    if (enr == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Enrollment record not found for this academy.'),
      );
    }

    // No-op if status is unchanged — prevents duplicate seat increments/decrements.
    if (enr.status == newStatus) {
      return Success(_data);
    }

    final batch = _data.batches
        .where((b) => b.id == enr.batchId && b.academyId == academyId)
        .firstOrNull;
    if (batch == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Batch not found for enrollment.'),
      );
    }

    final wasApproved = enr.status == EnrollmentRequestStatus.approved;
    final willBeApproved = newStatus == EnrollmentRequestStatus.approved;

    var updatedBatches = _data.batches;
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
      updatedBatches = _data.batches
          .map((b) => b.id == batch.id
              ? b.copyWith(enrolledCount: b.enrolledCount + 1)
              : b)
          .toList();
      clearWaitlist = true;
    } else if (wasApproved && !willBeApproved) {
      updatedBatches = _data.batches
          .map((b) => b.id == batch.id
              ? b.copyWith(
                  enrolledCount:
                      (b.enrolledCount - 1).clamp(0, b.capacity).toInt(),
                )
              : b)
          .toList();
    }

    if (newStatus == EnrollmentRequestStatus.waitlisted) {
      final currentWaitlisted = _data.enrollments
          .where((e) =>
              e.academyId == academyId &&
              e.batchId == enr.batchId &&
              e.status == EnrollmentRequestStatus.waitlisted)
          .length;
      nextWaitlistPos = enr.waitlistPosition ?? (currentWaitlisted + 1);
    } else {
      clearWaitlist = true;
    }

    final updatedEnrollments = _data.enrollments.map((e) {
      if (e.id != enrollmentId) return e;
      return e.copyWith(
        status: newStatus,
        waitlistPosition: nextWaitlistPos,
        clearWaitlistPosition: clearWaitlist,
      );
    }).toList();

    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: _data.branches,
      programs: _data.programs,
      batches: updatedBatches,
      coachAffiliations: _data.coachAffiliations,
      enrollments: updatedEnrollments,
    );
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> recordTuitionPayment({
    required String academyId,
    required String enrollmentId,
    required TuitionFeeStatus feeStatus,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update tuition status.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;

    final existing = _data.enrollments
        .where((e) => e.id == enrollmentId && e.academyId == academyId)
        .firstOrNull;
    if (existing == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Enrollment record not found for this academy.'),
      );
    }

    final updatedEnrollments = _data.enrollments.map((e) {
      if (e.id != enrollmentId) return e;
      return e.copyWith(feeStatus: feeStatus);
    }).toList();

    _data = AcademyWorkspaceData(
      profile: _data.profile,
      branches: _data.branches,
      programs: _data.programs,
      batches: _data.batches,
      coachAffiliations: _data.coachAffiliations,
      enrollments: updatedEnrollments,
    );
    return Success(_data);
  }
}
