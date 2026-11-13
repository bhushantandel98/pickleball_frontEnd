import 'package:equatable/equatable.dart';

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
    required this.city,
    required this.address,
    required this.operatingHours,
    required this.courtCount,
    required this.contactPhone,
    this.isActive = true,
  });

  AcademyBranch copyWith({
    String? name,
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

/// A scheduled training batch within an [AcademyProgram] at a specific branch.
class AcademyBatch extends Equatable {
  final String id;
  final String academyId;
  final String programId;
  final String programTitle;
  final String branchId;
  final String branchName;
  final String name;
  final String scheduleLabel;
  final int capacity;
  final int enrolledCount;
  final String? assignedCoachId;
  final String? assignedCoachName;

  const AcademyBatch({
    required this.id,
    required this.academyId,
    required this.programId,
    required this.programTitle,
    required this.branchId,
    required this.branchName,
    required this.name,
    required this.scheduleLabel,
    required this.capacity,
    required this.enrolledCount,
    this.assignedCoachId,
    this.assignedCoachName,
  });

  bool get isFull => enrolledCount >= capacity;

  AcademyBatch copyWith({
    int? enrolledCount,
    String? assignedCoachId,
    String? assignedCoachName,
  }) {
    return AcademyBatch(
      id: id,
      academyId: academyId,
      programId: programId,
      programTitle: programTitle,
      branchId: branchId,
      branchName: branchName,
      name: name,
      scheduleLabel: scheduleLabel,
      capacity: capacity,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      assignedCoachId: assignedCoachId ?? this.assignedCoachId,
      assignedCoachName: assignedCoachName ?? this.assignedCoachName,
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

/// Aggregated Academy workspace data payload.
class AcademyWorkspaceData extends Equatable {
  final AcademyProfileSummary profile;
  final List<AcademyBranch> branches;
  final List<AcademyProgram> programs;
  final List<AcademyBatch> batches;
  final List<AcademyCoachAffiliation> coachAffiliations;
  final List<AcademyEnrollmentRecord> enrollments;

  const AcademyWorkspaceData({
    required this.profile,
    required this.branches,
    required this.programs,
    required this.batches,
    required this.coachAffiliations,
    required this.enrollments,
  });

  @override
  List<Object?> get props => [
        profile,
        branches,
        programs,
        batches,
        coachAffiliations,
        enrollments,
      ];
}
