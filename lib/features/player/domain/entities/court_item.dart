import 'package:equatable/equatable.dart';

/// Status of an individual court time-slot.
enum SlotStatus {
  available('Available'),
  booked('Booked'),
  unavailable('Unavailable');

  final String displayName;
  const SlotStatus(this.displayName);
}

/// Representation of a bookable time-slot on a specific court.
class CourtSlot extends Equatable {
  final String id;
  final String courtId;
  final String venueId;
  final String startTime;
  final String endTime;
  final double price;
  final SlotStatus status;

  const CourtSlot({
    required this.id,
    required this.courtId,
    required this.venueId,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.status,
  });

  bool get isAvailable => status == SlotStatus.available;
  bool get isBooked => status == SlotStatus.booked;
  bool get isUnavailable => status == SlotStatus.unavailable;

  String get formattedTime => '$startTime - $endTime';

  CourtSlot copyWith({
    String? id,
    String? courtId,
    String? venueId,
    String? startTime,
    String? endTime,
    double? price,
    SlotStatus? status,
  }) {
    return CourtSlot(
      id: id ?? this.id,
      courtId: courtId ?? this.courtId,
      venueId: venueId ?? this.venueId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      price: price ?? this.price,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        courtId,
        venueId,
        startTime,
        endTime,
        price,
        status,
      ];
}

/// Representation of an individual court within a venue.
class CourtItem extends Equatable {
  final String id;
  final String venueId;
  final String name;
  final int courtNumber;
  final String surfaceType;
  final bool isIndoor;
  final bool hasLighting;
  final bool isActive;
  final int availableSlotCount;

  const CourtItem({
    required this.id,
    required this.venueId,
    required this.name,
    required this.courtNumber,
    required this.surfaceType,
    required this.isIndoor,
    required this.hasLighting,
    this.isActive = true,
    this.availableSlotCount = 0,
  });

  CourtItem copyWith({
    String? id,
    String? venueId,
    String? name,
    int? courtNumber,
    String? surfaceType,
    bool? isIndoor,
    bool? hasLighting,
    bool? isActive,
    int? availableSlotCount,
  }) {
    return CourtItem(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      name: name ?? this.name,
      courtNumber: courtNumber ?? this.courtNumber,
      surfaceType: surfaceType ?? this.surfaceType,
      isIndoor: isIndoor ?? this.isIndoor,
      hasLighting: hasLighting ?? this.hasLighting,
      isActive: isActive ?? this.isActive,
      availableSlotCount: availableSlotCount ?? this.availableSlotCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        venueId,
        name,
        courtNumber,
        surfaceType,
        isIndoor,
        hasLighting,
        isActive,
        availableSlotCount,
      ];
}

/// Navigation payload passing selected venue, court, date, slot, and price to the next booking step.
class BookingSelectionPayload extends Equatable {
  final String venueId;
  final String venueName;
  final String courtId;
  final String courtName;
  final String surfaceType;
  final DateTime date;
  final String slotId;
  final String slotTime;
  final double price;
  final String? venueAddress;
  final String? venueCity;
  final int durationMinutes;

  const BookingSelectionPayload({
    required this.venueId,
    required this.venueName,
    required this.courtId,
    required this.courtName,
    required this.surfaceType,
    required this.date,
    required this.slotId,
    required this.slotTime,
    required this.price,
    this.venueAddress,
    this.venueCity,
    this.durationMinutes = 60,
  });

  bool get isValid =>
      venueId.trim().isNotEmpty &&
      venueName.trim().isNotEmpty &&
      courtId.trim().isNotEmpty &&
      courtName.trim().isNotEmpty &&
      slotId.trim().isNotEmpty &&
      slotTime.trim().isNotEmpty &&
      price > 0;

  String get startTime {
    if (slotTime.contains('-')) {
      return slotTime.split('-').first.trim();
    }
    return slotTime;
  }

  String get endTime {
    if (slotTime.contains('-')) {
      return slotTime.split('-').last.trim();
    }
    return '';
  }

  @override
  List<Object?> get props => [
        venueId,
        venueName,
        courtId,
        courtName,
        surfaceType,
        date,
        slotId,
        slotTime,
        price,
        venueAddress,
        venueCity,
        durationMinutes,
      ];
}
