import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

/// Skill levels for academy batches (non-DUPR).
enum BatchSkillLevel {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advanced('Advanced'),
  pro('Pro');

  final String label;
  const BatchSkillLevel(this.label);
}

/// Affiliation status between an Academy and a Coach.
/// Coaches must accept an invitation before becoming active; academies cannot
/// force-activate an affiliation or access a coach's personal coaching data.
enum CoachAffiliationStatus {
  pendingAcceptance('Pending Coach Acceptance'),
  accepted('Accepted'),
  declined('Declined'),
  revoked('Revoked');

  final String label;
  const CoachAffiliationStatus(this.label);
}

/// Student enrollment lifecycle status inside an Academy program/batch.
enum EnrollmentRequestStatus {
  pending('Pending Review'),
  waitlisted('Waitlisted'),
  approved('Approved'),
  declined('Declined');

  final String label;
  const EnrollmentRequestStatus(this.label);
}

/// Academy tuition payment status (strictly separate from coach personal fees).
enum TuitionFeeStatus {
  paid('Paid'),
  pending('Pending'),
  overdue('Overdue');

  final String label;
  const TuitionFeeStatus(this.label);
}

/// Top-level Academy organization metadata.
class AcademyProfileSummary extends Equatable {
  final String academyId;
  final String academyName;
  final String ownerName;
  final String primaryCity;
  final String contactEmail;

  const AcademyProfileSummary({
    required this.academyId,
    required this.academyName,
    required this.ownerName,
    required this.primaryCity,
    required this.contactEmail,
  });

  @override
  List<Object?> get props => [
        academyId,
        academyName,
        ownerName,
        primaryCity,
        contactEmail,
      ];
}

/// A physical branch facility owned/operated by the Academy.
class AcademyBranch extends Equatable {
  final String id;
  final String academyId;
  final String name;
  final String contactPerson;
  final String city;
  final String address;
  final String operatingHours;
  final int courtCount;
  final String contactPhone;
  final bool isActive;

  const AcademyBranch({
    required this.id,
    required this.academyId,
    required this.name,
    this.contactPerson = '',
    this.city = '',
    required this.address,
    this.operatingHours = '',
    this.courtCount = 0,
    this.contactPhone = '',
    this.isActive = true,
  });

  AcademyBranch copyWith({
    String? name,
    String? contactPerson,
    String? city,
    String? address,
    String? operatingHours,
    int? courtCount,
    String? contactPhone,
    bool? isActive,
  }) {
    return AcademyBranch(
      id: id,
      academyId: academyId,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      city: city ?? this.city,
      address: address ?? this.address,
      operatingHours: operatingHours ?? this.operatingHours,
      courtCount: courtCount ?? this.courtCount,
      contactPhone: contactPhone ?? this.contactPhone,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        name,
        contactPerson,
        city,
        address,
        operatingHours,
        courtCount,
        contactPhone,
        isActive,
      ];
}

/// An academy-owned coaching program (curriculum & tuition fee).
class AcademyProgram extends Equatable {
  final String id;
  final String academyId;
  final String branchId;
  final String branchName;
  final String title;
  final String skillLevel;
  final String ageGroup;
  final String description;
  final double monthlyTuitionInr;
  final bool isActive;

  const AcademyProgram({
    required this.id,
    required this.academyId,
    required this.branchId,
    required this.branchName,
    required this.title,
    required this.skillLevel,
    required this.ageGroup,
    required this.description,
    required this.monthlyTuitionInr,
    this.isActive = true,
  });

  AcademyProgram copyWith({
    String? title,
    String? skillLevel,
    String? ageGroup,
    String? description,
    double? monthlyTuitionInr,
    bool? isActive,
  }) {
    return AcademyProgram(
      id: id,
      academyId: academyId,
      branchId: branchId,
      branchName: branchName,
      title: title ?? this.title,
      skillLevel: skillLevel ?? this.skillLevel,
      ageGroup: ageGroup ?? this.ageGroup,
      description: description ?? this.description,
      monthlyTuitionInr: monthlyTuitionInr ?? this.monthlyTuitionInr,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        branchId,
        branchName,
        title,
        skillLevel,
        ageGroup,
        description,
        monthlyTuitionInr,
        isActive,
      ];
}

/// A scheduled training batch within a specific Academy branch.
class AcademyBatch extends Equatable {
  final String id;
  final String academyId;
  final String programId;
  final String programTitle;
  final String branchId;
  final String branchName;
  final String name;
  final BatchSkillLevel skillLevel;
  final List<String> daysOfWeek;
  final String startTime;
  final String endTime;
  final String scheduleLabel;
  final int capacity;
  final int enrolledCount;
  final String? assignedCoachId;
  final String? assignedCoachName;

