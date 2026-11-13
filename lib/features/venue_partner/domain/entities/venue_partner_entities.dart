import 'package:equatable/equatable.dart';

/// Booking confirmation mode configured per venue location.
enum VenueBookingRuleConfirmationMode {
  autoConfirm('Auto-Confirm'),
  manualApproval('Manual Approval');

  final String label;
  const VenueBookingRuleConfirmationMode(this.label);
}

/// Court booking lifecycle status managed by Venue Partner.
enum PartnerBookingStatus {
  pending('Pending Approval'),
  confirmed('Confirmed'),
  checkedIn('Checked In'),
  completed('Completed'),
  cancelled('Cancelled'),
  declined('Declined');

  final String label;
  const PartnerBookingStatus(this.label);
}

/// Offline/manual payment status in V1.
/// Online Razorpay checkout and platform refund execution are excluded in V1.
enum ManualPaymentStatus {
  unpaid('Unpaid'),
  paidAtVenue('Paid at Venue'),
  pendingVerification('Pending Verification');

  final String label;
  const ManualPaymentStatus(this.label);
}

/// Top-level Venue Partner organization profile.
class VenuePartnerProfile extends Equatable {
  final String partnerId;
  final String partnerName;
  final String ownerName;
  final String contactEmail;
  final String contactPhone;

  const VenuePartnerProfile({
    required this.partnerId,
    required this.partnerName,
    required this.ownerName,
    required this.contactEmail,
    required this.contactPhone,
  });

  @override
  List<Object?> get props => [
        partnerId,
        partnerName,
        ownerName,
        contactEmail,
        contactPhone,
      ];
}

/// Physical venue location owned by the Venue Partner, including booking rules.
class VenueLocation extends Equatable {
  final String id;
  final String partnerId;
  final String name;
  final String city;
  final String address;
  final String operatingHours;
  final int slotDurationMinutes;
  final int advanceBookingWindowDays;
  final int cancellationCutoffHours;
  final VenueBookingRuleConfirmationMode confirmationMode;
  final bool isActive;

  const VenueLocation({
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
    this.isActive = true,
  });

  VenueLocation copyWith({
    String? name,
    String? city,
    String? address,
    String? operatingHours,
    int? slotDurationMinutes,
    int? advanceBookingWindowDays,
    int? cancellationCutoffHours,
    VenueBookingRuleConfirmationMode? confirmationMode,
    bool? isActive,
  }) {
    return VenueLocation(
      id: id,
      partnerId: partnerId,
      name: name ?? this.name,
      city: city ?? this.city,
      address: address ?? this.address,
      operatingHours: operatingHours ?? this.operatingHours,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      advanceBookingWindowDays:
          advanceBookingWindowDays ?? this.advanceBookingWindowDays,
      cancellationCutoffHours:
          cancellationCutoffHours ?? this.cancellationCutoffHours,
      confirmationMode: confirmationMode ?? this.confirmationMode,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partnerId,
        name,
        city,
        address,
        operatingHours,
        slotDurationMinutes,
        advanceBookingWindowDays,
        cancellationCutoffHours,
        confirmationMode,
        isActive,
      ];
}

/// Individual pickleball court inside a [VenueLocation] with standard & peak pricing.
class VenueCourt extends Equatable {
  final String id;
  final String partnerId;
  final String locationId;
  final String locationName;
  final String name;
  final String surfaceType;
  final bool isIndoor;
  final bool hasLighting;
  final double hourlyRateInr;
  final double peakHourlyRateInr;
  final bool isActive;

  const VenueCourt({
    required this.id,
    required this.partnerId,
    required this.locationId,
    required this.locationName,
    required this.name,
    required this.surfaceType,
    required this.isIndoor,
    required this.hasLighting,
    required this.hourlyRateInr,
    required this.peakHourlyRateInr,
    this.isActive = true,
  });

  VenueCourt copyWith({
    String? name,
    String? surfaceType,
    bool? isIndoor,
    bool? hasLighting,
    double? hourlyRateInr,
    double? peakHourlyRateInr,
    bool? isActive,
  }) {
    return VenueCourt(
      id: id,
      partnerId: partnerId,
      locationId: locationId,
      locationName: locationName,
      name: name ?? this.name,
      surfaceType: surfaceType ?? this.surfaceType,
      isIndoor: isIndoor ?? this.isIndoor,
      hasLighting: hasLighting ?? this.hasLighting,
      hourlyRateInr: hourlyRateInr ?? this.hourlyRateInr,
      peakHourlyRateInr: peakHourlyRateInr ?? this.peakHourlyRateInr,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partnerId,
        locationId,
        locationName,
        name,
        surfaceType,
        isIndoor,
        hasLighting,
        hourlyRateInr,
        peakHourlyRateInr,
        isActive,
      ];
}

/// Maintenance or private hold block on a court's availability calendar.
class CourtAvailabilityBlock extends Equatable {
  final String id;
  final String partnerId;
  final String locationId;
  final String courtId;
  final String courtName;
  final String title;
  final String reason;
  final DateTime startTime;
  final DateTime endTime;

