import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';

/// Contract for court booking creation and retrieval.
abstract class BookingRepository {
  /// Creates a court booking from the user's validated selection.
  Future<Result<CourtBooking>> createBooking({
    required BookingSelectionPayload payload,
    String? playerId,
    String? playerName,
  });

  /// Retrieves a specific booking record by its unique ID.
  Future<Result<CourtBooking>> getBookingById(String bookingId);

  /// Retrieves all bookings for the active player.
  Future<Result<List<CourtBooking>>> getBookings();

  /// Cancels an active court booking by ID.
  Future<Result<CourtBooking>> cancelBooking(String bookingId);
}