  const AcademyBatch({
    required this.id,
    required this.academyId,
    this.programId = '',
    this.programTitle = '',
    required this.branchId,
    required this.branchName,
    required this.name,
    this.skillLevel = BatchSkillLevel.beginner,
    this.daysOfWeek = const ['Mon', 'Wed', 'Fri'],
    this.startTime = '06:00 PM',
    this.endTime = '07:30 PM',
    required this.scheduleLabel,
    required this.capacity,
    required this.enrolledCount,
    this.assignedCoachId,
    this.assignedCoachName,
  });

  bool get isFull => enrolledCount >= capacity;
  int get availableSeats => (capacity - enrolledCount).clamp(0, capacity);

  AcademyBatch copyWith({
    String? branchId,
    String? branchName,
    String? name,
    BatchSkillLevel? skillLevel,
    List<String>? daysOfWeek,
    String? startTime,
    String? endTime,
    String? scheduleLabel,
    int? capacity,
    int? enrolledCount,
    String? assignedCoachId,
    String? assignedCoachName,
    bool clearAssignedCoach = false,
  }) {
    return AcademyBatch(
      id: id,
      academyId: academyId,
      programId: programId,
      programTitle: programTitle,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      name: name ?? this.name,
      skillLevel: skillLevel ?? this.skillLevel,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      scheduleLabel: scheduleLabel ?? this.scheduleLabel,
      capacity: capacity ?? this.capacity,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      assignedCoachId: clearAssignedCoach
          ? null
          : (assignedCoachId ?? this.assignedCoachId),
      assignedCoachName: clearAssignedCoach
          ? null
          : (assignedCoachName ?? this.assignedCoachName),
    );
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        programId,
        programTitle,
        branchId,
        branchName,
        name,
        skillLevel,
        daysOfWeek,
        startTime,
        endTime,
        scheduleLabel,
        capacity,
        enrolledCount,
        assignedCoachId,
        assignedCoachName,
      ];
}

/// Coach affiliation & branch assignment owned by the Academy.
class AcademyCoachAffiliation extends Equatable {
  final String id;
  final String academyId;
  final String coachId;
  final String coachName;
  final String coachContact;
  final String specialization;
  final List<String> assignedBranchIds;
  final List<String> assignedBranchNames;
  final bool canModifyOfficialSchedule;
  final CoachAffiliationStatus status;
  final DateTime invitedAt;

  const AcademyCoachAffiliation({
    required this.id,
    required this.academyId,
    required this.coachId,
    required this.coachName,
    required this.coachContact,
    required this.specialization,
    required this.assignedBranchIds,
    required this.assignedBranchNames,
    this.canModifyOfficialSchedule = false,
    required this.status,
    required this.invitedAt,
  });

  AcademyCoachAffiliation copyWith({
    List<String>? assignedBranchIds,
    List<String>? assignedBranchNames,
    bool? canModifyOfficialSchedule,
    CoachAffiliationStatus? status,
  }) {
    return AcademyCoachAffiliation(
      id: id,
      academyId: academyId,
      coachId: coachId,
      coachName: coachName,
      coachContact: coachContact,
      specialization: specialization,
      assignedBranchIds: assignedBranchIds ?? this.assignedBranchIds,
      assignedBranchNames: assignedBranchNames ?? this.assignedBranchNames,
      canModifyOfficialSchedule:
          canModifyOfficialSchedule ?? this.canModifyOfficialSchedule,
      status: status ?? this.status,
      invitedAt: invitedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        coachId,
        coachName,
        coachContact,
        specialization,
        assignedBranchIds,
        assignedBranchNames,
        canModifyOfficialSchedule,
        status,
        invitedAt,
      ];
}

/// Student enrollment & tuition fee record scoped to an Academy branch/program/batch.
class AcademyEnrollmentRecord extends Equatable {
  final String id;
  final String academyId;
  final String branchId;
  final String branchName;
  final String programId;
  final String programTitle;
  final String batchId;
  final String batchName;
  final String studentName;
  final String studentContact;
  final String? guardianName;
  final EnrollmentRequestStatus status;
  final int? waitlistPosition;
  final TuitionFeeStatus feeStatus;
  final double tuitionAmountInr;
  final DateTime requestedAt;

