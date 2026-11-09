import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';

/// Available tabs / filter categories for My Bookings.
enum BookingFilter {
  upcoming('Upcoming'),
  past('Past'),
  cancelled('Cancelled');

  final String label;
  const BookingFilter(this.label);
}

/// Sealed state hierarchy for player My Bookings & history.
sealed class MyBookingsState extends Equatable {
  const MyBookingsState();

  @override
  List<Object?> get props => [];
}

class MyBookingsInitial extends MyBookingsState {
  const MyBookingsInitial();
}

class MyBookingsLoading extends MyBookingsState {
  const MyBookingsLoading();
}

class MyBookingsLoaded extends MyBookingsState {
  final List<CourtBooking> allBookings;
  final BookingFilter activeFilter;
  final String? cancellingBookingId;
  final String? feedbackMessage;

  const MyBookingsLoaded({
    required this.allBookings,
    this.activeFilter = BookingFilter.upcoming,
    this.cancellingBookingId,
    this.feedbackMessage,
  });

  /// Chronological ascending upcoming bookings.
  List<CourtBooking> get upcomingBookings =>
      allBookings.where((b) => b.isUpcoming).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  /// Chronological descending past completed bookings.
  List<CourtBooking> get pastBookings =>
      allBookings.where((b) => b.isPast).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Chronological descending cancelled bookings.
  List<CourtBooking> get cancelledBookings =>
      allBookings.where((b) => b.isCancelled).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  /// Bookings matching the currently active filter.
  List<CourtBooking> get filteredBookings {
    switch (activeFilter) {
      case BookingFilter.upcoming:
        return upcomingBookings;
      case BookingFilter.past:
        return pastBookings;
      case BookingFilter.cancelled:
        return cancelledBookings;
    }
  }

  int get upcomingCount => upcomingBookings.length;
  int get pastCount => pastBookings.length;
  int get cancelledCount => cancelledBookings.length;

  MyBookingsLoaded copyWith({
    List<CourtBooking>? allBookings,
    BookingFilter? activeFilter,
    String? cancellingBookingId,
    String? feedbackMessage,
    bool clearCancellingId = false,
    bool clearFeedbackMessage = false,
  }) {
    return MyBookingsLoaded(
      allBookings: allBookings ?? this.allBookings,
      activeFilter: activeFilter ?? this.activeFilter,
      cancellingBookingId: clearCancellingId
          ? null
          : (cancellingBookingId ?? this.cancellingBookingId),
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        allBookings,
        activeFilter,
        cancellingBookingId,
        feedbackMessage,
      ];
}

class MyBookingsFailure extends MyBookingsState {
  final String message;

  const MyBookingsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
