import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/personal_coaching_booking.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/personal_coaching_repository.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/personal_coaching_state.dart';

/// Cubit managing Coach Personal Coaching bookings, status filtering,
/// creation, editing (preserving pending or invalidating confirmed approval),
/// and coach-initiated cancellation.
class PersonalCoachingCubit extends Cubit<PersonalCoachingState> {
  final PersonalCoachingRepository repository;

  PersonalCoachingCubit({
    required this.repository,
  }) : super(const PersonalCoachingInitial());

  Future<void> loadBookings({String coachId = 'coach_001'}) async {
    emit(const PersonalCoachingLoading());
    final result = await repository.getBookings(coachId: coachId);
    switch (result) {
      case Success(:final data):
        emit(
          PersonalCoachingLoaded(
            coachId: coachId,
            bookings: data,
          ),
        );
      case FailureResult(:final failure):
        emit(PersonalCoachingFailure(failure));
    }
  }

  Future<void> refreshBookings({String? coachId}) async {
    final current = state;
    final resolvedCoachId =
        coachId ?? (current is PersonalCoachingLoaded ? current.coachId : 'coach_001');
    final result = await repository.getBookings(coachId: resolvedCoachId);
    switch (result) {
      case Success(:final data):
        if (current is PersonalCoachingLoaded) {
          emit(current.copyWith(bookings: data, clearFeedback: true));
        } else {
          emit(
            PersonalCoachingLoaded(
              coachId: resolvedCoachId,
              bookings: data,
            ),
          );
        }
      case FailureResult(:final failure):
        emit(PersonalCoachingFailure(failure));
    }
  }

  void setFilter(PersonalBookingFilter filter) {
    final current = state;
    if (current is! PersonalCoachingLoaded) return;
    emit(current.copyWith(activeFilter: filter, clearFeedback: true));
  }

  void setSearchQuery(String query) {
    final current = state;
    if (current is! PersonalCoachingLoaded) return;
    emit(current.copyWith(searchQuery: query, clearFeedback: true));
  }

  void clearFeedback() {
    final current = state;
    if (current is PersonalCoachingLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<bool> createBooking({
    required String playerName,
    required String playerContact,
    required String sessionTitle,
    required String sessionType,
    required String venueName,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    final current = state;
    if (current is! PersonalCoachingLoaded) return false;

    final result = await repository.createBooking(
      coachId: current.coachId,
      playerName: playerName,
      playerContact: playerContact,
      sessionTitle: sessionTitle,
      sessionType: sessionType,
      venueName: venueName,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
    );

    switch (result) {
      case Success(:final data):
        final updatedList = [...current.bookings, data]
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        emit(
          current.copyWith(
            bookings: updatedList,
            feedbackMessage:
                'Booking created as Pending Player Approval.',
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

  Future<bool> editBooking({
    required String bookingId,
    required String sessionTitle,
    required String sessionType,
    required String venueName,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    final current = state;
    if (current is! PersonalCoachingLoaded) return false;

    final wasConfirmed = current.bookings.any(
      (b) => b.id == bookingId && b.status == PersonalBookingStatus.confirmed,
    );

    final result = await repository.editBooking(
      coachId: current.coachId,
      bookingId: bookingId,
      sessionTitle: sessionTitle,
      sessionType: sessionType,
      venueName: venueName,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
    );

    switch (result) {
      case Success(:final data):
        final updatedList = current.bookings
            .map((b) => b.id == data.id ? data : b)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        emit(
          current.copyWith(
            bookings: updatedList,
            feedbackMessage: wasConfirmed
                ? 'Booking updated. Previous approval invalidated — returned to Pending Player Approval.'
                : 'Pending booking updated.',
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

  Future<bool> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final current = state;
    if (current is! PersonalCoachingLoaded) return false;

    final result = await repository.cancelBooking(
      coachId: current.coachId,
      bookingId: bookingId,
      reason: reason,
    );

    switch (result) {
      case Success(:final data):
        final updatedList = current.bookings
            .map((b) => b.id == data.id ? data : b)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        emit(
          current.copyWith(
            bookings: updatedList,
            feedbackMessage: 'Personal coaching booking cancelled.',
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
