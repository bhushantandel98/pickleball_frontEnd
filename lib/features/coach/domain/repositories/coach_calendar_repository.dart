import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_calendar.dart';

/// Repository contract for Coach Calendar & Personal Availability management.
abstract class CoachCalendarRepository {
  Future<Result<CoachCalendarData>> getCalendarData({String? coachId});

  Future<Result<CoachCalendarData>> addBlockedTime({
    required String coachId,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
  });

  Future<Result<CoachCalendarData>> removeBlockedTime({
    required String coachId,
    required String blockedTimeId,
  });

  Future<Result<CoachCalendarData>> addAvailabilityWindow({
    required String coachId,
    required PersonalAvailabilityWindow window,
  });

  Future<Result<CoachCalendarData>> toggleAvailabilityWindow({
    required String coachId,
    required String windowId,
    required bool isActive,
  });

  Future<Result<CoachCalendarData>> removeAvailabilityWindow({
    required String coachId,
    required String windowId,
  });
}
