import 'package:equatable/equatable.dart';

/// Status of an academy enrollment request submitted by a player.
enum AcademyEnrollmentStatus {
  pendingApproval('Pending Academy Approval'),
  approved('Enrolled (Approved)'),
  waitlisted('On Waitlist'),
  rejected('Application Declined'),
  cancelled('Cancelled by Player');

  final String displayName;
  const AcademyEnrollmentStatus(this.displayName);

  bool get isPending => this == AcademyEnrollmentStatus.pendingApproval;
  bool get isWaitlisted => this == AcademyEnrollmentStatus.waitlisted;
  bool get isApproved => this == AcademyEnrollmentStatus.approved;
  bool get isRejected => this == AcademyEnrollmentStatus.rejected;
  bool get isCancelled => this == AcademyEnrollmentStatus.cancelled;
}

/// Status of a coaching inquiry or connection request submitted by a player.
enum CoachInquiryStatus {
  pendingCoachResponse('Awaiting Coach Review'),
  accepted('Inquiry Accepted'),
  declined('Coach Unavailable'),
  cancelled('Cancelled by Player');

  final String displayName;
  const CoachInquiryStatus(this.displayName);

  bool get isPending => this == CoachInquiryStatus.pendingCoachResponse;
  bool get isAccepted => this == CoachInquiryStatus.accepted;
  bool get isDeclined => this == CoachInquiryStatus.declined;
  bool get isCancelled => this == CoachInquiryStatus.cancelled;
}

/// A specific scheduled training batch within an academy program.
class AcademyBatch extends Equatable {
  final String id;
  final String programId;
  final String name;
  final String schedule; // e.g. "Tue, Thu, Sat: 7:00 AM - 8:30 AM"
  final DateTime? startDate;
  final DateTime? endDate;
  final int maxCapacity;
  final int enrolledCount;
  final bool isWaitlistEnabled;
  final int waitlistCount;
  final String instructorName;

  const AcademyBatch({
    required this.id,
    required this.programId,
    required this.name,
    required this.schedule,
    this.startDate,
    this.endDate,
    required this.maxCapacity,
    required this.enrolledCount,
    this.isWaitlistEnabled = false,
    this.waitlistCount = 0,
    required this.instructorName,
  });

  bool get isFull => enrolledCount >= maxCapacity;
  bool get canEnrollDirectly => !isFull;
  bool get canJoinWaitlist => isFull && isWaitlistEnabled;
  bool get isClosed => isFull && !isWaitlistEnabled;

  int get availableSpots => (maxCapacity - enrolledCount).clamp(0, maxCapacity);

  AcademyBatch copyWith({
    String? id,
    String? programId,
    String? name,
    String? schedule,
    DateTime? startDate,
    DateTime? endDate,
    int? maxCapacity,
    int? enrolledCount,
    bool? isWaitlistEnabled,
    int? waitlistCount,
    String? instructorName,
  }) {
    return AcademyBatch(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      name: name ?? this.name,
      schedule: schedule ?? this.schedule,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      enrolledCount: enrolledCount ?? this.enrolledCount,
      isWaitlistEnabled: isWaitlistEnabled ?? this.isWaitlistEnabled,
      waitlistCount: waitlistCount ?? this.waitlistCount,
      instructorName: instructorName ?? this.instructorName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        programId,
        name,
        schedule,
        startDate,
        endDate,
        maxCapacity,
        enrolledCount,
        isWaitlistEnabled,
        waitlistCount,
        instructorName,
      ];
}

/// A structured training or coaching program offered at an academy branch.
class AcademyProgram extends Equatable {
  final String id;
  final String title;
  final String description;
  final String skillLevel; // e.g. "Beginner", "Intermediate (3.0 - 4.0)", "Open"
  final String ageGroup; // e.g. "Junior (U-16)", "Adults (18+)", "All Ages"
  final List<AcademyBatch> batches;

