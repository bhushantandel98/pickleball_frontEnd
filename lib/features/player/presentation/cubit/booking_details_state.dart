import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';

/// Sealed state hierarchy for individual booking details view.
sealed class BookingDetailsState extends Equatable {
  const BookingDetailsState();

  @override
  List<Object?> get props => [];
}

class BookingDetailsInitial extends BookingDetailsState {
  const BookingDetailsInitial();
}

class BookingDetailsLoading extends BookingDetailsState {
  const BookingDetailsLoading();
}

class BookingDetailsLoaded extends BookingDetailsState {
  final CourtBooking booking;
  final bool isCancelling;
  final String? feedbackMessage;

  const BookingDetailsLoaded({
    required this.booking,
    this.isCancelling = false,
    this.feedbackMessage,
  });

  BookingDetailsLoaded copyWith({
    CourtBooking? booking,
    bool? isCancelling,
    String? feedbackMessage,
    bool clearFeedbackMessage = false,
  }) {
    return BookingDetailsLoaded(
      booking: booking ?? this.booking,
      isCancelling: isCancelling ?? this.isCancelling,
      feedbackMessage: clearFeedbackMessage
          ? null
          : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [booking, isCancelling, feedbackMessage];
}

class BookingDetailsFailure extends BookingDetailsState {
  final String message;

  const BookingDetailsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
