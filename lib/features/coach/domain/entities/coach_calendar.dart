import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';

/// Supported calendar display modes for the Coach Calendar.
enum CoachCalendarViewMode {
  day,
  week,
  month,
}

/// Distinguishes personal coaching, academy official schedules, and personal blocked time.
enum CalendarEntryContext {
  personal,
  academy,
  blocked,
}

/// A personal coaching or accepted-academy session on the coach's calendar.
class CoachCalendarSession extends Equatable {
  final String id;
  final String title;
  final String sessionType;
  final CalendarEntryContext contextType;
  final DateTime startTime;
  final DateTime endTime;
  final String venueOrBranchName;
  final String? academyId;
  final String? academyName;
  final String? branchId;
  final String? branchName;
  final String? batchName;
  final String statusLabel;
  final int participantCount;

  /// Official academy schedules are read-only unless explicit schedule-modification
  /// permission has been granted.
  final bool canModifySchedule;

  const CoachCalendarSession({
    required this.id,
    required this.title,
    required this.sessionType,
    required this.contextType,
    required this.startTime,
    required this.endTime,
    required this.venueOrBranchName,
    this.academyId,
    this.academyName,
    this.branchId,
    this.branchName,
    this.batchName,
    required this.statusLabel,
    required this.participantCount,
    this.canModifySchedule = false,
  });

  bool overlapsWith(DateTime otherStart, DateTime otherEnd) {
    return startTime.isBefore(otherEnd) && endTime.isAfter(otherStart);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        sessionType,
        contextType,
        startTime,
        endTime,
        venueOrBranchName,
        academyId,
        academyName,
        branchId,
        branchName,
        batchName,
        statusLabel,
        participantCount,
        canModifySchedule,
      ];
}

/// A personal blocked-time period created by the coach.
class CoachBlockedTime extends Equatable {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? reason;

  const CoachBlockedTime({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.reason,
  });

  bool overlapsWith(DateTime otherStart, DateTime otherEnd) {
    return startTime.isBefore(otherEnd) && endTime.isAfter(otherStart);
  }

  @override
  List<Object?> get props => [id, title, startTime, endTime, reason];
}

/// Personal coaching availability window managed by the coach.
class PersonalAvailabilityWindow extends Equatable {
  final String id;
  final int dayOfWeek;
  final String dayLabel;
  final String startTimeLabel;
  final String endTimeLabel;
  final String locationNote;
  final bool isActive;

  const PersonalAvailabilityWindow({
    required this.id,
    required this.dayOfWeek,
    required this.dayLabel,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.locationNote,
    this.isActive = true,
  });

  PersonalAvailabilityWindow copyWith({
    String? id,
    int? dayOfWeek,
    String? dayLabel,
    String? startTimeLabel,
    String? endTimeLabel,
    String? locationNote,
    bool? isActive,
  }) {
    return PersonalAvailabilityWindow(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayLabel: dayLabel ?? this.dayLabel,
      startTimeLabel: startTimeLabel ?? this.startTimeLabel,
      endTimeLabel: endTimeLabel ?? this.endTimeLabel,
      locationNote: locationNote ?? this.locationNote,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        dayOfWeek,
        dayLabel,
        startTimeLabel,
        endTimeLabel,
        locationNote,
        isActive,
      ];
}

/// Warning representing an overlap between calendar entries.
/// Warnings inform the coach without automatically cancelling, moving, or blocking bookings.
class ScheduleConflictWarning extends Equatable {
  final String id;
  final String primaryEntryId;
  final String primaryTitle;
  final CalendarEntryContext primaryContext;
  final String conflictingEntryId;
  final String conflictingTitle;
  final CalendarEntryContext conflictingContext;
  final DateTime overlapStart;
  final DateTime overlapEnd;
  final String message;

  const ScheduleConflictWarning({
    required this.id,
    required this.primaryEntryId,
    required this.primaryTitle,
    required this.primaryContext,
    required this.conflictingEntryId,
    required this.conflictingTitle,
    required this.conflictingContext,
    required this.overlapStart,
    required this.overlapEnd,
    required this.message,
  });

