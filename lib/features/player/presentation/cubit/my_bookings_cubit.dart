import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';
import 'package:pickleball_platform/features/player/domain/repositories/booking_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_bookings_state.dart';

/// Cubit managing the Player My Bookings and booking history lifecycle.
class MyBookingsCubit extends Cubit<MyBookingsState> {
  final BookingRepository repository;

  MyBookingsCubit({required this.repository}) : super(const MyBookingsInitial());

  /// Loads all bookings from repository and populates state.
  Future<void> loadBookings({bool isRefresh = false}) async {
    if (!isRefresh && state is! MyBookingsLoaded) {
      emit(const MyBookingsLoading());
    }

    final result = await repository.getBookings();
    switch (result) {
      case Success<List<CourtBooking>>(:final data):
        final currentFilter = state is MyBookingsLoaded
            ? (state as MyBookingsLoaded).activeFilter
            : BookingFilter.upcoming;
        emit(MyBookingsLoaded(
          allBookings: data,
          activeFilter: currentFilter,
        ));
      case FailureResult(:final failure):
        emit(MyBookingsFailure(failure.message));
    }
  }

  /// Updates active tab filter between upcoming, past, and cancelled.
  void setFilter(BookingFilter filter) {
    if (state is MyBookingsLoaded) {
      final current = state as MyBookingsLoaded;
      emit(current.copyWith(
        activeFilter: filter,
        clearFeedbackMessage: true,
      ));
    }
  }

  /// Cancels an active booking and updates local state.
  Future<bool> cancelBooking(String bookingId) async {
    if (state is! MyBookingsLoaded) return false;
    final current = state as MyBookingsLoaded;

    emit(current.copyWith(cancellingBookingId: bookingId));

    final result = await repository.cancelBooking(bookingId);
    switch (result) {
      case Success<CourtBooking>(:final data):
        final updatedList = current.allBookings.map((b) {
          return b.id == data.id ? data : b;
        }).toList();

        emit(current.copyWith(
          allBookings: updatedList,
          clearCancellingId: true,
          feedbackMessage: 'Booking ${data.bookingReference} has been cancelled.',
        ));
        return true;
      case FailureResult(:final failure):
        emit(current.copyWith(
          clearCancellingId: true,
          feedbackMessage: failure.message,
        ));
        return false;
    }
  }

  /// Clears transient feedback banner / SnackBar text.
  void clearFeedback() {
    if (state is MyBookingsLoaded) {
      emit((state as MyBookingsLoaded).copyWith(clearFeedbackMessage: true));
    }
  }
}
