import 'package:equatable/equatable.dart';

/// Lifecycle status of a Coach's personal coaching booking.
///
/// Business rules:
/// - New bookings always start as [pendingPlayerApproval].
/// - Only the player can approve ([confirmed]) or decline ([declined]).
/// - Editing a [confirmed] booking invalidates previous approval and returns
///   it to [pendingPlayerApproval].
/// - Only the coach can cancel ([cancelled]).
enum PersonalBookingStatus {
  pendingPlayerApproval('Pending Player Approval'),
  confirmed('Confirmed'),
  declined('Declined'),
  cancelled('Cancelled');

  final String label;
  const PersonalBookingStatus(this.label);
}

/// Filter tabs for Personal Coaching Management.
enum PersonalBookingFilter {
  all('All'),
  upcoming('Upcoming'),
  pending('Pending'),
  confirmed('Confirmed'),
  declined('Declined'),
  cancelled('Cancelled');

  final String label;
  const PersonalBookingFilter(this.label);
}

/// Audit event types preserved in booking history.
enum BookingHistoryEventType {
  created('Created'),
  edited('Edited'),
  playerApproved('Player Approved'),
  playerDeclined('Player Declined'),
  cancelled('Cancelled');

  final String label;
  const BookingHistoryEventType(this.label);
}

/// Immutable audit entry recording booking lifecycle events.
class BookingHistoryEntry extends Equatable {
  final String id;
  final BookingHistoryEventType eventType;
  final String title;
  final String description;
  final String actorLabel;
  final DateTime timestamp;

  const BookingHistoryEntry({
    required this.id,
    required this.eventType,
    required this.title,
    required this.description,
    required this.actorLabel,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        id,
        eventType,
        title,
        description,
        actorLabel,
        timestamp,
      ];
}

/// A Coach's personal coaching booking, strictly separate from academy sessions.
class PersonalCoachingBooking extends Equatable {
  final String id;
  final String coachId;
  final String playerId;
  final String playerName;
  final String playerContact;
  final String sessionTitle;
  final String sessionType;
  final String venueName;
  final String? notes;
  final DateTime startTime;
  final DateTime endTime;
  final PersonalBookingStatus status;
  final String? playerResponseNote;
  final String? cancellationReason;

  /// Non-blocking warning if this booking overlaps another schedule entry.
  final String? conflictWarning;

  final DateTime createdAt;
  final DateTime updatedAt;
  final List<BookingHistoryEntry> history;

  const PersonalCoachingBooking({
    required this.id,
    required this.coachId,
    required this.playerId,
    required this.playerName,
    required this.playerContact,
    required this.sessionTitle,
    required this.sessionType,
    required this.venueName,
    this.notes,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.playerResponseNote,
    this.cancellationReason,
    this.conflictWarning,
    required this.createdAt,
    required this.updatedAt,
    required this.history,
  });

  bool isUpcoming(DateTime referenceNow) {
    return (status == PersonalBookingStatus.pendingPlayerApproval ||
            status == PersonalBookingStatus.confirmed) &&
        endTime.isAfter(referenceNow);
  }

  bool get canEdit =>
      status == PersonalBookingStatus.pendingPlayerApproval ||
      status == PersonalBookingStatus.confirmed;

  bool get canCancel =>
      status == PersonalBookingStatus.pendingPlayerApproval ||
      status == PersonalBookingStatus.confirmed;

  PersonalCoachingBooking copyWith({
    String? playerName,
    String? playerContact,
    String? sessionTitle,
    String? sessionType,
    String? venueName,
    String? notes,
    DateTime? startTime,
    DateTime? endTime,
    PersonalBookingStatus? status,
    String? playerResponseNote,
    bool clearPlayerResponseNote = false,
    String? cancellationReason,
    String? conflictWarning,
    bool clearConflictWarning = false,
    DateTime? updatedAt,
    List<BookingHistoryEntry>? history,
  }) {
    return PersonalCoachingBooking(
      id: id,
      coachId: coachId,
      playerId: playerId,
      playerName: playerName ?? this.playerName,
      playerContact: playerContact ?? this.playerContact,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      sessionType: sessionType ?? this.sessionType,
      venueName: venueName ?? this.venueName,
      notes: notes ?? this.notes,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      playerResponseNote: clearPlayerResponseNote
          ? null
          : (playerResponseNote ?? this.playerResponseNote),
      cancellationReason: cancellationReason ?? this.cancellationReason,
      conflictWarning: clearConflictWarning
          ? null
          : (conflictWarning ?? this.conflictWarning),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      history: history ?? this.history,
    );
  }

  @override
  List<Object?> get props => [
        id,
        coachId,
        playerId,
        playerName,
        playerContact,
        sessionTitle,
        sessionType,
        venueName,
        notes,
        startTime,
        endTime,
        status,
        playerResponseNote,
        cancellationReason,
        conflictWarning,
        createdAt,
        updatedAt,
        history,
      ];
}
