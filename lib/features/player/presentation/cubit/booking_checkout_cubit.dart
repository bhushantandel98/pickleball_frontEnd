import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/booking_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_checkout_state.dart';

/// Cubit managing checkout review, payload validation, and booking confirmation.
class BookingCheckoutCubit extends Cubit<BookingCheckoutState> {
  final BookingRepository repository;

  BookingCheckoutCubit({
    required this.repository,
  }) : super(const BookingCheckoutInitial());

  /// Initializes the cubit with the given [payload] and performs validation.
  void init(BookingSelectionPayload? payload) {
    if (payload == null) {
      emit(const BookingCheckoutInvalid('Booking selection details are missing.'));
      return;
    }

    if (!payload.isValid) {
      emit(const BookingCheckoutInvalid('Incomplete booking information provided.'));
      return;
    }

    emit(
      BookingCheckoutReady(
        payload: payload,
        courtFee: payload.price,
        platformFee: 0.0,
        taxes: 0.0,
        totalAmount: payload.price,
      ),
    );
  }

  /// Confirms the booking and persists a local mock record.
  Future<void> confirmBooking({
    String? playerId,
    String? playerName,
  }) async {
    final currentState = state;
    if (currentState is! BookingCheckoutReady && currentState is! BookingCheckoutFailure) {
      return;
    }

    final payload = currentState is BookingCheckoutReady
        ? currentState.payload
        : (currentState as BookingCheckoutFailure).payload;

    emit(BookingCheckoutSubmitting(payload));

    final result = await repository.createBooking(
      payload: payload,
      playerId: playerId,
      playerName: playerName,
    );

    if (result case Success(:final data)) {
      emit(BookingCheckoutSuccess(data));
    } else if (result case FailureResult(:final failure)) {
      emit(BookingCheckoutFailure(payload: payload, failure: failure));
    }
  }
}
