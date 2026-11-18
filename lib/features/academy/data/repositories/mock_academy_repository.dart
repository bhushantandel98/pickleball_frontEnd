import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/domain/repositories/academy_repository.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

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
          contactPerson: 'Rohan Deshmukh',
          city: 'Mumbai',
          address: '14 Link Road, Andheri West, Mumbai 400053',
          contactPhone: '+91 22 2634 8810',
          isActive: true,
        ),
        AcademyBranch(
          id: 'branch_bandra',
          academyId: 'acad_001',
          name: 'Bandra West Branch',
          contactPerson: 'Meera Kulkarni',
          city: 'Mumbai',
          address: '28 Chapel Road, Bandra West, Mumbai 400050',
          contactPhone: '+91 22 2640 5521',
          isActive: true,
        ),
        AcademyBranch(
          id: 'branch_powai',
          academyId: 'acad_001',
          name: 'Powai Training Annex',
          contactPerson: 'Ankit Joshi',
          city: 'Mumbai',
          address: 'Hiranandani Gardens, Powai, Mumbai 400076',
          contactPhone: '+91 22 2570 9932',
          isActive: false,
        ),
      ],
      programs: const [],
      batches: const [
        AcademyBatch(
          id: 'batch_b2',
          academyId: 'acad_001',
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          name: 'Evening Intermediate Batch',
          skillLevel: BatchSkillLevel.intermediate,
          daysOfWeek: ['Mon', 'Wed', 'Fri'],
          startTime: '07:00 PM',
          endTime: '08:30 PM',
          scheduleLabel: 'Mon, Wed, Fri • 07:00 PM – 08:30 PM',
          capacity: 8,
          enrolledCount: 6,
          assignedCoachId: 'coach_001',
          assignedCoachName: 'Aarav Sharma',
        ),
        AcademyBatch(
          id: 'batch_j1',
          academyId: 'acad_001',
          branchId: 'branch_bandra',
          branchName: 'Bandra West Branch',
          name: 'Morning Beginner Squad',
          skillLevel: BatchSkillLevel.beginner,
          daysOfWeek: ['Tue', 'Thu', 'Sat'],
          startTime: '07:30 AM',
          endTime: '09:00 AM',
          scheduleLabel: 'Tue, Thu, Sat • 07:30 AM – 09:00 AM',
          capacity: 10,
          enrolledCount: 7,
          assignedCoachId: 'coach_001',
          assignedCoachName: 'Aarav Sharma',
        ),
        AcademyBatch(
          id: 'batch_hp1',
          academyId: 'acad_001',
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          name: 'Weekend Advanced Squad',
          skillLevel: BatchSkillLevel.advanced,
          daysOfWeek: ['Sat', 'Sun'],
          startTime: '07:00 AM',
          endTime: '09:00 AM',
          scheduleLabel: 'Sat, Sun • 07:00 AM – 09:00 AM',
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
          programId: '',
          programTitle: '',
          batchId: 'batch_b2',
          batchName: 'Evening Intermediate Batch',
          studentName: 'Sanya Bhatia',
          studentContact: '+91 98198 77665',
          status: EnrollmentRequestStatus.declined,
          feeStatus: TuitionFeeStatus.pending,
          tuitionAmountInr: 4500,
          requestedAt: now.subtract(const Duration(days: 5)),
        ),
      ],
      coachDirectory: const [
        CoachDirectoryCandidate(
          coachId: 'coach_001',
          name: 'Aarav Sharma',
          mobileNumber: '9820012345',
          specialization: 'Doubles Strategy & Third-Shot Drops',
          experienceYears: 6,
          rating: 4.8,
          city: 'Mumbai',
          bio: 'Former national finalist focusing on doubles positioning and kitchen-line consistency.',
        ),
        CoachDirectoryCandidate(
          coachId: 'coach_002',
          name: 'Priya Nair',
          mobileNumber: '9821167890',
          specialization: 'High-Performance Match Play',
          experienceYears: 8,
          rating: 4.9,
          city: 'Mumbai',
          bio: 'High-tempo counter-attacking specialist and tournament preparation mentor.',
        ),
        CoachDirectoryCandidate(
          coachId: 'coach_003',
          name: 'Vikram Desai',
          mobileNumber: '9819033445',
          specialization: 'Junior Footwork & Agility',
          experienceYears: 5,
          rating: 4.7,
          city: 'Mumbai',
          bio: 'Certified youth pickleball coach building speed, footwork, and rally habits.',
        ),
        CoachDirectoryCandidate(
          coachId: 'coach_004',
          name: 'Kabir Mehta',
          mobileNumber: '9820455667',
          specialization: 'Beginner Fundamentals & Serve Mechanics',
          experienceYears: 4,
          rating: 4.6,
          city: 'Mumbai',
          bio: 'Patient fundamentals coach helping new players master grips, serves, and scoring.',
        ),
        CoachDirectoryCandidate(
          coachId: 'coach_005',
          name: 'Neha Kapoor',
          mobileNumber: '9876541122',
          specialization: 'Pro Tactical Video Analysis',
          experienceYears: 9,
          rating: 4.9,
          city: 'Mumbai',
          bio: 'Pro-level tactical analyst coaching tournament athletes on shot selection.',
        ),
      ],
      students: [
        AcademyStudent(
          id: 'stu_001',
          academyId: 'acad_001',
          name: 'Rhea Kulkarni',
          phone: '+91 98205 11100',
          email: 'rhea.k@example.com',
          ageGroup: 'Adult (24)',
          skillLevel: BatchSkillLevel.intermediate,
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          batchId: 'batch_b2',
          batchName: 'Evening Intermediate Batch',
          assignedCoachId: 'coach_001',
          assignedCoachName: 'Aarav Sharma',
          enrollmentStatus: EnrollmentRequestStatus.approved,
          paymentStatus: TuitionFeeStatus.paid,
          monthlyFeeInr: 4500,
          joinedAt: now.subtract(const Duration(days: 60)),
          academyNotes: 'Prefers evening slots; emergency contact: +91 98205 00001.',
          attendanceHistory: [
            StudentAttendanceEntry(
              id: 'att_1',
              date: now.subtract(const Duration(days: 2)),
              batchName: 'Evening Intermediate Batch',
              status: 'Present',
              markedBy: 'Staff: Kavita Rao',
            ),
            StudentAttendanceEntry(
              id: 'att_2',
              date: now.subtract(const Duration(days: 4)),
              batchName: 'Evening Intermediate Batch',
              status: 'Present',
              markedBy: 'Staff: Kavita Rao',
            ),
            StudentAttendanceEntry(
              id: 'att_3',
              date: now.subtract(const Duration(days: 7)),
              batchName: 'Evening Intermediate Batch',
              status: 'Late',
              markedBy: 'Staff: Kavita Rao',
            ),
          ],
          coachAssessments: [
            CoachPerformanceAssessment(
              id: 'assess_1',
              date: now.subtract(const Duration(days: 3)),
              coachId: 'coach_001',
              coachName: 'Aarav Sharma',
              focusArea: 'Third-Shot Drop & Transition Reset',
              progressScore: 84,
              aspectRatings: const {
                'asp_serve': 8,
                'asp_return': 8,
                'asp_dink': 9,
                'asp_drop': 8,
                'asp_volley': 8,
                'asp_reset': 9,
                'asp_footwork': 8,
                'asp_positioning': 9,
                'asp_shot_sel': 8,
                'asp_agility': 8,
                'asp_stamina': 9,
                'asp_composure': 9,
              },
              feedback: 'Consistent soft drops under pressure; work on split-step timing at mid-court.',
            ),
            CoachPerformanceAssessment(
              id: 'assess_2',
              date: now.subtract(const Duration(days: 17)),
              coachId: 'coach_001',
              coachName: 'Aarav Sharma',
              focusArea: 'Kitchen Line Dink Patience',
              progressScore: 76,
              aspectRatings: const {
                'asp_serve': 7,
                'asp_return': 7,
                'asp_dink': 8,
                'asp_drop': 7,
                'asp_volley': 7,
                'asp_reset': 8,
                'asp_footwork': 7,
                'asp_positioning': 8,
                'asp_shot_sel': 8,
                'asp_agility': 8,
                'asp_stamina': 8,
                'asp_composure': 8,
              },
              feedback: 'Good cross-court dink depth; avoid popping up backhand volleys.',
            ),
          ],
        ),
        AcademyStudent(
          id: 'stu_002',
          academyId: 'acad_001',
          name: 'Aryan Verma',
          phone: '+91 98331 22445',
          email: 'aryan.v@example.com',
          ageGroup: 'Junior (14)',
          skillLevel: BatchSkillLevel.beginner,
          branchId: 'branch_bandra',
          branchName: 'Bandra West Branch',
          batchId: 'batch_j1',
          batchName: 'Morning Beginner Squad',
          assignedCoachId: 'coach_001',
          assignedCoachName: 'Aarav Sharma',
          enrollmentStatus: EnrollmentRequestStatus.approved,
          paymentStatus: TuitionFeeStatus.overdue,
          monthlyFeeInr: 3500,
          joinedAt: now.subtract(const Duration(days: 35)),
          academyNotes: 'Guardian: Neha Verma (+91 98331 22440). Fee reminder sent.',
          attendanceHistory: [
            StudentAttendanceEntry(
              id: 'att_4',
              date: now.subtract(const Duration(days: 1)),
              batchName: 'Morning Beginner Squad',
              status: 'Present',
              markedBy: 'Staff: Kavita Rao',
            ),
            StudentAttendanceEntry(
              id: 'att_5',
              date: now.subtract(const Duration(days: 3)),
              batchName: 'Morning Beginner Squad',
              status: 'Absent',
              markedBy: 'Staff: Kavita Rao',
            ),
          ],
          coachAssessments: [
            CoachPerformanceAssessment(
              id: 'assess_3',
              date: now.subtract(const Duration(days: 5)),
              coachId: 'coach_001',
              coachName: 'Aarav Sharma',
              focusArea: 'Serve Placement & Footwork',
              progressScore: 71,
              feedback: 'Great lateral agility; keep paddle up in ready position after serve.',
            ),
          ],
        ),
        AcademyStudent(
          id: 'stu_003',
          academyId: 'acad_001',
          name: 'Karan Malhotra',
          phone: '+91 98207 99881',
          email: 'karan.m@example.com',
          ageGroup: 'Adult (29)',
          skillLevel: BatchSkillLevel.advanced,
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          batchId: 'batch_hp1',
          batchName: 'Weekend Advanced Squad',
          assignedCoachId: 'coach_002',
          assignedCoachName: 'Priya Nair',
          enrollmentStatus: EnrollmentRequestStatus.pending,
          paymentStatus: TuitionFeeStatus.pending,
          monthlyFeeInr: 6500,
          joinedAt: now.subtract(const Duration(days: 1)),
          academyNotes: 'Trial session completed on Saturday; awaiting final approval.',
          attendanceHistory: const [],
          coachAssessments: [
            CoachPerformanceAssessment(
              id: 'assess_4',
              date: now.subtract(const Duration(days: 2)),
              coachId: 'coach_002',
              coachName: 'Priya Nair',
              focusArea: 'Trial Evaluation — Counter-Attacking',
              progressScore: 88,
              feedback: 'Strong hand speed at NVZ; recommended for Weekend Advanced Squad.',
            ),
          ],
        ),
      ],
      staffMembers: [
        AcademyStaffMember(
          staffId: 'staff_acad_001',
          userId: 'user_acad_staff_001',
          academyId: 'acad_001',
          name: 'Kavita Rao',
          email: 'kavita.rao@apexpickleball.in',
          phone: '+91 98200 55443',
          roleTitle: 'Branch Operations Coordinator',
          assignedBranchIds: const ['branch_andheri'],
          assignedBranchNames: const ['Andheri West Branch'],
          permissions: const {
            AcademyStaffPermission.viewDashboard,
            AcademyStaffPermission.manageAttendance,
            AcademyStaffPermission.manageBatches,
            AcademyStaffPermission.manageEnrollments,
            AcademyStaffPermission.viewStudents,
            AcademyStaffPermission.viewCoaches,
          },
          isActive: true,
          assignedAt: now.subtract(const Duration(days: 90)),
        ),
      ],
      attendanceTrends: const [
        AttendanceTrendPoint(label: 'Mon', attendanceRate: 88),
        AttendanceTrendPoint(label: 'Tue', attendanceRate: 82),
        AttendanceTrendPoint(label: 'Wed', attendanceRate: 91),
        AttendanceTrendPoint(label: 'Thu', attendanceRate: 85),
        AttendanceTrendPoint(label: 'Fri', attendanceRate: 90),
        AttendanceTrendPoint(label: 'Sat', attendanceRate: 94),
        AttendanceTrendPoint(label: 'Sun', attendanceRate: 89),
      ],
      performanceAspects: const [
        PerformanceAspectConfig(
          id: 'asp_serve',
          label: 'Serve Consistency',
          category: 'Technical',
        ),
        PerformanceAspectConfig(
          id: 'asp_return',
          label: 'Return Depth',
          category: 'Technical',
        ),
        PerformanceAspectConfig(
          id: 'asp_dink',
          label: 'Dink Control',
          category: 'Technical',
        ),
        PerformanceAspectConfig(
          id: 'asp_drop',
          label: 'Third-Shot Drop',
          category: 'Technical',
        ),
        PerformanceAspectConfig(
          id: 'asp_volley',
          label: 'NVZ Volley Reflexes',
          category: 'Technical',
        ),
        PerformanceAspectConfig(
          id: 'asp_reset',
          label: 'Transition Reset',
          category: 'Tactical',
        ),
        PerformanceAspectConfig(
          id: 'asp_footwork',
          label: 'Footwork & Balance',
          category: 'Physical',
        ),
        PerformanceAspectConfig(
          id: 'asp_positioning',
          label: 'Court Positioning',
          category: 'Tactical',
        ),
        PerformanceAspectConfig(
          id: 'asp_shot_sel',
          label: 'Shot Selection',
          category: 'Tactical',
        ),
        PerformanceAspectConfig(
          id: 'asp_agility',
          label: 'Lateral Agility',
          category: 'Physical',
        ),
        PerformanceAspectConfig(
          id: 'asp_stamina',
          label: 'Match Stamina',
          category: 'Physical',
        ),
        PerformanceAspectConfig(
          id: 'asp_composure',
          label: 'Mental Composure',
          category: 'Mental',
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

  AcademyWorkspaceData _withUpdatedData({
    List<AcademyBranch>? branches,
    List<AcademyProgram>? programs,
    List<AcademyBatch>? batches,
    List<AcademyCoachAffiliation>? coachAffiliations,
    List<AcademyEnrollmentRecord>? enrollments,
    List<AcademyStudent>? students,
    List<AcademyStaffMember>? staffMembers,
  }) {
    return AcademyWorkspaceData(
      profile: _data.profile,
      branches: branches ?? _data.branches,
      programs: programs ?? _data.programs,
      batches: batches ?? _data.batches,
      coachAffiliations: coachAffiliations ?? _data.coachAffiliations,
      enrollments: enrollments ?? _data.enrollments,
      coachDirectory: _data.coachDirectory,
      students: students ?? _data.students,
      staffMembers: staffMembers ?? _data.staffMembers,
      attendanceTrends: _data.attendanceTrends,
      performanceAspects: _data.performanceAspects,
    );
  }

  @override
  Future<Result<AcademyWorkspaceData>> createBranch({
    required String academyId,
    required String name,
    String contactPerson = '',
    String city = '',
    required String address,
    String operatingHours = '',
    int courtCount = 0,
    String contactPhone = '',
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to create branch.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (name.trim().isEmpty || address.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Branch name and address are required.',
        ),
      );
    }

    final branch = AcademyBranch(
      id: 'branch_${DateTime.now().microsecondsSinceEpoch}',
      academyId: academyId,
      name: name.trim(),
      contactPerson: contactPerson.trim(),
      city: city.trim(),
      address: address.trim(),
      operatingHours: operatingHours.trim(),
      courtCount: courtCount,
      contactPhone: contactPhone.trim(),
      isActive: true,
    );

    _data = _withUpdatedData(branches: [..._data.branches, branch]);
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> updateBranch({
    required String academyId,
    required String branchId,
    required String name,
    String contactPerson = '',
    String city = '',
    required String address,
    String operatingHours = '',
    int courtCount = 0,
    String contactPhone = '',
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update branch.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (name.trim().isEmpty || address.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Branch name and address are required.',
        ),
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
        contactPerson: contactPerson.trim(),
        city: city.trim(),
        address: address.trim(),
        operatingHours: operatingHours.trim(),
        courtCount: courtCount,
        contactPhone: contactPhone.trim(),
      );
    }).toList();

    _data = _withUpdatedData(branches: updatedBranches);
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
    String programId = '',
    String? branchId,
    required String name,
    BatchSkillLevel skillLevel = BatchSkillLevel.beginner,
    List<String> daysOfWeek = const ['Mon', 'Wed', 'Fri'],
    String startTime = '06:00 PM',
    String endTime = '07:30 PM',
    String? scheduleLabel,
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
    if (name.trim().isEmpty || capacity <= 0 || daysOfWeek.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Batch name, training days, and capacity (> 0) are required.',
        ),
      );
    }

    final targetBranchId = branchId?.trim() ?? '';
    final branch = _data.branches
        .where((b) => b.id == targetBranchId && b.academyId == academyId)
        .firstOrNull;
    if (branch == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Branch not found for this academy.'),
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
            message: 'Only approved academy coaches can be assigned to batches.',
          ),
        );
      }
    }

    final resolvedSchedule = scheduleLabel?.trim().isNotEmpty == true
        ? scheduleLabel!.trim()
        : '${daysOfWeek.join(', ')} • $startTime – $endTime';

    final batch = AcademyBatch(
      id: 'batch_${DateTime.now().microsecondsSinceEpoch}',
      academyId: academyId,
      programId: programId,
      branchId: branch.id,
      branchName: branch.name,
      name: name.trim(),
      skillLevel: skillLevel,
      daysOfWeek: List<String>.from(daysOfWeek),
      startTime: startTime.trim(),
      endTime: endTime.trim(),
      scheduleLabel: resolvedSchedule,
      capacity: capacity,
      enrolledCount: 0,
      assignedCoachId: coach?.coachId,
      assignedCoachName: coach?.coachName,
    );

    _data = _withUpdatedData(batches: [..._data.batches, batch]);
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> updateBatch({
    required String academyId,
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
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update batch.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (name.trim().isEmpty || capacity <= 0 || daysOfWeek.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Batch name, training days, and capacity (> 0) are required.',
        ),
      );
    }
    final branch = _data.branches
        .where((b) => b.id == branchId && b.academyId == academyId)
        .firstOrNull;
    if (branch == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Branch not found for this academy.'),
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
            message: 'Only approved academy coaches can be assigned to batches.',
          ),
        );
      }
    }

    final resolvedSchedule = '${daysOfWeek.join(', ')} • $startTime – $endTime';
    final updatedBatches = _data.batches.map((b) {
      if (b.id != batchId) return b;
      return b.copyWith(
        branchId: branch.id,
        branchName: branch.name,
        name: name.trim(),
        skillLevel: skillLevel,
        daysOfWeek: List<String>.from(daysOfWeek),
        startTime: startTime.trim(),
        endTime: endTime.trim(),
        scheduleLabel: resolvedSchedule,
        capacity: capacity,
        assignedCoachId: coach?.coachId,
        assignedCoachName: coach?.coachName,
        clearAssignedCoach: coach == null,
      );
    }).toList();

    _data = _withUpdatedData(batches: updatedBatches);
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> assignCoachToBatch({
    required String academyId,
    required String batchId,
    String? coachId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to assign coach to batch.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;

    AcademyCoachAffiliation? coach;
    if (coachId != null && coachId.isNotEmpty) {
      coach = _data.coachAffiliations
          .where((c) =>
              c.academyId == academyId &&
              c.coachId == coachId &&
              c.status == CoachAffiliationStatus.accepted)
          .firstOrNull;
      if (coach == null) {
        return const FailureResult(
          ValidationFailure(
            message: 'Only approved coaches can be assigned to a batch.',
          ),
        );
      }
    }

    final updatedBatches = _data.batches.map((b) {
      if (b.id != batchId) return b;
      return b.copyWith(
        assignedCoachId: coach?.coachId,
        assignedCoachName: coach?.coachName,
        clearAssignedCoach: coach == null,
      );
    }).toList();

    _data = _withUpdatedData(batches: updatedBatches);
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> sendCoachConnectionRequest({
    required String academyId,
    required String coachId,
    required List<String> branchIds,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to send coach connection request.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;

    final candidate = _data.coachDirectory
        .where((c) => c.coachId == coachId)
        .firstOrNull;
    if (candidate == null) {
      return const FailureResult(
        NotFoundFailure(message: 'Coach not found in directory.'),
      );
    }

    final alreadyExists = _data.coachAffiliations.any(
      (a) =>
          a.coachId == coachId &&
          (a.status == CoachAffiliationStatus.accepted ||
              a.status == CoachAffiliationStatus.pendingAcceptance),
    );
    if (alreadyExists) {
      return const FailureResult(
        ValidationFailure(
          message: 'This coach already has an active or pending connection.',
        ),
      );
    }

    final selectedBranches =
        _data.branches.where((b) => branchIds.contains(b.id)).toList();
    if (selectedBranches.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Select at least one branch.'),
      );
    }

    final affiliation = AcademyCoachAffiliation(
      id: 'aff_${DateTime.now().microsecondsSinceEpoch}',
      academyId: academyId,
      coachId: candidate.coachId,
      coachName: candidate.name,
      coachContact: candidate.mobileNumber,
      specialization: candidate.specialization,
      assignedBranchIds: selectedBranches.map((b) => b.id).toList(),
      assignedBranchNames: selectedBranches.map((b) => b.name).toList(),
      canModifyOfficialSchedule: false,
      status: CoachAffiliationStatus.pendingAcceptance,
      invitedAt: DateTime.now(),
    );

    _data = _withUpdatedData(
      coachAffiliations: [affiliation, ..._data.coachAffiliations],
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

    _data = _withUpdatedData(coachAffiliations: updated);
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

    _data = _withUpdatedData(coachAffiliations: updated);
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

    _data = _withUpdatedData(
      batches: updatedBatches,
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

    _data = _withUpdatedData(enrollments: updatedEnrollments);
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> addStaffMember({
    required String academyId,
    required String name,
    required String email,
    required String phone,
    required String roleTitle,
    required List<String> assignedBranchIds,
    required Set<AcademyStaffPermission> permissions,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to add staff member.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    if (name.trim().isEmpty || email.trim().isEmpty || roleTitle.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Staff name, email, and role title are required.',
        ),
      );
    }
    final branches =
        _data.branches.where((b) => assignedBranchIds.contains(b.id)).toList();
    if (branches.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Assign at least one branch to staff.'),
      );
    }

    final member = AcademyStaffMember(
      staffId: 'staff_${DateTime.now().microsecondsSinceEpoch}',
      userId: 'user_staff_${DateTime.now().microsecondsSinceEpoch}',
      academyId: academyId,
      name: name.trim(),
      email: email.trim(),
      phone: phone.trim(),
      roleTitle: roleTitle.trim(),
      assignedBranchIds: branches.map((b) => b.id).toList(),
      assignedBranchNames: branches.map((b) => b.name).toList(),
      permissions: Set<AcademyStaffPermission>.from(permissions),
      isActive: true,
      assignedAt: DateTime.now(),
    );

    _data = _withUpdatedData(staffMembers: [..._data.staffMembers, member]);
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> updateStaffMember({
    required String academyId,
    required String staffId,
    required String roleTitle,
    required List<String> assignedBranchIds,
    required Set<AcademyStaffPermission> permissions,
    required bool isActive,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update staff member.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;
    final branches =
        _data.branches.where((b) => assignedBranchIds.contains(b.id)).toList();
    if (branches.isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Assign at least one branch to staff.'),
      );
    }

    final updatedStaff = _data.staffMembers.map((m) {
      if (m.staffId != staffId) return m;
      return m.copyWith(
        roleTitle: roleTitle.trim(),
        assignedBranchIds: branches.map((b) => b.id).toList(),
        assignedBranchNames: branches.map((b) => b.name).toList(),
        permissions: Set<AcademyStaffPermission>.from(permissions),
        isActive: isActive,
      );
    }).toList();

    _data = _withUpdatedData(staffMembers: updatedStaff);
    return Success(_data);
  }

  @override
  Future<Result<AcademyWorkspaceData>> recordStudentAssessment({
    required String academyId,
    required String studentId,
    required String coachId,
    required String coachName,
    required String focusArea,
    required Map<String, int> aspectRatings,
    required String feedback,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to record student assessment.'),
      );
    }
    final ownershipError = _validateAcademyOwnership(academyId);
    if (ownershipError != null) return ownershipError;

    if (focusArea.trim().isEmpty || aspectRatings.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Focus area and at least one aspect rating are required.',
        ),
      );
    }

    final validRatings = <String, int>{};
    for (final entry in aspectRatings.entries) {
      validRatings[entry.key] = entry.value.clamp(1, 10);
    }
    final avg = validRatings.values.fold<int>(0, (s, v) => s + v) /
        validRatings.length;
    final progressScore = (avg * 10).round().clamp(10, 100);

    final assessment = CoachPerformanceAssessment(
      id: 'assess_${DateTime.now().microsecondsSinceEpoch}',
      date: DateTime.now(),
      coachId: coachId,
      coachName: coachName,
      focusArea: focusArea.trim(),
      progressScore: progressScore,
      aspectRatings: validRatings,
      feedback: feedback.trim(),
    );

    final updatedStudents = _data.students.map((s) {
      if (s.id != studentId) return s;
      return AcademyStudent(
        id: s.id,
        academyId: s.academyId,
        name: s.name,
        phone: s.phone,
        email: s.email,
        ageGroup: s.ageGroup,
        skillLevel: s.skillLevel,
        branchId: s.branchId,
        branchName: s.branchName,
        batchId: s.batchId,
        batchName: s.batchName,
        assignedCoachId: s.assignedCoachId,
        assignedCoachName: s.assignedCoachName,
        enrollmentStatus: s.enrollmentStatus,
        paymentStatus: s.paymentStatus,
        monthlyFeeInr: s.monthlyFeeInr,
        joinedAt: s.joinedAt,
        academyNotes: s.academyNotes,
        attendanceHistory: s.attendanceHistory,
        coachAssessments: [assessment, ...s.coachAssessments],
      );
    }).toList();

    _data = _withUpdatedData(students: updatedStudents);
    return Success(_data);
  }
}
