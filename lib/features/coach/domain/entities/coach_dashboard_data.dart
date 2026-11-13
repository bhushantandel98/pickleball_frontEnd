import 'package:equatable/equatable.dart';

/// Filter context for the Coach Dashboard.
enum CoachContextType {
  all,
  personal,
  academy,
}

/// Origin context of a coaching session, task, or summary.
enum CoachSessionContext {
  personal,
  academy,
}

/// Lifecycle status of an upcoming coaching session.
enum CoachSessionStatus {
  confirmed,
  pendingApproval,
  scheduled,
  completed,
  cancelled,
}

/// Category of a pending coach action or notification item.
enum CoachPendingTaskType {
  bookingApproval,
  academyInvitation,
  rescheduleRequest,
  sessionNotes,
}

/// Represents an accepted academy affiliation and the branches assigned to the coach.
class AcademyAffiliationSummary extends Equatable {
  final String academyId;
  final String academyName;
  final List<AssignedBranchSummary> assignedBranches;

  const AcademyAffiliationSummary({
    required this.academyId,
    required this.academyName,
    required this.assignedBranches,
  });

  @override
  List<Object?> get props => [academyId, academyName, assignedBranches];
}

/// Represents an academy branch assigned to the coach under an accepted affiliation.
class AssignedBranchSummary extends Equatable {
  final String branchId;
  final String branchName;
  final String city;

  const AssignedBranchSummary({
    required this.branchId,
    required this.branchName,
    required this.city,
  });

  @override
  List<Object?> get props => [branchId, branchName, city];
}

/// Represents an upcoming personal coaching or assigned academy batch session.
class CoachSessionItem extends Equatable {
  final String id;
  final String title;
  final String sessionType;
  final String dateLabel;
  final String timeRange;
  final DateTime dateTime;
  final String venueOrBranchName;
  final CoachSessionContext contextType;
  final String? academyId;
  final String? academyName;
  final String? branchId;
  final CoachSessionStatus status;
  final int participantCount;

  /// True when the session belongs to an official academy schedule
  /// (read-only for the coach on the dashboard).
  final bool isAcademyManaged;

  const CoachSessionItem({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.dateLabel,
    required this.timeRange,
    required this.dateTime,
    required this.venueOrBranchName,
    required this.contextType,
    this.academyId,
    this.academyName,
    this.branchId,
    required this.status,
    required this.participantCount,
    this.isAcademyManaged = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        sessionType,
        dateLabel,
        timeRange,
        dateTime,
        venueOrBranchName,
        contextType,
        academyId,
        academyName,
        branchId,
        status,
        participantCount,
        isAcademyManaged,
      ];
}

/// Personal coaching player metrics, kept strictly separate from academy players.
class PersonalPlayerSummary extends Equatable {
  final int activePrivatePlayers;
  final int activeGroupPlayers;
  final int completedSessionsThisMonth;
  final int newInquiriesCount;

  const PersonalPlayerSummary({
    required this.activePrivatePlayers,
    required this.activeGroupPlayers,
    required this.completedSessionsThisMonth,
    required this.newInquiriesCount,
  });

  int get totalPersonalPlayers => activePrivatePlayers + activeGroupPlayers;

  @override
  List<Object?> get props => [
        activePrivatePlayers,
        activeGroupPlayers,
        completedSessionsThisMonth,
        newInquiriesCount,
      ];
}

/// Academy player metrics scoped to an accepted academy and assigned branch.
class AcademyPlayerSummary extends Equatable {
  final String academyId;
  final String academyName;
  final String branchId;
  final String branchName;
  final int assignedBatchesCount;
  final int totalAssignedPlayers;
  final double averageAttendancePercent;

  const AcademyPlayerSummary({
    required this.academyId,
    required this.academyName,
    required this.branchId,
    required this.branchName,
    required this.assignedBatchesCount,
    required this.totalAssignedPlayers,
    required this.averageAttendancePercent,
  });

  @override
  List<Object?> get props => [
        academyId,
        academyName,
        branchId,
        branchName,
        assignedBatchesCount,
        totalAssignedPlayers,
        averageAttendancePercent,
      ];
}

/// Pending action item requiring coach attention.
class CoachPendingTask extends Equatable {
  final String id;
  final String title;
  final String description;
  final CoachPendingTaskType type;
  final CoachSessionContext contextType;
  final String? academyId;
  final String? academyName;
  final String? branchId;
  final String dueOrCreatedLabel;
  final bool isUrgent;

