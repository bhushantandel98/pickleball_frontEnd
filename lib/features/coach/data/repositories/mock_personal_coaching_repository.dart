import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/coach/domain/entities/personal_coaching_booking.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/personal_coaching_repository.dart';

/// In-memory mock implementation of [PersonalCoachingRepository] for Phase 3 Feature 3.4.
class MockPersonalCoachingRepository implements PersonalCoachingRepository {
  final bool shouldFail;
  final bool simulateEmpty;
  final DateTime _referenceDate;
  final List<PersonalCoachingBooking> _bookings;

  MockPersonalCoachingRepository({
    this.shouldFail = false,
    this.simulateEmpty = false,
    DateTime? referenceDate,
    List<PersonalCoachingBooking>? initialBookings,
  })  : _referenceDate = referenceDate ?? DateTime.now(),
        _bookings = List<PersonalCoachingBooking>.from(
          initialBookings ??
              (simulateEmpty
                  ? const <PersonalCoachingBooking>[]
                  : _buildSeedBookings(referenceDate ?? DateTime.now())),
        );

  static List<PersonalCoachingBooking> _buildSeedBookings(DateTime ref) {
    final baseDay = DateTime(ref.year, ref.month, ref.day);

    return [
      PersonalCoachingBooking(
        id: 'pb_001',
        coachId: 'coach_001',
        playerId: 'player_101',
        playerName: 'Rohan Mehta',
        playerContact: '+91 98201 11223',
        sessionTitle: 'Third-Shot Drop & Kitchen Footwork',
        sessionType: '1-on-1 Coaching',
        venueName: 'Grand Slam Pickleball Arena, Bandra',
        notes: 'Focus on soft resets and split-step timing.',
        startTime: baseDay.add(const Duration(days: 1, hours: 7)),
        endTime: baseDay.add(const Duration(days: 1, hours: 8)),
        status: PersonalBookingStatus.pendingPlayerApproval,
        createdAt: baseDay.subtract(const Duration(hours: 6)),
        updatedAt: baseDay.subtract(const Duration(hours: 6)),
        history: [
          BookingHistoryEntry(
            id: 'h_001_1',
            eventType: BookingHistoryEventType.created,
            title: 'Booking Created',
            description:
                'Created by Coach and sent for player approval (Pending Player Approval).',
            actorLabel: 'Coach',
            timestamp: baseDay.subtract(const Duration(hours: 6)),
          ),
        ],
      ),
      PersonalCoachingBooking(
        id: 'pb_002',
        coachId: 'coach_001',
        playerId: 'player_102',
        playerName: 'Ananya Rao',
        playerContact: '+91 98204 55678',
        sessionTitle: 'Serve & Spin Clinic',
        sessionType: '1-on-1 Coaching',
        venueName: 'Dink & Smash Club, Juhu',
        notes: 'Video review of topspin serve motion.',
        startTime: baseDay.add(const Duration(hours: 18, minutes: 30)),
        endTime: baseDay.add(const Duration(hours: 19, minutes: 30)),
        status: PersonalBookingStatus.confirmed,
        playerResponseNote: 'Approved by player — excited for the serve drills!',
        conflictWarning:
            'Overlaps with read-only Academy session: Apex Pickleball Academy — Intermediate Doubles Batch B2 (19:00 – 20:30). Both remain active.',
        createdAt: baseDay.subtract(const Duration(days: 2)),
        updatedAt: baseDay.subtract(const Duration(days: 1)),
        history: [
          BookingHistoryEntry(
            id: 'h_002_1',
            eventType: BookingHistoryEventType.created,
            title: 'Booking Created',
            description:
                'Created by Coach as Pending Player Approval.',
            actorLabel: 'Coach',
            timestamp: baseDay.subtract(const Duration(days: 2)),
          ),
          BookingHistoryEntry(
            id: 'h_002_2',
            eventType: BookingHistoryEventType.playerApproved,
            title: 'Player Approved',
            description: 'Ananya Rao approved the session.',
            actorLabel: 'Ananya Rao (Player)',
            timestamp: baseDay.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      PersonalCoachingBooking(
        id: 'pb_003',
        coachId: 'coach_001',
        playerId: 'player_103',
        playerName: 'Kabir & Tara',
        playerContact: '+91 98199 44321',
        sessionTitle: 'Doubles Stacking & Transition Drills',
        sessionType: 'Semi-Private',
        venueName: 'Metro Pickleball Courts, Worli',
        startTime: baseDay.add(const Duration(days: 2, hours: 8)),
        endTime: baseDay.add(const Duration(days: 2, hours: 9, minutes: 30)),
        status: PersonalBookingStatus.declined,
        playerResponseNote: 'Unavailable at 8:00 AM due to office travel.',
        createdAt: baseDay.subtract(const Duration(days: 3)),
        updatedAt: baseDay.subtract(const Duration(days: 2)),
        history: [
          BookingHistoryEntry(
            id: 'h_003_1',
            eventType: BookingHistoryEventType.created,
            title: 'Booking Created',
            description: 'Created by Coach as Pending Player Approval.',
            actorLabel: 'Coach',
            timestamp: baseDay.subtract(const Duration(days: 3)),
          ),
          BookingHistoryEntry(
            id: 'h_003_2',
            eventType: BookingHistoryEventType.playerDeclined,
            title: 'Player Declined',
            description:
                'Kabir & Tara declined: Unavailable at 8:00 AM due to office travel.',
            actorLabel: 'Kabir & Tara (Player)',
            timestamp: baseDay.subtract(const Duration(days: 2)),
          ),
        ],
      ),
      PersonalCoachingBooking(
        id: 'pb_004',
        coachId: 'coach_001',
        playerId: 'player_104',
        playerName: 'Devika Nair',
        playerContact: '+91 98330 77889',
        sessionTitle: 'DUPR Match Readiness Assessment',
        sessionType: 'Assessment',
        venueName: 'Grand Slam Pickleball Arena, Bandra',
        startTime: baseDay.add(const Duration(days: 3, hours: 17)),
        endTime: baseDay.add(const Duration(days: 3, hours: 18)),
        status: PersonalBookingStatus.cancelled,
        cancellationReason: 'Court resurfacing scheduled by venue.',
        createdAt: baseDay.subtract(const Duration(days: 4)),
        updatedAt: baseDay.subtract(const Duration(days: 1)),
        history: [
          BookingHistoryEntry(
            id: 'h_004_1',
            eventType: BookingHistoryEventType.created,
            title: 'Booking Created',
            description: 'Created by Coach as Pending Player Approval.',
            actorLabel: 'Coach',
            timestamp: baseDay.subtract(const Duration(days: 4)),
          ),
          BookingHistoryEntry(
            id: 'h_004_2',
            eventType: BookingHistoryEventType.playerApproved,
            title: 'Player Approved',
            description: 'Devika Nair approved the session.',
            actorLabel: 'Devika Nair (Player)',
            timestamp: baseDay.subtract(const Duration(days: 3)),
          ),
          BookingHistoryEntry(
            id: 'h_004_3',
            eventType: BookingHistoryEventType.cancelled,
            title: 'Cancelled by Coach',
            description: 'Reason: Court resurfacing scheduled by venue.',
            actorLabel: 'Coach',
            timestamp: baseDay.subtract(const Duration(days: 1)),
          ),
        ],
      ),
    ];
  }

  @override
  Future<Result<List<PersonalCoachingBooking>>> getBookings({
    required String coachId,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to load personal coaching bookings.'),
      );
    }
    final sorted = List<PersonalCoachingBooking>.from(_bookings)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return Success(sorted);
  }

  @override
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
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to create booking right now.'),
      );
    }

