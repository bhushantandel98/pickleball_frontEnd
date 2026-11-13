import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';

/// DTO for [VenueLocation] API serialization.
class VenueLocationModel {
  final String id;
  final String partnerId;
  final String name;
  final String city;
  final String address;
  final String operatingHours;
  final int slotDurationMinutes;
  final int advanceBookingWindowDays;
  final int cancellationCutoffHours;
  final String confirmationMode;
  final bool isActive;

  const VenueLocationModel({
    required this.id,
    required this.partnerId,
    required this.name,
    required this.city,
    required this.address,
    required this.operatingHours,
    required this.slotDurationMinutes,
    required this.advanceBookingWindowDays,
    required this.cancellationCutoffHours,
    required this.confirmationMode,
    required this.isActive,
  });

  factory VenueLocationModel.fromJson(Map<String, dynamic> json) {
    return VenueLocationModel(
      id: json['id'] as String? ?? '',
      partnerId: json['partnerId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      operatingHours: json['operatingHours'] as String? ?? '06:00 AM – 10:00 PM',
      slotDurationMinutes: (json['slotDurationMinutes'] as num?)?.toInt() ?? 60,
      advanceBookingWindowDays:
          (json['advanceBookingWindowDays'] as num?)?.toInt() ?? 14,
      cancellationCutoffHours:
          (json['cancellationCutoffHours'] as num?)?.toInt() ?? 6,
      confirmationMode: json['confirmationMode'] as String? ?? 'AUTO_CONFIRM',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  VenueLocation toEntity() {
    final normalizedMode = confirmationMode
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z]'), '')
        .toLowerCase();
    final mode = normalizedMode == 'manualapproval'
        ? VenueBookingRuleConfirmationMode.manualApproval
        : VenueBookingRuleConfirmationMode.autoConfirm;

    return VenueLocation(
      id: id,
      partnerId: partnerId,
      name: name,
      city: city,
      address: address,
      operatingHours: operatingHours,
      slotDurationMinutes: slotDurationMinutes,
      advanceBookingWindowDays: advanceBookingWindowDays,
      cancellationCutoffHours: cancellationCutoffHours,
      confirmationMode: mode,
      isActive: isActive,
    );
  }
}

/// DTO for [VenuePartnerBooking] API serialization.
class VenuePartnerBookingModel {
  final String id;
  final String partnerId;
  final String locationId;
  final String courtId;
  final String status;
  final String paymentStatus;

  const VenuePartnerBookingModel({
    required this.id,
    required this.partnerId,
    required this.locationId,
    required this.courtId,
    required this.status,
    required this.paymentStatus,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'partnerId': partnerId,
        'locationId': locationId,
        'courtId': courtId,
        'status': status,
        'paymentStatus': paymentStatus,
      };
}
