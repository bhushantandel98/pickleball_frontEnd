import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_calendar.dart';

/// Base state hierarchy for Coach Calendar & Availability.
sealed class CoachCalendarState extends Equatable {
  const CoachCalendarState();

  @override
  List<Object?> get props => [];
}

class CoachCalendarInitial extends CoachCalendarState {
  const CoachCalendarInitial();
}

class CoachCalendarLoading extends CoachCalendarState {
  const CoachCalendarLoading();
}

class CoachCalendarLoaded extends CoachCalendarState {
  final CoachCalendarData data;
  final CoachCalendarViewMode viewMode;
  final DateTime selectedDate;
  final CalendarEntryContext? contextFilter;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const CoachCalendarLoaded({
    required this.data,
    this.viewMode = CoachCalendarViewMode.day,
    required this.selectedDate,
    this.contextFilter,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  static DateTime normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Start of the Monday–Sunday week containing [selectedDate].
  DateTime get weekStart {
    final normalized = normalizeDate(selectedDate);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  /// End of the Monday–Sunday week containing [selectedDate] (inclusive day).
  DateTime get weekEnd => weekStart.add(const Duration(days: 6));

  bool _isInSelectedRange(DateTime dt) {
    final day = normalizeDate(dt);
    switch (viewMode) {
      case CoachCalendarViewMode.day:
        return _isSameDay(day, selectedDate);
      case CoachCalendarViewMode.week:
        return !day.isBefore(weekStart) && !day.isAfter(weekEnd);
      case CoachCalendarViewMode.month:
        return day.year == selectedDate.year && day.month == selectedDate.month;
    }
  }

  /// Sessions matching the active [viewMode], [selectedDate], and [contextFilter].
  List<CoachCalendarSession> get filteredSessions {
    if (contextFilter == CalendarEntryContext.blocked) {
      return const [];
    }
    final items = data.sessions.where((session) {
      if (contextFilter != null && session.contextType != contextFilter) {
        return false;
      }
      return _isInSelectedRange(session.startTime);
    }).toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  /// Blocked periods matching the active [viewMode], [selectedDate], and [contextFilter].
  List<CoachBlockedTime> get filteredBlockedTimes {
    if (contextFilter == CalendarEntryContext.personal ||
        contextFilter == CalendarEntryContext.academy) {
      return const [];
    }
    final items = data.blockedTimes
        .where((b) => _isInSelectedRange(b.startTime))
        .toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  /// Sessions for a specific [day] (respecting [contextFilter]), used in week/month views.
  List<CoachCalendarSession> sessionsOnDay(DateTime day) {
    if (contextFilter == CalendarEntryContext.blocked) return const [];
    return data.sessions.where((s) {
      if (contextFilter != null && s.contextType != contextFilter) return false;
      return _isSameDay(s.startTime, day);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Blocked periods for a specific [day] (respecting [contextFilter]).
  List<CoachBlockedTime> blockedTimesOnDay(DateTime day) {
    if (contextFilter == CalendarEntryContext.personal ||
        contextFilter == CalendarEntryContext.academy) {
      return const [];
    }
    return data.blockedTimes
        .where((b) => _isSameDay(b.startTime, day))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// All detected scheduling overlap warnings.
  List<ScheduleConflictWarning> get conflicts => data.conflicts;

  bool hasConflictForEntry(String entryId) {
    return conflicts.any(
      (c) => c.primaryEntryId == entryId || c.conflictingEntryId == entryId,
    );
  }

  CoachCalendarLoaded copyWith({
    CoachCalendarData? data,
    CoachCalendarViewMode? viewMode,
    DateTime? selectedDate,
    CalendarEntryContext? contextFilter,
    bool clearContextFilter = false,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? isErrorFeedback,
  }) {
    return CoachCalendarLoaded(
      data: data ?? this.data,
      viewMode: viewMode ?? this.viewMode,
      selectedDate: selectedDate ?? this.selectedDate,
      contextFilter:
          clearContextFilter ? null : (contextFilter ?? this.contextFilter),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isErrorFeedback:
          clearFeedback ? false : (isErrorFeedback ?? this.isErrorFeedback),
    );
  }

  @override
  List<Object?> get props => [
        data,
        viewMode,
        selectedDate,
        contextFilter,
        feedbackMessage,
        isErrorFeedback,
      ];
}

class CoachCalendarEmpty extends CoachCalendarState {
  final String message;

  const CoachCalendarEmpty({
    this.message = 'No coaching sessions, blocked times, or availability set yet.',
  });

  @override
  List<Object?> get props => [message];
}

class CoachCalendarFailure extends CoachCalendarState {
  final Failure failure;

  const CoachCalendarFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
