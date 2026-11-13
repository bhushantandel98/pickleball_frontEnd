import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_calendar.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/coach_calendar_repository.dart';

/// In-memory mock implementation of [CoachCalendarRepository] for Phase 3 Feature 3.3.
class MockCoachCalendarRepository implements CoachCalendarRepository {
  final bool shouldFail;
  final bool simulateEmpty;
  CoachCalendarData? _data;

  MockCoachCalendarRepository({
    this.shouldFail = false,
    this.simulateEmpty = false,
    CoachCalendarData? initialData,
    DateTime? referenceDate,
  }) : _data = initialData ??
            (simulateEmpty
                ? const CoachCalendarData(
                    coachId: 'coach_001',
                    acceptedAffiliations: [],
                    sessions: [],
                    blockedTimes: [],
                    personalAvailability: [],
                  )
                : _buildDefaultData(referenceDate ?? DateTime.now()));

  static CoachCalendarData _buildDefaultData(DateTime ref) {
    final baseDay = DateTime(ref.year, ref.month, ref.day);

    return CoachCalendarData(
      coachId: 'coach_001',
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
      sessions: [
        // Personal morning session today
        CoachCalendarSession(
          id: 'cal_p_001',
          title: 'Third-Shot Drop & Footwork (1-on-1)',
          sessionType: 'Personal 1-on-1',
          contextType: CalendarEntryContext.personal,
          startTime: baseDay.add(const Duration(hours: 7)),
          endTime: baseDay.add(const Duration(hours: 8)),
          venueOrBranchName: 'Grand Slam Pickleball Arena, Bandra',
          statusLabel: 'Confirmed',
          participantCount: 1,
          canModifySchedule: true,
        ),
        // Personal evening session overlapping Academy Batch today (18:30-19:30 vs 19:00-20:30)
        CoachCalendarSession(
          id: 'cal_p_002',
          title: 'Serve & Spin Clinic — Ananya Rao',
          sessionType: 'Personal 1-on-1',
          contextType: CalendarEntryContext.personal,
          startTime: baseDay.add(const Duration(hours: 18, minutes: 30)),
          endTime: baseDay.add(const Duration(hours: 19, minutes: 30)),
          venueOrBranchName: 'Dink & Smash Club, Juhu',
          statusLabel: 'Confirmed',
          participantCount: 1,
          canModifySchedule: true,
        ),
        // Academy official schedule today (read-only)
        CoachCalendarSession(
          id: 'cal_a_001',
          title: 'Intermediate Doubles Tactics — Evening Batch B',
          sessionType: 'Academy Batch',
          contextType: CalendarEntryContext.academy,
          startTime: baseDay.add(const Duration(hours: 19)),
          endTime: baseDay.add(const Duration(hours: 20, minutes: 30)),
          venueOrBranchName: 'Apex Pickleball Academy • Andheri West Branch',
          academyId: 'acad_001',
          academyName: 'Apex Pickleball Academy',
          branchId: 'branch_andheri',
          branchName: 'Andheri West Branch',
          batchName: 'Evening Batch B',
          statusLabel: 'Scheduled',
          participantCount: 12,
          canModifySchedule: false,
        ),
        // Academy session tomorrow at Bandra branch
        CoachCalendarSession(
          id: 'cal_a_002',
          title: 'Junior High-Performance Morning Squad',
          sessionType: 'Academy Batch',
          contextType: CalendarEntryContext.academy,
          startTime: baseDay.add(const Duration(days: 1, hours: 8, minutes: 30)),
          endTime: baseDay.add(const Duration(days: 1, hours: 10)),
          venueOrBranchName: 'Apex Pickleball Academy • Bandra West Branch',
          academyId: 'acad_001',
          academyName: 'Apex Pickleball Academy',
          branchId: 'branch_bandra',
          branchName: 'Bandra West Branch',
          batchName: 'Junior HP Squad',
          statusLabel: 'Confirmed',
          participantCount: 10,
          canModifySchedule: false,
        ),
        // Academy session in 2 days at Smashers Elite Academy (Powai)
        CoachCalendarSession(
          id: 'cal_a_003',
          title: 'Weekend Serve & Return Clinic',
          sessionType: 'Academy Batch',
          contextType: CalendarEntryContext.academy,
          startTime: baseDay.add(const Duration(days: 2, hours: 16)),
          endTime: baseDay.add(const Duration(days: 2, hours: 17, minutes: 30)),
          venueOrBranchName: 'Smashers Elite Academy • Powai Lakeview Branch',
          academyId: 'acad_002',
          academyName: 'Smashers Elite Academy',
          branchId: 'branch_powai',
          branchName: 'Powai Lakeview Branch',
          batchName: 'Weekend Clinic',
          statusLabel: 'Scheduled',
          participantCount: 8,
          canModifySchedule: false,
        ),
        // Personal group session in 4 days
        CoachCalendarSession(
          id: 'cal_p_003',
          title: 'Semi-Private Doubles Strategy',
          sessionType: 'Personal Group',
          contextType: CalendarEntryContext.personal,
          startTime: baseDay.add(const Duration(days: 4, hours: 7)),
          endTime: baseDay.add(const Duration(days: 4, hours: 8, minutes: 30)),
          venueOrBranchName: 'Grand Slam Pickleball Arena, Bandra',
          statusLabel: 'Confirmed',
          participantCount: 2,
          canModifySchedule: true,
        ),
      ],
      blockedTimes: [
        CoachBlockedTime(
          id: 'blk_001',
          title: 'Travel & Equipment Maintenance',
          startTime: baseDay.add(const Duration(days: 1, hours: 13)),
          endTime: baseDay.add(const Duration(days: 1, hours: 15)),
          reason: 'Personal transit buffer between Bandra and Powai',
        ),
      ],
      personalAvailability: const [
        PersonalAvailabilityWindow(
          id: 'avl_001',
          dayOfWeek: DateTime.monday,
          dayLabel: 'Monday',
          startTimeLabel: '06:30',
          endTimeLabel: '09:30',
          locationNote: 'Bandra & Juhu Personal Venues',
          isActive: true,
        ),
        PersonalAvailabilityWindow(
          id: 'avl_002',
          dayOfWeek: DateTime.wednesday,
          dayLabel: 'Wednesday',
          startTimeLabel: '16:30',
          endTimeLabel: '18:30',
          locationNote: 'Grand Slam Arena, Bandra',
          isActive: true,
        ),
        PersonalAvailabilityWindow(
          id: 'avl_003',
          dayOfWeek: DateTime.saturday,
          dayLabel: 'Saturday',
          startTimeLabel: '07:00',
          endTimeLabel: '10:30',
          locationNote: 'Andheri West Courts',
          isActive: true,
        ),
      ],
    );
  }

