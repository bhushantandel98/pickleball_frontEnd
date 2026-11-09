import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';

/// Sealed state representation for the Court Booking Checkout screen.
sealed class BookingCheckoutState extends Equatable {
  const BookingCheckoutState();

  @override
  List<Object?> get props => [];
}

/// Initial state before payload verification begins.
class BookingCheckoutInitial extends BookingCheckoutState {
  const BookingCheckoutInitial();
}

/// State when required booking details are missing or malformed.
class BookingCheckoutInvalid extends BookingCheckoutState {
  final String errorMessage;

  const BookingCheckoutInvalid(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

/// Ready state when booking information is validated and awaiting player review/confirmation.
class BookingCheckoutReady extends BookingCheckoutState {
  final BookingSelectionPayload payload;
  final double courtFee;
  final double platformFee;
  final double taxes;
  final double totalAmount;
  final String paymentNotice;

  const BookingCheckoutReady({
    required this.payload,
    required this.courtFee,
    this.platformFee = 0.0,
    this.taxes = 0.0,
    required this.totalAmount,
    this.paymentNotice = 'Pay at Venue / Offline Payment',
  });

  @override
  List<Object?> get props => [
        payload,
        courtFee,
        platformFee,
        taxes,
        totalAmount,
        paymentNotice,
      ];
}

/// Submitting state when the booking is being processed.
class BookingCheckoutSubmitting extends BookingCheckoutState {
  final BookingSelectionPayload payload;

  const BookingCheckoutSubmitting(this.payload);

  @override
  List<Object?> get props => [payload];
}

/// Success state after booking has been created and confirmed.
class BookingCheckoutSuccess extends BookingCheckoutState {
  final CourtBooking booking;

  const BookingCheckoutSuccess(this.booking);

  @override
  List<Object?> get props => [booking];
}

/// Failure state if booking creation fails.
class BookingCheckoutFailure extends BookingCheckoutState {
  final BookingSelectionPayload payload;
  final Failure failure;

  const BookingCheckoutFailure({
    required this.payload,
    required this.failure,
  });

  @override
  List<Object?> get props => [payload, failure];
}