  @override
  List<Object?> get props => [
        id,
        primaryEntryId,
        primaryTitle,
        primaryContext,
        conflictingEntryId,
        conflictingTitle,
        conflictingContext,
        overlapStart,
        overlapEnd,
        message,
      ];
}

/// Aggregated Coach Calendar & Availability payload.
class CoachCalendarData extends Equatable {
  final String coachId;
  final List<AcademyAffiliationSummary> acceptedAffiliations;
  final List<CoachCalendarSession> sessions;
  final List<CoachBlockedTime> blockedTimes;
  final List<PersonalAvailabilityWindow> personalAvailability;

  const CoachCalendarData({
    required this.coachId,
    required this.acceptedAffiliations,
    required this.sessions,
    required this.blockedTimes,
    required this.personalAvailability,
  });

  bool get isCompletelyEmpty =>
      sessions.isEmpty && blockedTimes.isEmpty && personalAvailability.isEmpty;

  /// Computes scheduling overlap warnings without modifying or hard-blocking any booking.
  List<ScheduleConflictWarning> get conflicts {
    final warnings = <ScheduleConflictWarning>[];

    // 1. Personal bookings overlapping Academy sessions
    final personalSessions = sessions
        .where((s) => s.contextType == CalendarEntryContext.personal)
        .toList();
    final academySessions = sessions
        .where((s) => s.contextType == CalendarEntryContext.academy)
        .toList();

    for (final personal in personalSessions) {
      for (final academy in academySessions) {
        if (personal.overlapsWith(academy.startTime, academy.endTime)) {
          final start = personal.startTime.isAfter(academy.startTime)
              ? personal.startTime
              : academy.startTime;
          final end = personal.endTime.isBefore(academy.endTime)
              ? personal.endTime
              : academy.endTime;
          warnings.add(
            ScheduleConflictWarning(
              id: 'conflict_${personal.id}_${academy.id}',
              primaryEntryId: personal.id,
              primaryTitle: personal.title,
              primaryContext: CalendarEntryContext.personal,
              conflictingEntryId: academy.id,
              conflictingTitle: academy.title,
              conflictingContext: CalendarEntryContext.academy,
              overlapStart: start,
              overlapEnd: end,
              message:
                  'Personal session "${personal.title}" overlaps academy session "${academy.title}". Both bookings remain unchanged.',
            ),
          );
        }
      }
    }

    // 2. Sessions overlapping Personal Blocked Time
    for (final session in sessions) {
      for (final blocked in blockedTimes) {
        if (session.overlapsWith(blocked.startTime, blocked.endTime)) {
          final start = session.startTime.isAfter(blocked.startTime)
              ? session.startTime
              : blocked.startTime;
          final end = session.endTime.isBefore(blocked.endTime)
              ? session.endTime
              : blocked.endTime;
          warnings.add(
            ScheduleConflictWarning(
              id: 'conflict_${session.id}_${blocked.id}',
              primaryEntryId: session.id,
              primaryTitle: session.title,
              primaryContext: session.contextType,
              conflictingEntryId: blocked.id,
              conflictingTitle: blocked.title,
              conflictingContext: CalendarEntryContext.blocked,
              overlapStart: start,
              overlapEnd: end,
              message:
                  '"${session.title}" overlaps blocked period "${blocked.title}".',
            ),
          );
        }
      }
    }

    return warnings;
  }

  CoachCalendarData copyWith({
    String? coachId,
    List<AcademyAffiliationSummary>? acceptedAffiliations,
    List<CoachCalendarSession>? sessions,
    List<CoachBlockedTime>? blockedTimes,
    List<PersonalAvailabilityWindow>? personalAvailability,
  }) {
    return CoachCalendarData(
      coachId: coachId ?? this.coachId,
      acceptedAffiliations: acceptedAffiliations ?? this.acceptedAffiliations,
      sessions: sessions ?? this.sessions,
      blockedTimes: blockedTimes ?? this.blockedTimes,
      personalAvailability: personalAvailability ?? this.personalAvailability,
    );
  }

  @override
  List<Object?> get props => [
        coachId,
        acceptedAffiliations,
        sessions,
        blockedTimes,
        personalAvailability,
      ];
}