  const AcademyEnrollmentRecord({
    required this.id,
    required this.academyId,
    required this.branchId,
    required this.branchName,
    required this.programId,
    required this.programTitle,
    required this.batchId,
    required this.batchName,
    required this.studentName,
    required this.studentContact,
    this.guardianName,
    required this.status,
    this.waitlistPosition,
    required this.feeStatus,
    required this.tuitionAmountInr,
    required this.requestedAt,
  });

  AcademyEnrollmentRecord copyWith({
    EnrollmentRequestStatus? status,
    int? waitlistPosition,
    bool clearWaitlistPosition = false,
    TuitionFeeStatus? feeStatus,
  }) {
    return AcademyEnrollmentRecord(
      id: id,
      academyId: academyId,
      branchId: branchId,
      branchName: branchName,
      programId: programId,
      programTitle: programTitle,
      batchId: batchId,
      batchName: batchName,
      studentName: studentName,
      studentContact: studentContact,
      guardianName: guardianName,
      status: status ?? this.status,
      waitlistPosition: clearWaitlistPosition
          ? null
          : (waitlistPosition ?? this.waitlistPosition),
      feeStatus: feeStatus ?? this.feeStatus,
      tuitionAmountInr: tuitionAmountInr,
      requestedAt: requestedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        academyId,
        branchId,
        branchName,
        programId,
        programTitle,
        batchId,
        batchName,
        studentName,
        studentContact,
        guardianName,
        status,
        waitlistPosition,
        feeStatus,
        tuitionAmountInr,
        requestedAt,
      ];
}

/// Searchable registered coach candidate for Academy connection requests.
class CoachDirectoryCandidate extends Equatable {
  final String coachId;
  final String name;
  final String mobileNumber;
  final String specialization;
  final int experienceYears;
  final double rating;
  final String city;
  final String bio;

  const CoachDirectoryCandidate({
    required this.coachId,
    required this.name,
    required this.mobileNumber,
    required this.specialization,
    required this.experienceYears,
    required this.rating,
    required this.city,
    required this.bio,
  });

  @override
  List<Object?> get props => [
        coachId,
        name,
        mobileNumber,
        specialization,
        experienceYears,
        rating,
        city,
        bio,
      ];
}

/// Attendance entry for an academy student's session history.
class StudentAttendanceEntry extends Equatable {
  final String id;
  final DateTime date;
  final String batchName;
  final String status;
  final String markedBy;

  const StudentAttendanceEntry({
    required this.id,
    required this.date,
    required this.batchName,
    required this.status,
    required this.markedBy,
  });

  @override
  List<Object?> get props => [id, date, batchName, status, markedBy];
}

/// Configurable performance aspect used by coaches to rate players (1–10 scale).
class PerformanceAspectConfig extends Equatable {
  final String id;
  final String label;
  final String category;

  const PerformanceAspectConfig({
    required this.id,
    required this.label,
    required this.category,
  });

  @override
  List<Object?> get props => [id, label, category];
}

/// Coach-recorded performance assessment and progress feedback for a student.
class CoachPerformanceAssessment extends Equatable {
  final String id;
  final DateTime date;
  final String coachId;
  final String coachName;
  final String focusArea;
  final int progressScore;
  final Map<String, int> aspectRatings;
  final String feedback;

  const CoachPerformanceAssessment({
    required this.id,
    required this.date,
    required this.coachId,
    required this.coachName,
    required this.focusArea,
    required this.progressScore,
    this.aspectRatings = const {},
    required this.feedback,
  });

  double get overallRating {
    if (aspectRatings.isEmpty) return progressScore / 10.0;
    final total = aspectRatings.values.fold<int>(0, (sum, v) => sum + v);
    return total / aspectRatings.length;
  }

  @override
  List<Object?> get props => [
        id,
        date,
        coachId,
        coachName,
        focusArea,
        progressScore,
        aspectRatings,
        feedback,
      ];
}

/// Student profile within an Academy, clearly separating academy-entered data
/// from coach-recorded performance assessments.
class AcademyStudent extends Equatable {
  final String id;
  final String academyId;
  final String name;
  final String phone;
  final String email;
  final String ageGroup;
  final BatchSkillLevel skillLevel;
  final String branchId;
  final String branchName;
  final String batchId;
  final String batchName;
  final String? assignedCoachId;
  final String? assignedCoachName;
  final EnrollmentRequestStatus enrollmentStatus;
  final TuitionFeeStatus paymentStatus;
  final double monthlyFeeInr;
  final DateTime joinedAt;
  final String? academyNotes;
  final List<StudentAttendanceEntry> attendanceHistory;
  final List<CoachPerformanceAssessment> coachAssessments;

