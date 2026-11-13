import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_staff/domain/entities/venue_staff_entities.dart';

/// Repository contract for the Venue Staff role module (Phase 3 — Feature 3.8).
///
/// Strictly enforces:
/// 1. Partner ownership (`partnerId` must match the staff member's venue partner).
/// 2. Assigned location scoping (`locationId` must be in `assignedLocationIds`).
/// 3. Delegated permission checks at the repository boundary.
/// 4. No partner-only operations (pricing, booking rules, or staff permission edits).
abstract class VenueStaffRepository {
  Future<Result<VenueStaffWorkspaceData>> getWorkspaceData({
    required String partnerId,
    required String staffId,
  });

  Future<Result<VenueStaffWorkspaceData>> updateBookingOperationalStatus({
    required String partnerId,
    required String staffId,
    required String bookingId,
    required PartnerBookingStatus newStatus,
  });

  Future<Result<VenueStaffWorkspaceData>> recordOfflinePayment({
    required String partnerId,
    required String staffId,
    required String bookingId,
    required ManualPaymentStatus paymentStatus,
  });

  Future<Result<VenueStaffWorkspaceData>> updateMaintenanceTaskStatus({
    required String partnerId,
    required String staffId,
    required String taskId,
    required VenueMaintenanceTaskStatus status,
  });

  Future<Result<VenueStaffWorkspaceData>> createCourtMaintenanceBlock({
    required String partnerId,
    required String staffId,
    required String courtId,
    required String title,
    required String reason,
    required DateTime startTime,
    required DateTime endTime,
  });

  Future<Result<VenueStaffWorkspaceData>> submitPurchaseWithReceipt({
    required String partnerId,
    required String staffId,
    required String locationId,
    required String title,
    required String category,
    required double amountInr,
    required String receiptReference,
  });
}
