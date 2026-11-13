import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/personal_coaching_booking.dart';

/// Repository contract for Coach Personal Coaching Management (Feature 3.4).
///
/// Strictly scoped to personal coaching bookings; academy sessions and
/// academy-owned schedules are never managed here.
abstract class PersonalCoachingRepository {
  Future<Result<List<PersonalCoachingBooking>>> getBookings({
    required String coachId,
  });

  Future<Result<PersonalCoachingBooking>> createBooking({
    required String coachId,
    required String playerName,
    required String playerContact,
    required String sessionTitle,
    required String sessionType,
    required String venueName,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  });

  Future<Result<PersonalCoachingBooking>> editBooking({
    required String coachId,
    required String bookingId,
    required String sessionTitle,
    required String sessionType,
    required String venueName,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  });

  Future<Result<PersonalCoachingBooking>> cancelBooking({
    required String coachId,
    required String bookingId,
    String? reason,
  });
}
