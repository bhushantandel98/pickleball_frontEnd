import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_calendar.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/coach_calendar_repository.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_calendar_state.dart';

/// Cubit managing Coach Calendar views (Day/Week/Month), personal availability,
/// blocked-time periods, and overlap conflict warnings.
class CoachCalendarCubit extends Cubit<CoachCalendarState> {
  final CoachCalendarRepository repository;

  CoachCalendarCubit({
    required this.repository,
  }) : super(const CoachCalendarInitial());

  Future<void> loadCalendar({String? coachId, DateTime? initialDate}) async {
    emit(const CoachCalendarLoading());
    final result = await repository.getCalendarData(coachId: coachId);
    switch (result) {
      case Success(:final data):
        if (data.isCompletelyEmpty) {
          emit(const CoachCalendarEmpty());
        } else {
          emit(
            CoachCalendarLoaded(
              data: data,
              selectedDate: CoachCalendarLoaded.normalizeDate(
                initialDate ?? DateTime.now(),
              ),
            ),
          );
        }
      case FailureResult(:final failure):
        emit(CoachCalendarFailure(failure));
    }
  }

  Future<void> refreshCalendar({String? coachId}) async {
    final prev = state;
    final result = await repository.getCalendarData(coachId: coachId);
    switch (result) {
      case Success(:final data):
        if (data.isCompletelyEmpty) {
          emit(const CoachCalendarEmpty());
        } else if (prev is CoachCalendarLoaded) {
          emit(prev.copyWith(data: data, clearFeedback: true));
        } else {
          emit(
            CoachCalendarLoaded(
              data: data,
              selectedDate: CoachCalendarLoaded.normalizeDate(DateTime.now()),
            ),
          );
        }
      case FailureResult(:final failure):
        emit(CoachCalendarFailure(failure));
    }
  }

  void setViewMode(CoachCalendarViewMode mode) {
    final current = state;
    if (current is! CoachCalendarLoaded) return;
    emit(current.copyWith(viewMode: mode, clearFeedback: true));
  }

  void selectDate(DateTime date) {
    final current = state;
    if (current is! CoachCalendarLoaded) return;
    emit(
      current.copyWith(
        selectedDate: CoachCalendarLoaded.normalizeDate(date),
        clearFeedback: true,
      ),
    );
  }

  void stepDate(int delta) {
    final current = state;
    if (current is! CoachCalendarLoaded) return;

    final d = current.selectedDate;
    final nextDate = switch (current.viewMode) {
      CoachCalendarViewMode.day => d.add(Duration(days: delta)),
      CoachCalendarViewMode.week => d.add(Duration(days: delta * 7)),
      CoachCalendarViewMode.month => DateTime(d.year, d.month + delta, 1),
    };
    emit(current.copyWith(selectedDate: nextDate, clearFeedback: true));
  }

  void setContextFilter(CalendarEntryContext? context) {
    final current = state;
    if (current is! CoachCalendarLoaded) return;
    emit(
      current.copyWith(
        contextFilter: context,
        clearContextFilter: context == null,
        clearFeedback: true,
      ),
    );
  }

  void clearFeedback() {
    final current = state;
    if (current is CoachCalendarLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<bool> addBlockedTime({
    required String title,
    required DateTime startTime,
    required DateTime endTime,
    String? reason,
  }) async {
    final current = state;
    if (current is! CoachCalendarLoaded) return false;

    final result = await repository.addBlockedTime(
      coachId: current.data.coachId,
      title: title,
      startTime: startTime,
      endTime: endTime,
      reason: reason,
    );
    return _applyMutation(result, 'Personal blocked time added.');
  }

  Future<bool> removeBlockedTime(String blockedTimeId) async {
    final current = state;
    if (current is! CoachCalendarLoaded) return false;

    final result = await repository.removeBlockedTime(
      coachId: current.data.coachId,
      blockedTimeId: blockedTimeId,
    );
    return _applyMutation(result, 'Blocked time removed.');
  }

  Future<bool> addAvailabilityWindow(PersonalAvailabilityWindow window) async {
    final current = state;
    if (current is! CoachCalendarLoaded) return false;

    final result = await repository.addAvailabilityWindow(
      coachId: current.data.coachId,
      window: window,
    );
    return _applyMutation(result, 'Personal availability added.');
  }

  Future<bool> toggleAvailabilityWindow(String windowId, bool isActive) async {
    final current = state;
    if (current is! CoachCalendarLoaded) return false;

    final result = await repository.toggleAvailabilityWindow(
      coachId: current.data.coachId,
      windowId: windowId,
      isActive: isActive,
    );
    return _applyMutation(
      result,
      isActive ? 'Availability window enabled.' : 'Availability window paused.',
    );
  }

  Future<bool> removeAvailabilityWindow(String windowId) async {
    final current = state;
    if (current is! CoachCalendarLoaded) return false;

    final result = await repository.removeAvailabilityWindow(
      coachId: current.data.coachId,
      windowId: windowId,
    );
    return _applyMutation(result, 'Availability window removed.');
  }

  bool _applyMutation(
    Result<CoachCalendarData> result,
    String successMessage,
  ) {
    final current = state;
    if (current is! CoachCalendarLoaded) return false;

    switch (result) {
      case Success(:final data):
        emit(
          current.copyWith(
            data: data,
            feedbackMessage: successMessage,
            isErrorFeedback: false,
          ),
        );
        return true;
      case FailureResult(:final failure):
        emit(
          current.copyWith(
            feedbackMessage: failure.message,
            isErrorFeedback: true,
          ),
        );
        return false;
    }
  }
}
