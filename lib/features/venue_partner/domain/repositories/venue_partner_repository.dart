import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';

/// Repository contract for the Venue Partner role module (Phase 3 — Feature 3.7).
///
/// Strictly scoped to the authenticated Venue Partner's authorized `partnerId`.
/// Enforces tenant ownership, booking lifecycle rules, and V1 offline-only
/// manual payment tracking.
abstract class VenuePartnerRepository {
  Future<Result<VenuePartnerWorkspaceData>> getWorkspaceData({
    required String partnerId,
  });

  Future<Result<VenuePartnerWorkspaceData>> createLocation({
    required String partnerId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int slotDurationMinutes,
    required int advanceBookingWindowDays,
    required int cancellationCutoffHours,
    required VenueBookingRuleConfirmationMode confirmationMode,
  });

  Future<Result<VenuePartnerWorkspaceData>> updateLocationAndRules({
    required String partnerId,
    required String locationId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int slotDurationMinutes,
    required int advanceBookingWindowDays,
    required int cancellationCutoffHours,
    required VenueBookingRuleConfirmationMode confirmationMode,
  });

  Future<Result<VenuePartnerWorkspaceData>> toggleLocationStatus({
    required String partnerId,
    required String locationId,
    required bool isActive,
  });

  Future<Result<VenuePartnerWorkspaceData>> createCourt({
    required String partnerId,
    required String locationId,
    required String name,
    required String surfaceType,
    required bool isIndoor,
    required bool hasLighting,
    required double hourlyRateInr,
    required double peakHourlyRateInr,
  });

  Future<Result<VenuePartnerWorkspaceData>> updateCourtPricing({
    required String partnerId,
    required String courtId,
    required double hourlyRateInr,
    required double peakHourlyRateInr,
    required bool isActive,
  });

  Future<Result<VenuePartnerWorkspaceData>> createAvailabilityBlock({
    required String partnerId,
    required String courtId,
    required String title,
    required String reason,
    required DateTime startTime,
    required DateTime endTime,
  });

  Future<Result<VenuePartnerWorkspaceData>> removeAvailabilityBlock({
    required String partnerId,
    required String blockId,
  });

  Future<Result<VenuePartnerWorkspaceData>> updateBookingStatus({
    required String partnerId,
    required String bookingId,
    required PartnerBookingStatus newStatus,
  });

  Future<Result<VenuePartnerWorkspaceData>> recordManualPayment({
    required String partnerId,
    required String bookingId,
    required ManualPaymentStatus paymentStatus,
  });

  Future<Result<VenuePartnerWorkspaceData>> addExpense({
    required String partnerId,
    required String locationId,
    required String title,
    required String category,
    required double amountInr,
  });

  Future<Result<VenuePartnerWorkspaceData>> toggleStaffActive({
    required String partnerId,
    required String staffAssignmentId,
    required bool isActive,
  });
}