    if (playerName.trim().isEmpty ||
        sessionTitle.trim().isEmpty ||
        venueName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Player name, session title, and venue are required.',
        ),
      );
    }
    if (!endTime.isAfter(startTime)) {
      return const FailureResult(
        ValidationFailure(
          message: 'End time must be after start time.',
        ),
      );
    }

    final now = DateTime.now();
    final id = 'pb_${now.microsecondsSinceEpoch}';
    final warning = _computeConflictWarning(
      startTime: startTime,
      endTime: endTime,
    );

    final booking = PersonalCoachingBooking(
      id: id,
      coachId: coachId,
      playerId: 'player_${now.microsecondsSinceEpoch}',
      playerName: playerName.trim(),
      playerContact: playerContact.trim(),
      sessionTitle: sessionTitle.trim(),
      sessionType: sessionType.trim().isEmpty ? '1-on-1 Coaching' : sessionType.trim(),
      venueName: venueName.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      startTime: startTime,
      endTime: endTime,
      // Business rule: Every newly created booking starts as Pending Player Approval.
      status: PersonalBookingStatus.pendingPlayerApproval,
      conflictWarning: warning,
      createdAt: now,
      updatedAt: now,
      history: [
        BookingHistoryEntry(
          id: 'h_${now.microsecondsSinceEpoch}',
          eventType: BookingHistoryEventType.created,
          title: 'Booking Created',
          description:
              'Created by Coach and awaiting player approval (Pending Player Approval).',
          actorLabel: 'Coach',
          timestamp: now,
        ),
      ],
    );

    _bookings.add(booking);
    return Success(booking);
  }

  @override
  Future<Result<PersonalCoachingBooking>> editBooking({
    required String coachId,
    required String bookingId,
    required String sessionTitle,
    required String sessionType,
    required String venueName,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to update booking right now.'),
      );
    }

    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Booking not found.'),
      );
    }

    final existing = _bookings[index];
    if (!existing.canEdit) {
      return const FailureResult(
        ValidationFailure(
          message: 'Only pending or confirmed bookings can be edited.',
        ),
      );
    }

    if (sessionTitle.trim().isEmpty || venueName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure(
          message: 'Session title and venue are required.',
        ),
      );
    }
    if (!endTime.isAfter(startTime)) {
      return const FailureResult(
        ValidationFailure(
          message: 'End time must be after start time.',
        ),
      );
    }

    final now = DateTime.now();
    final wasConfirmed = existing.status == PersonalBookingStatus.confirmed;
    final warning = _computeConflictWarning(
      startTime: startTime,
      endTime: endTime,
      excludeBookingId: bookingId,
    );

    // Business rules 5 & 6:
    // - Pending booking stays Pending Player Approval.
    // - Confirmed booking invalidates previous approval and returns to Pending Player Approval.
    final updated = existing.copyWith(
      sessionTitle: sessionTitle.trim(),
      sessionType: sessionType.trim().isEmpty
          ? existing.sessionType
          : sessionType.trim(),
      venueName: venueName.trim(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
      startTime: startTime,
      endTime: endTime,
      status: PersonalBookingStatus.pendingPlayerApproval,
      clearPlayerResponseNote: wasConfirmed,
      conflictWarning: warning,
      clearConflictWarning: warning == null,
      updatedAt: now,
      history: [
        ...existing.history,
        BookingHistoryEntry(
          id: 'h_${now.microsecondsSinceEpoch}',
          eventType: BookingHistoryEventType.edited,
          title: wasConfirmed
              ? 'Booking Edited (Approval Invalidated)'
              : 'Booking Edited',
          description: wasConfirmed
              ? 'Coach edited a confirmed booking. Previous player approval was invalidated; status returned to Pending Player Approval.'
              : 'Coach edited pending booking details; status remains Pending Player Approval.',
          actorLabel: 'Coach',
          timestamp: now,
        ),
      ],
    );

    _bookings[index] = updated;
    return Success(updated);
  }

  @override
  Future<Result<PersonalCoachingBooking>> cancelBooking({
    required String coachId,
    required String bookingId,
    String? reason,
  }) async {
    if (shouldFail) {
      return const FailureResult(
        ServerFailure(message: 'Unable to cancel booking right now.'),
      );
    }

    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index == -1) {
      return const FailureResult(
        NotFoundFailure(message: 'Booking not found.'),
      );
    }

    final existing = _bookings[index];
    if (!existing.canCancel) {
      return const FailureResult(
        ValidationFailure(
          message: 'This booking cannot be cancelled.',
        ),
      );
    }

    final now = DateTime.now();
    final trimmedReason = reason?.trim();
    final updated = existing.copyWith(
      status: PersonalBookingStatus.cancelled,
      cancellationReason:
          (trimmedReason != null && trimmedReason.isNotEmpty)
              ? trimmedReason
              : null,
      clearConflictWarning: true,
      updatedAt: now,
      history: [
        ...existing.history,
        BookingHistoryEntry(
          id: 'h_${now.microsecondsSinceEpoch}',
          eventType: BookingHistoryEventType.cancelled,
          title: 'Cancelled by Coach',
          description: (trimmedReason != null && trimmedReason.isNotEmpty)
              ? 'Cancelled by Coach. Reason: $trimmedReason'
              : 'Cancelled by Coach.',
          actorLabel: 'Coach',
          timestamp: now,
        ),
      ],
    );

    _bookings[index] = updated;
    return Success(updated);
  }

  /// Checks overlaps against known read-only academy schedule windows and other
  /// active personal bookings. Returns a warning string only — never blocks.
  String? _computeConflictWarning({
    required DateTime startTime,
    required DateTime endTime,
    String? excludeBookingId,
  }) {
    final baseDay = DateTime(
      _referenceDate.year,
      _referenceDate.month,
      _referenceDate.day,
    );
    final academyStart = baseDay.add(const Duration(hours: 19));
    final academyEnd = baseDay.add(const Duration(hours: 20, minutes: 30));
    if (startTime.isBefore(academyEnd) && endTime.isAfter(academyStart)) {
      return 'Overlaps with read-only Academy session: Apex Pickleball Academy — Intermediate Doubles Batch B2 (19:00 – 20:30). Both remain active.';
    }

    for (final other in _bookings) {
      if (other.id == excludeBookingId) continue;
      if (other.status == PersonalBookingStatus.cancelled ||
          other.status == PersonalBookingStatus.declined) {
        continue;
      }
      if (startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime)) {
        return 'Overlaps with personal booking "${other.sessionTitle}" (${other.playerName}). Both bookings remain unchanged.';
      }
    }
    return null;
  }
}