  const AcademyProgram({
    required this.id,
    required this.title,
    required this.description,
    required this.skillLevel,
    required this.ageGroup,
    this.batches = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        skillLevel,
        ageGroup,
        batches,
      ];
}

/// Public representation of an academy branch.
///
/// Per PRD privacy rules, public branch listings only expose permitted information
/// (academy name, branch location, and operating timings). Fees and player rosters are hidden.
class AcademyBranch extends Equatable {
  final String id;
  final String academyId;
  final String academyName;
  final String branchName;
  final String city;
  final String address;
  final String operatingHours; // e.g. "Mon-Sat: 6:00 AM - 9:00 PM"
  final String contactPhone;
  final String contactEmail;
  final String overview;
  final String headCoachName;
  final int courtCount;
  final List<AcademyProgram> programs;

  const AcademyBranch({
    required this.id,
    required this.academyId,
    required this.academyName,
    required this.branchName,
    required this.city,
    required this.address,
    required this.operatingHours,
    this.contactPhone = '',
    this.contactEmail = '',
    this.overview = '',
    this.headCoachName = '',
    this.courtCount = 0,
    this.programs = const [],
  });

  String get fullTitle => '$academyName — $branchName';

  @override
  List<Object?> get props => [
        id,
        academyId,
        academyName,
        branchName,
        city,
        address,
        operatingHours,
        contactPhone,
        contactEmail,
        overview,
        headCoachName,
        courtCount,
        programs,
      ];
}

/// Enrollment request submitted by a player for a specific academy batch.
class AcademyEnrollmentRequest extends Equatable {
  final String id;
  final String branchId;
  final String branchName;
  final String academyName;
  final String programId;
  final String programTitle;
  final String batchId;
  final String batchName;
  final String schedule;
  final String playerName;
  final String playerPhone;
  final String playerEmail;
  final double? playerRating;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String? notes;
  final DateTime requestedAt;
  final AcademyEnrollmentStatus status;
  final bool isWaitlist;
  final int? waitlistPosition;
  final String? rejectionReason;

  const AcademyEnrollmentRequest({
    required this.id,
    required this.branchId,
    required this.branchName,
    required this.academyName,
    required this.programId,
    required this.programTitle,
    required this.batchId,
    required this.batchName,
    required this.schedule,
    required this.playerName,
    required this.playerPhone,
    this.playerEmail = '',
    this.playerRating,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    this.notes,
    required this.requestedAt,
    this.status = AcademyEnrollmentStatus.pendingApproval,
    this.isWaitlist = false,
    this.waitlistPosition,
    this.rejectionReason,
  });

  bool get canCancel =>
      status == AcademyEnrollmentStatus.pendingApproval ||
      status == AcademyEnrollmentStatus.waitlisted;

