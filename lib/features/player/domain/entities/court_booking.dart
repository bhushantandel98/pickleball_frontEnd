import 'package:equatable/equatable.dart';

/// Status of a court booking.
enum BookingStatus {
  confirmed('Confirmed'),
  paymentPending('Payment Pending'),
  cancelled('Cancelled'),
  completed('Completed');

  final String displayName;
  const BookingStatus(this.displayName);
}

/// Domain entity representing a confirmed court reservation.
class CourtBooking extends Equatable {
  final String id;
  final String bookingReference;
  final String venueId;
  final String venueName;
  final String venueAddress;
  final String venueCity;
  final String courtId;
  final String courtName;
  final String surfaceType;
  final DateTime date;
  final String slotId;
  final String slotTime;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final double courtFee;
  final double platformFee;
  final double taxes;
  final double totalAmount;
  final BookingStatus status;
  final String paymentMethod;
  final String playerId;
  final String playerName;
  final DateTime createdAt;

  const CourtBooking({
    required this.id,
    required this.bookingReference,
    required this.venueId,
    required this.venueName,
    required this.venueAddress,
    required this.venueCity,
    required this.courtId,
    required this.courtName,
    required this.surfaceType,
    required this.date,
    required this.slotId,
    required this.slotTime,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.courtFee,
    this.platformFee = 0.0,
    this.taxes = 0.0,
    required this.totalAmount,
    this.status = BookingStatus.confirmed,
    this.paymentMethod = 'Pay at Venue (Offline)',
    required this.playerId,
    required this.playerName,
    required this.createdAt,
  });

  CourtBooking copyWith({
    String? id,
    String? bookingReference,
    String? venueId,
    String? venueName,
    String? venueAddress,
    String? venueCity,
    String? courtId,
    String? courtName,
    String? surfaceType,
    DateTime? date,
    String? slotId,
    String? slotTime,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    double? courtFee,
    double? platformFee,
    double? taxes,
    double? totalAmount,
    BookingStatus? status,
    String? paymentMethod,
    String? playerId,
    String? playerName,
    DateTime? createdAt,
  }) {
    return CourtBooking(
      id: id ?? this.id,
      bookingReference: bookingReference ?? this.bookingReference,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      venueCity: venueCity ?? this.venueCity,
      courtId: courtId ?? this.courtId,
      courtName: courtName ?? this.courtName,
      surfaceType: surfaceType ?? this.surfaceType,
      date: date ?? this.date,
      slotId: slotId ?? this.slotId,
      slotTime: slotTime ?? this.slotTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      courtFee: courtFee ?? this.courtFee,
      platformFee: platformFee ?? this.platformFee,
      taxes: taxes ?? this.taxes,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Whether the booking is cancelled.
  bool get isCancelled => status == BookingStatus.cancelled;

  /// Whether the booking is upcoming (today or future date, and not completed/cancelled).
  bool get isUpcoming {
    if (isCancelled || status == BookingStatus.completed) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(date.year, date.month, date.day);
    return bookingDay.isAfter(today) || bookingDay.isAtSameMomentAs(today);
  }

  /// Whether the booking is in the past or completed.
  bool get isPast {
    if (isCancelled) return false;
    if (status == BookingStatus.completed) return true;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(date.year, date.month, date.day);
    return bookingDay.isBefore(today);
  }

  /// Whether the booking can be cancelled by the player (upcoming and active).
  bool get canCancel =>
      isUpcoming &&
      (status == BookingStatus.confirmed || status == BookingStatus.paymentPending);

  /// Display text for payment status.
  String get paymentStatusDisplay {
    switch (status) {
      case BookingStatus.confirmed:
      case BookingStatus.paymentPending:
        return 'Pending (Pay at Venue)';
      case BookingStatus.completed:
        return 'Paid at Venue';
      case BookingStatus.cancelled:
        return 'Cancelled (No Payment Collected)';
    }
  }

  @override
  List<Object?> get props => [
        id,
        bookingReference,
        venueId,
        venueName,
        venueAddress,
        venueCity,
        courtId,
        courtName,
        surfaceType,
        date,
        slotId,
        slotTime,
        startTime,
        endTime,
        durationMinutes,
        courtFee,
        platformFee,
        taxes,
        totalAmount,
        status,
        paymentMethod,
        playerId,
        playerName,
        createdAt,
      ];
}
