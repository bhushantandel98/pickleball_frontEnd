import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/booking_repository.dart';

/// In-memory mock implementation of [BookingRepository].
class MockBookingRepository implements BookingRepository {
  final bool shouldFail;
  final List<CourtBooking> _bookings;

  MockBookingRepository({
    this.shouldFail = false,
    List<CourtBooking>? initialBookings,
  }) : _bookings = List.of(initialBookings ?? []);

  /// Factory constructor pre-seeded with realistic upcoming, past, and cancelled bookings.
  factory MockBookingRepository.withDefaultBookings({bool shouldFail = false}) {
    return MockBookingRepository(
      shouldFail: shouldFail,
      initialBookings: defaultBookings(),
    );
  }

  /// Default realistic mock bookings consistent with Player PRD v1.6 and mock venues.
  static List<CourtBooking> defaultBookings() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 7, 0);
    final inThreeDays = DateTime(now.year, now.month, now.day + 3, 18, 0);
    final fiveDaysAgo = DateTime(now.year, now.month, now.day - 5, 19, 0);
    final twoWeeksAgo = DateTime(now.year, now.month, now.day - 14, 10, 0);

    return [
      CourtBooking(
        id: 'bkg_mock_001',
        bookingReference: generateBookingReference(tomorrow, 1),
        venueId: 'org_venue_001',
        venueName: 'Grand Slam Pickleball Arena',
        venueAddress: '742 Evergreen Terrace, Andheri West',
        venueCity: 'Mumbai',
        courtId: 'court_org_venue_001_1',
        courtName: 'Court 1 (Championship Cushioned)',
        surfaceType: 'Pro Cushion',
        date: tomorrow,
        slotId: 'slot_court_org_venue_001_1_tomorrow_07_00',
        slotTime: '07:00 - 08:00',
        startTime: '07:00',
        endTime: '08:00',
        durationMinutes: 60,
        courtFee: 700.0,
        platformFee: 0.0,
        taxes: 0.0,
        totalAmount: 700.0,
        status: BookingStatus.confirmed,
        paymentMethod: 'Pay at Venue (Offline)',
        playerId: 'user_player_001',
        playerName: 'Alex Rivera',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      CourtBooking(
        id: 'bkg_mock_002',
        bookingReference: generateBookingReference(inThreeDays, 2),
        venueId: 'org_venue_002',
        venueName: 'Pinnacle Sports Complex',
        venueAddress: 'Plot 15, BKC Bandra East',
        venueCity: 'Mumbai',
        courtId: 'court_org_venue_002_2',
        courtName: 'Court 2 (South Court)',
        surfaceType: 'Synthetic Acrylic',
        date: inThreeDays,
        slotId: 'slot_court_org_venue_002_2_in3days_18_00',
        slotTime: '18:00 - 19:00',
        startTime: '18:00',
        endTime: '19:00',
        durationMinutes: 60,
        courtFee: 850.0,
        platformFee: 0.0,
        taxes: 0.0,
        totalAmount: 850.0,
        status: BookingStatus.paymentPending,
        paymentMethod: 'Pay at Venue (Offline)',
        playerId: 'user_player_001',
        playerName: 'Alex Rivera',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      CourtBooking(
        id: 'bkg_mock_003',
        bookingReference: generateBookingReference(fiveDaysAgo, 3),
        venueId: 'org_venue_003',
        venueName: 'Dink & Smash Pickleball Club',
        venueAddress: 'Powai Central Road',
        venueCity: 'Mumbai',
        courtId: 'court_org_venue_003_1',
        courtName: 'Court 1 (Main Court)',
        surfaceType: 'Pro Cushion',
        date: fiveDaysAgo,
        slotId: 'slot_court_org_venue_003_1_past_19_00',
        slotTime: '19:00 - 20:00',
        startTime: '19:00',
        endTime: '20:00',
        durationMinutes: 60,
        courtFee: 600.0,
        platformFee: 0.0,
        taxes: 0.0,
        totalAmount: 600.0,
        status: BookingStatus.completed,
        paymentMethod: 'Pay at Venue (Offline)',
        playerId: 'user_player_001',
        playerName: 'Alex Rivera',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      CourtBooking(
        id: 'bkg_mock_004',
        bookingReference: generateBookingReference(twoWeeksAgo, 4),
        venueId: 'org_venue_004',
        venueName: 'Metro Pickleball Hub',
        venueAddress: 'Goregaon East Highway',
        venueCity: 'Mumbai',
        courtId: 'court_org_venue_004_3',
        courtName: 'Court 3',
        surfaceType: 'Polyurethane Cushioned',
        date: twoWeeksAgo,
        slotId: 'slot_court_org_venue_004_3_cancelled_10_00',
        slotTime: '10:00 - 11:00',
        startTime: '10:00',
        endTime: '11:00',
        durationMinutes: 60,
        courtFee: 550.0,
        platformFee: 0.0,
        taxes: 0.0,
        totalAmount: 550.0,
        status: BookingStatus.cancelled,
        paymentMethod: 'Pay at Venue (Offline)',
        playerId: 'user_player_001',
        playerName: 'Alex Rivera',
        createdAt: now.subtract(const Duration(days: 16)),
      ),
    ];
  }

  /// Generates a standardized, deterministic human-readable booking reference.
  static String generateBookingReference(DateTime date, int sequenceNumber) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final seq = sequenceNumber.toString().padLeft(4, '0');
    return 'PKL-BKG-$y$m$d-$seq';
  }

  @override
  Future<Result<CourtBooking>> createBooking({
    required BookingSelectionPayload payload,
    String? playerId,
    String? playerName,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to process court booking. Please try again.'),
      );
    }

    if (!payload.isValid) {
      return const FailureResult(
        ValidationFailure(message: 'Incomplete booking details provided.'),
      );
    }

    final now = DateTime.now();
    final sequence = _bookings.length + 1;
    final reference = generateBookingReference(payload.date, sequence);

    final booking = CourtBooking(
      id: 'bkg_${now.millisecondsSinceEpoch}_$sequence',
      bookingReference: reference,
      venueId: payload.venueId,
      venueName: payload.venueName,
      venueAddress: payload.venueAddress ?? 'Venue Location',
      venueCity: payload.venueCity ?? 'Mumbai',
      courtId: payload.courtId,
      courtName: payload.courtName,
      surfaceType: payload.surfaceType,
      date: payload.date,
      slotId: payload.slotId,
      slotTime: payload.slotTime,
      startTime: payload.startTime,
      endTime: payload.endTime,
      durationMinutes: payload.durationMinutes,
      courtFee: payload.price,
      platformFee: 0.0,
      taxes: 0.0,
      totalAmount: payload.price,
      status: BookingStatus.confirmed,
      paymentMethod: 'Pay at Venue (Offline)',
      playerId: playerId ?? 'usr_player_current',
      playerName: playerName ?? 'Alex Rivera',
      createdAt: now,
    );

    _bookings.add(booking);
    return Success(booking);
  }

  @override
  Future<Result<CourtBooking>> getBookingById(String bookingId) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Unable to retrieve booking'));
    }

    final match = _bookings.where((b) => b.id == bookingId || b.bookingReference == bookingId);
    if (match.isEmpty) {
      return const FailureResult(NotFoundFailure(message: 'Booking not found'));
    }
    return Success(match.first);
  }

  @override
  Future<Result<List<CourtBooking>>> getBookings() async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Unable to load bookings'));
    }
    return Success(List.unmodifiable(_bookings));
  }

  @override
  Future<Result<CourtBooking>> cancelBooking(String bookingId) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Unable to cancel booking. Please try again.'));
    }

    final index = _bookings.indexWhere((b) => b.id == bookingId || b.bookingReference == bookingId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Booking not found'));
    }

    final existing = _bookings[index];
    final updated = existing.copyWith(status: BookingStatus.cancelled);
    _bookings[index] = updated;
    return Success(updated);
  }
}