  const AcademyStudent({
    required this.id,
    required this.academyId,
    required this.name,
    required this.phone,
    required this.email,
    required this.ageGroup,
    required this.skillLevel,
    required this.branchId,
    required this.branchName,
    required this.batchId,
    required this.batchName,
    this.assignedCoachId,
    this.assignedCoachName,
    required this.enrollmentStatus,
    required this.paymentStatus,
    required this.monthlyFeeInr,
    required this.joinedAt,
    this.academyNotes,
    this.attendanceHistory = const [],
    this.coachAssessments = const [],
  });

  @override
  List<Object?> get props => [
        id,
        academyId,
        name,
        phone,
        email,
        ageGroup,
        skillLevel,
        branchId,
        branchName,
        batchId,
        batchName,
        assignedCoachId,
        assignedCoachName,
        enrollmentStatus,
        paymentStatus,
        monthlyFeeInr,
        joinedAt,
        academyNotes,
        attendanceHistory,
        coachAssessments,
      ];
}

/// Manageable Academy Staff member record for Academy Admin governance.
class AcademyStaffMember extends Equatable {
  final String staffId;
  final String userId;
  final String academyId;
  final String name;
  final String email;
  final String phone;
  final String roleTitle;
  final List<String> assignedBranchIds;
  final List<String> assignedBranchNames;
  final Set<AcademyStaffPermission> permissions;
  final bool isActive;
  final DateTime assignedAt;

  const AcademyStaffMember({
    required this.staffId,
    required this.userId,
    required this.academyId,
    required this.name,
    required this.email,
    required this.phone,
    required this.roleTitle,
    required this.assignedBranchIds,
    required this.assignedBranchNames,
    required this.permissions,
    this.isActive = true,
    required this.assignedAt,
  });

  AcademyStaffMember copyWith({
    String? name,
    String? email,
    String? phone,
    String? roleTitle,
    List<String>? assignedBranchIds,
    List<String>? assignedBranchNames,
    Set<AcademyStaffPermission>? permissions,
    bool? isActive,
  }) {
    return AcademyStaffMember(
      staffId: staffId,
      userId: userId,
      academyId: academyId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      roleTitle: roleTitle ?? this.roleTitle,
      assignedBranchIds: assignedBranchIds ?? this.assignedBranchIds,
      assignedBranchNames: assignedBranchNames ?? this.assignedBranchNames,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      assignedAt: assignedAt,
    );
  }

  @override
  List<Object?> get props => [
        staffId,
        userId,
        academyId,
        name,
        email,
        phone,
        roleTitle,
        assignedBranchIds,
        assignedBranchNames,
        permissions,
        isActive,
        assignedAt,
      ];
}

/// Attendance trend data point for dashboard visualization.
class AttendanceTrendPoint extends Equatable {
  final String label;
  final double attendanceRate;

  const AttendanceTrendPoint({
    required this.label,
    required this.attendanceRate,
  });

  @override
  List<Object?> get props => [label, attendanceRate];
}

/// Aggregated Academy workspace data payload.
class AcademyWorkspaceData extends Equatable {
  final AcademyProfileSummary profile;
  final List<AcademyBranch> branches;
  final List<AcademyProgram> programs;
  final List<AcademyBatch> batches;
  final List<AcademyCoachAffiliation> coachAffiliations;
  final List<AcademyEnrollmentRecord> enrollments;
  final List<CoachDirectoryCandidate> coachDirectory;
  final List<AcademyStudent> students;
  final List<AcademyStaffMember> staffMembers;
  final List<AttendanceTrendPoint> attendanceTrends;
  final List<PerformanceAspectConfig> performanceAspects;

  const AcademyWorkspaceData({
    required this.profile,
    required this.branches,
    this.programs = const [],
    required this.batches,
    required this.coachAffiliations,
    required this.enrollments,
    this.coachDirectory = const [],
    this.students = const [],
    this.staffMembers = const [],
    this.attendanceTrends = const [],
    this.performanceAspects = const [],
  });

  @override
  List<Object?> get props => [
        profile,
        branches,
        programs,
        batches,
        coachAffiliations,
        enrollments,
        coachDirectory,
        students,
        staffMembers,
        attendanceTrends,
        performanceAspects,
      ];
}
