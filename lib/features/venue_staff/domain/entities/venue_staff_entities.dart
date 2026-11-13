import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';

/// Delegated permissions assignable to Venue Staff by a Venue Partner.
///
/// Staff cannot self-escalate permissions and never receive partner-only
/// privileges (venue/location creation, court pricing, booking rules, or staff
/// permission management).
enum VenueStaffPermission {
  viewDashboard('View Dashboard'),
  manageCheckIn('Booking Check-in & Operations'),
  manageMaintenance('Availability & Maintenance Tasks'),
  submitPurchases('Submit Purchase Receipts'),
  recordOfflinePayments('Record Offline Payments'),
  viewReports('View Permitted Reports');

  final String label;
  const VenueStaffPermission(this.label);
}

/// Lifecycle status for venue maintenance / operational tasks.
enum VenueMaintenanceTaskStatus {
  open('Open'),
  inProgress('In Progress'),
  completed('Completed');

  final String label;
  const VenueMaintenanceTaskStatus(this.label);
}

/// Authenticated Venue Staff profile and delegated location/permission scope.
class VenueStaffProfile extends Equatable {
  final String staffId;
  final String partnerId;
  final String partnerName;
  final String staffName;
  final String staffEmail;
  final String roleTitle;
  final List<String> assignedLocationIds;
  final List<String> assignedLocationNames;
  final Set<VenueStaffPermission> permissions;
  final bool isActive;

  const VenueStaffProfile({
    required this.staffId,
    required this.partnerId,
    required this.partnerName,
    required this.staffName,
    required this.staffEmail,
    required this.roleTitle,
    required this.assignedLocationIds,
    required this.assignedLocationNames,
    required this.permissions,
    this.isActive = true,
  });

  bool hasPermission(VenueStaffPermission permission) =>
      isActive && permissions.contains(permission);

  bool canAccessLocation(String locationId) =>
      isActive && assignedLocationIds.contains(locationId);

  @override
  List<Object?> get props => [
        staffId,
        partnerId,
        partnerName,
        staffName,
        staffEmail,
        roleTitle,
        assignedLocationIds,
        assignedLocationNames,
        permissions,
        isActive,
      ];
}

/// Operational maintenance task assigned to a Venue Staff location.
class VenueMaintenanceTask extends Equatable {
  final String id;
  final String partnerId;
  final String locationId;
  final String locationName;
  final String courtId;
  final String courtName;
  final String title;
  final String description;
  final VenueMaintenanceTaskStatus status;
  final String assignedToStaffId;
  final DateTime updatedAt;

  const VenueMaintenanceTask({
    required this.id,
    required this.partnerId,
    required this.locationId,
    required this.locationName,
    required this.courtId,
    required this.courtName,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedToStaffId,
    required this.updatedAt,
  });

  VenueMaintenanceTask copyWith({
    VenueMaintenanceTaskStatus? status,
    DateTime? updatedAt,
  }) {
    return VenueMaintenanceTask(
      id: id,
      partnerId: partnerId,
      locationId: locationId,
      locationName: locationName,
      courtId: courtId,
      courtName: courtName,
      title: title,
      description: description,
      status: status ?? this.status,
      assignedToStaffId: assignedToStaffId,
      updatedAt: updatedAt ?? this.updatedAt,
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
        title,
        description,
        status,
        assignedToStaffId,
        updatedAt,
      ];
}

/// Purchase / expense submission with receipt reference logged by Venue Staff.
class VenuePurchaseSubmission extends Equatable {
  final String id;
  final String partnerId;
  final String locationId;
  final String locationName;
  final String title;
  final String category;
  final double amountInr;
  final String receiptReference;
  final String submittedByStaffId;
  final String submittedByName;
  final DateTime submittedAt;

  const VenuePurchaseSubmission({
    required this.id,
    required this.partnerId,
    required this.locationId,
    required this.locationName,
    required this.title,
    required this.category,
    required this.amountInr,
    required this.receiptReference,
    required this.submittedByStaffId,
    required this.submittedByName,
    required this.submittedAt,
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
        receiptReference,
        submittedByStaffId,
        submittedByName,
        submittedAt,
      ];
}

/// Aggregated Venue Staff workspace scoped strictly to [staffProfile.partnerId],
/// [staffProfile.assignedLocationIds], and [staffProfile.permissions].
class VenueStaffWorkspaceData extends Equatable {
  final VenueStaffProfile staffProfile;
  final List<VenueLocation> assignedLocations;
  final List<VenueCourt> courts;
  final List<CourtAvailabilityBlock> availabilityBlocks;
  final List<VenuePartnerBooking> bookings;
  final List<VenueMaintenanceTask> maintenanceTasks;
  final List<VenuePurchaseSubmission> purchaseSubmissions;

  const VenueStaffWorkspaceData({
    required this.staffProfile,
    required this.assignedLocations,
    required this.courts,
    required this.availabilityBlocks,
    required this.bookings,
    required this.maintenanceTasks,
    required this.purchaseSubmissions,
  });

  @override
  List<Object?> get props => [
        staffProfile,
        assignedLocations,
        courts,
        availabilityBlocks,
        bookings,
        maintenanceTasks,
        purchaseSubmissions,
      ];
}
