import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/coach_dashboard_repository.dart';

/// In-memory mock implementation of [CoachDashboardRepository] for Phase 3 development.
class MockCoachDashboardRepository implements CoachDashboardRepository {
  final bool shouldFail;
  final bool simulateEmpty;
  final CoachDashboardData? customData;

  const MockCoachDashboardRepository({
    this.shouldFail = false,
    this.simulateEmpty = false,
    this.customData,
  });

  @override
  Future<Result<CoachDashboardData>> getDashboardData({String? coachId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));

    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load coach dashboard data.'),
      );
    }

    if (customData != null) {
      return Success(customData!);
    }

    if (simulateEmpty) {
      return Success(
        CoachDashboardData(
          coachId: coachId ?? 'coach_001',
          coachName: 'Vikram Malhotra',
          certificationLabel: 'IPTPA Level 2 Certified',
          acceptedAffiliations: const [],
          upcomingSessions: const [],
          personalPlayerSummary: null,
          academyPlayerSummaries: const [],
          pendingTasks: const [],
          personalFinanceSummary: null,
          academyFinanceSummaries: const [],
        ),
      );
    }

    final now = DateTime.now();
    final baseDay = DateTime(now.year, now.month, now.day);

    return Success(
      CoachDashboardData(
        coachId: coachId ?? 'coach_001',
        coachName: 'Vikram Malhotra',
        certificationLabel: 'IPTPA Level 2 Certified',
        acceptedAffiliations: const [
          AcademyAffiliationSummary(
            academyId: 'acad_001',
            academyName: 'Apex Pickleball Academy',
            assignedBranches: [
              AssignedBranchSummary(
                branchId: 'branch_andheri',
                branchName: 'Andheri West Branch',
                city: 'Mumbai',
              ),
              AssignedBranchSummary(
                branchId: 'branch_bandra',
                branchName: 'Bandra West Branch',
                city: 'Mumbai',
              ),
            ],
          ),
          AcademyAffiliationSummary(
            academyId: 'acad_002',
            academyName: 'Smashers Elite Academy',
            assignedBranches: [
              AssignedBranchSummary(
                branchId: 'branch_powai',
                branchName: 'Powai Lakeview Branch',
                city: 'Mumbai',
              ),
            ],
          ),
        ],
        upcomingSessions: [
          CoachSessionItem(
            id: 'sess_p_001',
            title: 'Third-Shot Drop & Kitchen Footwork (1-on-1)',
            sessionType: 'Personal 1-on-1',
            dateLabel: 'Today',
            timeRange: '17:30 - 18:30',
            dateTime: baseDay.add(const Duration(hours: 17, minutes: 30)),
            venueOrBranchName: 'Grand Slam Pickleball Arena, Bandra',
            contextType: CoachSessionContext.personal,
            status: CoachSessionStatus.confirmed,
            participantCount: 1,
            isAcademyManaged: false,
          ),
          CoachSessionItem(
            id: 'sess_a_001',
            title: 'Intermediate Doubles Tactics — Evening Batch B',
            sessionType: 'Academy Batch',
            dateLabel: 'Today',
            timeRange: '19:00 - 20:30',
            dateTime: baseDay.add(const Duration(hours: 19)),
            venueOrBranchName: 'Apex Pickleball Academy • Andheri West Branch',
            contextType: CoachSessionContext.academy,
            academyId: 'acad_001',
            academyName: 'Apex Pickleball Academy',
            branchId: 'branch_andheri',
            status: CoachSessionStatus.scheduled,
            participantCount: 12,
            isAcademyManaged: true,
          ),
          CoachSessionItem(
            id: 'sess_p_002',
            title: 'Semi-Private Doubles Strategy',
            sessionType: 'Personal Group',
            dateLabel: 'Tomorrow',
            timeRange: '07:00 - 08:00',
            dateTime: baseDay.add(const Duration(days: 1, hours: 7)),
            venueOrBranchName: 'Dink & Smash Club, Juhu',
            contextType: CoachSessionContext.personal,
            status: CoachSessionStatus.pendingApproval,
            participantCount: 2,
            isAcademyManaged: false,
          ),
          CoachSessionItem(
            id: 'sess_a_002',
            title: 'Junior High-Performance Morning Squad',
            sessionType: 'Academy Batch',
            dateLabel: 'Tomorrow',
            timeRange: '08:30 - 10:00',
            dateTime: baseDay.add(const Duration(days: 1, hours: 8, minutes: 30)),
            venueOrBranchName: 'Apex Pickleball Academy • Bandra West Branch',
            contextType: CoachSessionContext.academy,
            academyId: 'acad_001',
            academyName: 'Apex Pickleball Academy',
            branchId: 'branch_bandra',
            status: CoachSessionStatus.confirmed,
            participantCount: 10,
            isAcademyManaged: true,
          ),
          CoachSessionItem(
            id: 'sess_a_003',
            title: 'Weekend Serve & Return Clinic',
            sessionType: 'Academy Batch',
            dateLabel: 'In 2 days',
            timeRange: '16:00 - 17:30',
            dateTime: baseDay.add(const Duration(days: 2, hours: 16)),
            venueOrBranchName: 'Smashers Elite Academy • Powai Lakeview Branch',
            contextType: CoachSessionContext.academy,
            academyId: 'acad_002',
            academyName: 'Smashers Elite Academy',
            branchId: 'branch_powai',
            status: CoachSessionStatus.scheduled,
            participantCount: 8,
            isAcademyManaged: true,
          ),
        ],
        personalPlayerSummary: const PersonalPlayerSummary(
          activePrivatePlayers: 14,
          activeGroupPlayers: 8,
          completedSessionsThisMonth: 26,
          newInquiriesCount: 3,
        ),
        academyPlayerSummaries: const [
          AcademyPlayerSummary(
            academyId: 'acad_001',
            academyName: 'Apex Pickleball Academy',
            branchId: 'branch_andheri',
            branchName: 'Andheri West Branch',
            assignedBatchesCount: 3,
            totalAssignedPlayers: 34,
            averageAttendancePercent: 91.5,
          ),
          AcademyPlayerSummary(
            academyId: 'acad_001',
            academyName: 'Apex Pickleball Academy',
            branchId: 'branch_bandra',
            branchName: 'Bandra West Branch',
            assignedBatchesCount: 2,
            totalAssignedPlayers: 20,
            averageAttendancePercent: 88.0,
          ),
          AcademyPlayerSummary(
            academyId: 'acad_002',
            academyName: 'Smashers Elite Academy',
            branchId: 'branch_powai',
            branchName: 'Powai Lakeview Branch',
            assignedBatchesCount: 2,
            totalAssignedPlayers: 18,
            averageAttendancePercent: 93.0,
          ),
        ],
        pendingTasks: const [
          CoachPendingTask(
            id: 'task_001',
            title: 'Personal Session Booking Request — Ananya Rao',
            description:
                'Requested 1-on-1 spin & serve clinic on Saturday 07:30 at Grand Slam Arena.',
            type: CoachPendingTaskType.bookingApproval,
            contextType: CoachSessionContext.personal,
            dueOrCreatedLabel: 'Requested 2h ago',
            isUrgent: true,
          ),
          CoachPendingTask(
            id: 'task_002',
            title: 'Academy Affiliation Invitation — Coastal Spin Academy',
            description:
                'Invited to join Worli Seaface Branch as Visiting Senior Coach. Accept or decline from Affiliations.',
            type: CoachPendingTaskType.academyInvitation,
            contextType: CoachSessionContext.academy,
            academyId: 'acad_pending_003',
            academyName: 'Coastal Spin Academy',
            dueOrCreatedLabel: 'Expires in 3 days',
            isUrgent: true,
          ),
          CoachPendingTask(
            id: 'task_003',
            title: 'Reschedule Update — Rohan Deshmukh',
            description:
                'Asked to shift Friday 18:00 private slot to Sunday 08:00 at Dink & Smash Club.',
            type: CoachPendingTaskType.rescheduleRequest,
            contextType: CoachSessionContext.personal,
            dueOrCreatedLabel: 'Requested 5h ago',
          ),
          CoachPendingTask(
            id: 'task_004',
            title: 'Submit Batch Progress Notes — Evening Batch B',
            description:
                'Monthly skill evaluation notes due for 12 assigned players at Andheri West Branch.',
            type: CoachPendingTaskType.sessionNotes,
            contextType: CoachSessionContext.academy,
            academyId: 'acad_001',
            academyName: 'Apex Pickleball Academy',
            branchId: 'branch_andheri',
            dueOrCreatedLabel: 'Due tomorrow',
          ),
        ],
        personalFinanceSummary: const PersonalFinanceSummary(
          thisMonthEarnings: 42500,
          pendingPayout: 8400,
          completedPaidSessions: 26,
        ),
        academyFinanceSummaries: const [
          AcademyFinanceSummary(
            academyId: 'acad_001',
            academyName: 'Apex Pickleball Academy',
            branchId: 'branch_andheri',
            branchName: 'Andheri West Branch',
            permittedPayoutThisMonth: 32000,
            pendingDisbursement: 6400,
            payoutModelLabel: 'Permitted Session Stipend',
          ),
          AcademyFinanceSummary(
            academyId: 'acad_001',
            academyName: 'Apex Pickleball Academy',
            branchId: 'branch_bandra',
            branchName: 'Bandra West Branch',
            permittedPayoutThisMonth: 21000,
            pendingDisbursement: 4200,
            payoutModelLabel: 'Permitted Session Stipend',
          ),
          AcademyFinanceSummary(
            academyId: 'acad_002',
            academyName: 'Smashers Elite Academy',
            branchId: 'branch_powai',
            branchName: 'Powai Lakeview Branch',
            permittedPayoutThisMonth: 18500,
            pendingDisbursement: 3700,
            payoutModelLabel: 'Permitted Monthly Retainer',
          ),
        ],
      ),
    );
  }
}