  const CourtAvailabilityBlock({
    required this.id,
    required this.partnerId,
    required this.locationId,
    required this.courtId,
    required this.courtName,
    required this.title,
    required this.reason,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [
        id,
        partnerId,
        locationId,
        courtId,
        courtName,
        title,
        reason,
        startTime,
        endTime,
      ];
}

/// Court booking record managed by the Venue Partner.
class VenuePartnerBooking extends Equatable {
  final String id;
  final String partnerId;
  final String locationId;
  final String locationName;
  final String courtId;
  final String courtName;
  final String playerName;
  final String playerPhone;
  final DateTime slotStart;
  final DateTime slotEnd;
  final double amountInr;
  final PartnerBookingStatus status;
  final ManualPaymentStatus paymentStatus;
  final String? notes;

  const VenuePartnerBooking({
    required this.id,
    required this.partnerId,
    required this.locationId,
    required this.locationName,
    required this.courtId,
    required this.courtName,
    required this.playerName,
    required this.playerPhone,
    required this.slotStart,
    required this.slotEnd,
    required this.amountInr,
    required this.status,
    required this.paymentStatus,
    this.notes,
  });

  VenuePartnerBooking copyWith({
    PartnerBookingStatus? status,
    ManualPaymentStatus? paymentStatus,
    String? notes,
  }) {
    return VenuePartnerBooking(
      id: id,
      partnerId: partnerId,
      locationId: locationId,
      locationName: locationName,
      courtId: courtId,
      courtName: courtName,
      playerName: playerName,
      playerPhone: playerPhone,
      slotStart: slotStart,
      slotEnd: slotEnd,
      amountInr: amountInr,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partnerId,
        locationId,
        locationName,
        courtId,
        courtName,
        playerName,
        playerPhone,
        slotStart,
        slotEnd,
        amountInr,
        status,
        paymentStatus,
        notes,
      ];
}

/// Venue Staff delegation record managed exclusively by the Venue Partner.
class VenueStaffAssignment extends Equatable {
  final String id;
  final String partnerId;
  final String locationId;
  final String locationName;
  final String staffName;
  final String staffEmail;
  final String roleTitle;
  final List<String> permissions;
  final bool isActive;

  const VenueStaffAssignment({
    required this.id,
    required this.partnerId,
    required this.locationId,
    required this.locationName,
    required this.staffName,
    required this.staffEmail,
    required this.roleTitle,
    required this.permissions,
    this.isActive = true,
  });

  VenueStaffAssignment copyWith({
    List<String>? permissions,
    bool? isActive,
  }) {
    return VenueStaffAssignment(
      id: id,
      partnerId: partnerId,
      locationId: locationId,
      locationName: locationName,
      staffName: staffName,
      staffEmail: staffEmail,
      roleTitle: roleTitle,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        partnerId,
        locationId,
        locationName,
        staffName,
        staffEmail,
        roleTitle,
        permissions,
        isActive,
      ];
}

/// Venue operational expense / purchase record.
class VenueExpenseRecord extends Equatable {
  final String id;
  final String partnerId;
  final String locationId;
  final String locationName;
  final String title;
  final String category;
  final double amountInr;
  final DateTime recordedAt;
  final String submittedBy;

  const VenueExpenseRecord({
    required this.id,
    required this.partnerId,
    required this.locationId,
    required this.locationName,
    required this.title,
    required this.category,
    required this.amountInr,
    required this.recordedAt,
    required this.submittedBy,
  });

  @override
  List<Object?> get props => [
        id,
        partnerId,
        locationId,
        locationName,
        title,
        category,
        amountInr,
        recordedAt,
        submittedBy,
      ];
}

/// Aggregated Venue Partner workspace data strictly scoped to [profile.partnerId].
class VenuePartnerWorkspaceData extends Equatable {
  final VenuePartnerProfile profile;
  final List<VenueLocation> locations;
  final List<VenueCourt> courts;
  final List<CourtAvailabilityBlock> availabilityBlocks;
  final List<VenuePartnerBooking> bookings;
  final List<VenueStaffAssignment> staffAssignments;
  final List<VenueExpenseRecord> expenses;

  const VenuePartnerWorkspaceData({
    required this.profile,
    required this.locations,
    required this.courts,
    required this.availabilityBlocks,
    required this.bookings,
    required this.staffAssignments,
    required this.expenses,
  });

  @override
  List<Object?> get props => [
        profile,
        locations,
        courts,
        availabilityBlocks,
        bookings,
        staffAssignments,
        expenses,
      ];
}
