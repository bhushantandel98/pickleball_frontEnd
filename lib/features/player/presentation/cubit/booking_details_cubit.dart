import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';
import 'package:pickleball_platform/features/player/domain/repositories/booking_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_details_state.dart';

/// Cubit managing an individual booking details view and cancellation.
class BookingDetailsCubit extends Cubit<BookingDetailsState> {
  final BookingRepository repository;

  BookingDetailsCubit({required this.repository}) : super(const BookingDetailsInitial());

  /// Loads booking details by ID with optional instant pre-loaded entity.
  Future<void> loadBooking(String bookingId, {CourtBooking? initialBooking}) async {
    if (initialBooking != null) {
      emit(BookingDetailsLoaded(booking: initialBooking));
    } else {
      emit(const BookingDetailsLoading());
    }

    final result = await repository.getBookingById(bookingId);
    switch (result) {
      case Success<CourtBooking>(:final data):
        emit(BookingDetailsLoaded(booking: data));
      case FailureResult(:final failure):
        if (state is! BookingDetailsLoaded) {
          emit(BookingDetailsFailure(failure.message));
        }
    }
  }

  /// Cancels this active court booking.
  Future<bool> cancelBooking(String bookingId) async {
    if (state is! BookingDetailsLoaded) return false;
    final current = state as BookingDetailsLoaded;

    emit(current.copyWith(isCancelling: true));

    final result = await repository.cancelBooking(bookingId);
    switch (result) {
      case Success<CourtBooking>(:final data):
        emit(BookingDetailsLoaded(
          booking: data,
          isCancelling: false,
          feedbackMessage: 'Booking ${data.bookingReference} has been cancelled.',
        ));
        return true;
      case FailureResult(:final failure):
        emit(current.copyWith(
          isCancelling: false,
          feedbackMessage: failure.message,
        ));
        return false;
    }
  }

  /// Clears transient feedback banner.
  void clearFeedback() {
    if (state is BookingDetailsLoaded) {
      emit((state as BookingDetailsLoaded).copyWith(clearFeedbackMessage: true));
    }
  }
}