  AcademyEnrollmentRequest copyWith({
    String? id,
    String? branchId,
    String? branchName,
    String? academyName,
    String? programId,
    String? programTitle,
    String? batchId,
    String? batchName,
    String? schedule,
    String? playerName,
    String? playerPhone,
    String? playerEmail,
    double? playerRating,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? notes,
    DateTime? requestedAt,
    AcademyEnrollmentStatus? status,
    bool? isWaitlist,
    int? waitlistPosition,
    String? rejectionReason,
  }) {
    return AcademyEnrollmentRequest(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      academyName: academyName ?? this.academyName,
      programId: programId ?? this.programId,
      programTitle: programTitle ?? this.programTitle,
      batchId: batchId ?? this.batchId,
      batchName: batchName ?? this.batchName,
      schedule: schedule ?? this.schedule,
      playerName: playerName ?? this.playerName,
      playerPhone: playerPhone ?? this.playerPhone,
      playerEmail: playerEmail ?? this.playerEmail,
      playerRating: playerRating ?? this.playerRating,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      notes: notes ?? this.notes,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      isWaitlist: isWaitlist ?? this.isWaitlist,
      waitlistPosition: waitlistPosition ?? this.waitlistPosition,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  List<Object?> get props => [
        id,
        branchId,
        branchName,
        academyName,
        programId,
        programTitle,
        batchId,
        batchName,
        schedule,
        playerName,
        playerPhone,
        playerEmail,
        playerRating,
        emergencyContactName,
        emergencyContactPhone,
        notes,
        requestedAt,
        status,
        isWaitlist,
        waitlistPosition,
        rejectionReason,
      ];
}

/// A specific coaching service offered by a registered coach.
class CoachService extends Equatable {
  final String id;
  final String name;
  final String description;
  final String duration; // e.g. "60 Min"
  final double fee;
  final String feeDisplay; // e.g. "₹1,500 / hr"

  const CoachService({
    required this.id,
    required this.name,
    required this.description,
    required this.duration,
    required this.fee,
    required this.feeDisplay,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        duration,
        fee,
        feeDisplay,
      ];
}

/// A registered coach discovered by players on the platform.
class CoachItem extends Equatable {
  final String id;
  final String name;
  final String title;
  final String bio;
  final double rating;
  final int reviewCount;
  final String city;
  final int experienceYears;
  final List<String> certifications;
  final List<String> specializations;
  final List<CoachService> services;
  final List<String> affiliations;
  final String availabilitySchedule;

  const CoachItem({
    required this.id,
    required this.name,
    required this.title,
    required this.bio,
    this.rating = 5.0,
    this.reviewCount = 0,
    required this.city,
    required this.experienceYears,
    this.certifications = const [],
    this.specializations = const [],
    this.services = const [],
    this.affiliations = const [],
    required this.availabilitySchedule,
  });

  String get startingFeeDisplay {
    if (services.isEmpty) return 'Fee on inquiry';
    final lowest = services.map((s) => s.fee).reduce((a, b) => a < b ? a : b);
    return 'From ₹${lowest.toInt()} / hr';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        title,
        bio,
        rating,
        reviewCount,
        city,
        experienceYears,
        certifications,
        specializations,
        services,
        affiliations,
        availabilitySchedule,
      ];
}

/// An inquiry / connection request sent to a registered coach by a player.
///
/// Per Coach PRD rules, submitting an inquiry does NOT grant access to any coaching dashboard.
/// Coaching dashboard access is granted strictly by the coach.
class CoachInquiryRequest extends Equatable {
  final String id;
  final String coachId;
  final String coachName;
  final String? serviceId;
  final String? serviceName;
  final String playerName;
  final String playerPhone;
  final String playerEmail;
  final String preferredDays;
  final double? playerRating;
  final String trainingGoal;
  final String message;
  final DateTime submittedAt;
  final CoachInquiryStatus status;
  final String? coachResponseNotes;

  const CoachInquiryRequest({
    required this.id,
    required this.coachId,
    required this.coachName,
    this.serviceId,
    this.serviceName,
    required this.playerName,
    required this.playerPhone,
    this.playerEmail = '',
    required this.preferredDays,
    this.playerRating,
    required this.trainingGoal,
    required this.message,
    required this.submittedAt,
    this.status = CoachInquiryStatus.pendingCoachResponse,
    this.coachResponseNotes,
  });

  bool get canCancel => status == CoachInquiryStatus.pendingCoachResponse;

  CoachInquiryRequest copyWith({
    String? id,
    String? coachId,
    String? coachName,
    String? serviceId,
    String? serviceName,
    String? playerName,
    String? playerPhone,
    String? playerEmail,
    String? preferredDays,
    double? playerRating,
    String? trainingGoal,
    String? message,
    DateTime? submittedAt,
    CoachInquiryStatus? status,
    String? coachResponseNotes,
  }) {
    return CoachInquiryRequest(
      id: id ?? this.id,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      playerName: playerName ?? this.playerName,
      playerPhone: playerPhone ?? this.playerPhone,
      playerEmail: playerEmail ?? this.playerEmail,
      preferredDays: preferredDays ?? this.preferredDays,
      playerRating: playerRating ?? this.playerRating,
      trainingGoal: trainingGoal ?? this.trainingGoal,
      message: message ?? this.message,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      coachResponseNotes: coachResponseNotes ?? this.coachResponseNotes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        coachId,
        coachName,
        serviceId,
        serviceName,
        playerName,
        playerPhone,
        playerEmail,
        preferredDays,
        playerRating,
        trainingGoal,
        message,
        submittedAt,
        status,
        coachResponseNotes,
      ];
}