  const CoachPendingTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.contextType,
    this.academyId,
    this.academyName,
    this.branchId,
    required this.dueOrCreatedLabel,
    this.isUrgent = false,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        type,
        contextType,
        academyId,
        academyName,
        branchId,
        dueOrCreatedLabel,
        isUrgent,
      ];
}

/// Personal coaching finance summary, kept strictly separate from academy finances.
class PersonalFinanceSummary extends Equatable {
  final double thisMonthEarnings;
  final double pendingPayout;
  final int completedPaidSessions;
  final String currencySymbol;

  const PersonalFinanceSummary({
    required this.thisMonthEarnings,
    required this.pendingPayout,
    required this.completedPaidSessions,
    this.currencySymbol = '₹',
  });

  @override
  List<Object?> get props => [
        thisMonthEarnings,
        pendingPayout,
        completedPaidSessions,
        currencySymbol,
      ];
}

/// Permitted coach-level finance summary for an accepted academy.
/// Does not expose unauthorized academy gross revenue, tuition pools, or other coaches' payouts.
class AcademyFinanceSummary extends Equatable {
  final String academyId;
  final String academyName;
  final String? branchId;
  final String? branchName;
  final double permittedPayoutThisMonth;
  final double pendingDisbursement;
  final String payoutModelLabel;
  final String currencySymbol;

  const AcademyFinanceSummary({
    required this.academyId,
    required this.academyName,
    this.branchId,
    this.branchName,
    required this.permittedPayoutThisMonth,
    required this.pendingDisbursement,
    required this.payoutModelLabel,
    this.currencySymbol = '₹',
  });

  @override
  List<Object?> get props => [
        academyId,
        academyName,
        branchId,
        branchName,
        permittedPayoutThisMonth,
        pendingDisbursement,
        payoutModelLabel,
        currencySymbol,
      ];
}

/// Active context filter state for the Coach Dashboard.
class CoachDashboardFilter extends Equatable {
  final CoachContextType contextType;
  final String? selectedAcademyId;
  final String? selectedBranchId;

  const CoachDashboardFilter({
    this.contextType = CoachContextType.all,
    this.selectedAcademyId,
    this.selectedBranchId,
  });

  CoachDashboardFilter copyWith({
    CoachContextType? contextType,
    String? selectedAcademyId,
    bool clearAcademy = false,
    String? selectedBranchId,
    bool clearBranch = false,
  }) {
    return CoachDashboardFilter(
      contextType: contextType ?? this.contextType,
      selectedAcademyId:
          clearAcademy ? null : (selectedAcademyId ?? this.selectedAcademyId),
      selectedBranchId:
          clearBranch ? null : (selectedBranchId ?? this.selectedBranchId),
    );
  }

  @override
  List<Object?> get props => [contextType, selectedAcademyId, selectedBranchId];
}

/// Complete aggregated Coach Dashboard payload.
class CoachDashboardData extends Equatable {
  final String coachId;
  final String coachName;
  final String certificationLabel;
  final List<AcademyAffiliationSummary> acceptedAffiliations;
  final List<CoachSessionItem> upcomingSessions;
  final PersonalPlayerSummary? personalPlayerSummary;
  final List<AcademyPlayerSummary> academyPlayerSummaries;
  final List<CoachPendingTask> pendingTasks;
  final PersonalFinanceSummary? personalFinanceSummary;
  final List<AcademyFinanceSummary> academyFinanceSummaries;

  const CoachDashboardData({
    required this.coachId,
    required this.coachName,
    required this.certificationLabel,
    required this.acceptedAffiliations,
    required this.upcomingSessions,
    this.personalPlayerSummary,
    required this.academyPlayerSummaries,
    required this.pendingTasks,
    this.personalFinanceSummary,
    required this.academyFinanceSummaries,
  });

  bool get isCompletelyEmpty =>
      upcomingSessions.isEmpty &&
      pendingTasks.isEmpty &&
      personalPlayerSummary == null &&
      academyPlayerSummaries.isEmpty &&
      personalFinanceSummary == null &&
      academyFinanceSummaries.isEmpty;

  @override
  List<Object?> get props => [
        coachId,
        coachName,
        certificationLabel,
        acceptedAffiliations,
        upcomingSessions,
        personalPlayerSummary,
        academyPlayerSummaries,
        pendingTasks,
        personalFinanceSummary,
        academyFinanceSummaries,
      ];
}