  @override
  Future<Result<CoachCalendarData>> getCalendarData({String? coachId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load coach calendar data.'),
      );
    }

    return Success(_data!);
  }

  @override
  Future<Result<CoachCalendarData>> addBlockedTime({
    required String coachId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to add blocked time.'),
      );
    }
    if (title.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Blocked time title is required.'),
      );
    }
    if (!endTime.isAfter(startTime)) {
      return const FailureResult(
        ValidationFailure(message: 'End time must be after start time.'),
      );
    }

    final current = _data!;
    final item = CoachBlockedTime(
      id: 'blk_${DateTime.now().millisecondsSinceEpoch}',
      title: title.trim(),
      startTime: startTime,
      endTime: endTime,
      reason: reason?.trim().isEmpty == true ? null : reason?.trim(),
    );

    _data = current.copyWith(
      blockedTimes: [...current.blockedTimes, item],
    );
    return Success(_data!);
  }

  @override
  Future<Result<CoachCalendarData>> removeBlockedTime({
    required String coachId,
    required String blockedTimeId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to remove blocked time.'),
      );
    }

    final current = _data!;
    _data = current.copyWith(
      blockedTimes: current.blockedTimes
          .where((b) => b.id != blockedTimeId)
          .toList(),
    );
    return Success(_data!);
  }

  @override
  Future<Result<CoachCalendarData>> addAvailabilityWindow({
    required String coachId,
    required PersonalAvailabilityWindow window,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to add availability window.'),
      );
    }
    if (window.startTimeLabel.trim().isEmpty ||
        window.endTimeLabel.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(message: 'Start and end times are required.'),
      );
    }

    final current = _data!;
    final newItem = window.copyWith(
      id: window.id.isEmpty
          ? 'avl_${DateTime.now().millisecondsSinceEpoch}'
          : window.id,
    );
    _data = current.copyWith(
      personalAvailability: [...current.personalAvailability, newItem],
    );
    return Success(_data!);
  }

  @override
  Future<Result<CoachCalendarData>> toggleAvailabilityWindow({
    required String coachId,
    required String windowId,
    required bool isActive,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update availability window.'),
      );
    }

    final current = _data!;
    _data = current.copyWith(
      personalAvailability: current.personalAvailability.map((w) {
        return w.id == windowId ? w.copyWith(isActive: isActive) : w;
      }).toList(),
    );
    return Success(_data!);
  }

  @override
  Future<Result<CoachCalendarData>> removeAvailabilityWindow({
    required String coachId,
    required String windowId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to remove availability window.'),
      );
    }

    final current = _data!;
    _data = current.copyWith(
      personalAvailability: current.personalAvailability
          .where((w) => w.id != windowId)
          .toList(),
    );
    return Success(_data!);
  }
}
