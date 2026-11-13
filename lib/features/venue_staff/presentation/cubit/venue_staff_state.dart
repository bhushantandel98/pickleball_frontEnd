import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_staff/domain/entities/venue_staff_entities.dart';

/// Base state hierarchy for the Venue Staff module (Phase 3 — Feature 3.8).
sealed class VenueStaffState extends Equatable {
  const VenueStaffState();

  @override
  List<Object?> get props => [];
}

class VenueStaffInitial extends VenueStaffState {
  const VenueStaffInitial();
}

class VenueStaffLoading extends VenueStaffState {
  const VenueStaffLoading();
}

class VenueStaffLoaded extends VenueStaffState {
  final VenueStaffWorkspaceData data;
  final String? selectedLocationId;
  final PartnerBookingStatus? bookingFilter;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const VenueStaffLoaded({
    required this.data,
    this.selectedLocationId,
    this.bookingFilter,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  VenueStaffProfile get staffProfile => data.staffProfile;

  bool hasPermission(VenueStaffPermission permission) =>
      data.staffProfile.hasPermission(permission);

  List<VenueCourt> get scopedCourts {
    if (selectedLocationId == null) return data.courts;
    return data.courts
        .where((c) => c.locationId == selectedLocationId)
        .toList();
  }

  List<CourtAvailabilityBlock> get scopedBlocks {
    if (selectedLocationId == null) return data.availabilityBlocks;
    return data.availabilityBlocks
        .where((b) => b.locationId == selectedLocationId)
        .toList();
  }

  List<VenuePartnerBooking> get scopedBookings {
    return data.bookings.where((b) {
      if (selectedLocationId != null && b.locationId != selectedLocationId) {
        return false;
      }
      if (bookingFilter != null && b.status != bookingFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  List<VenueMaintenanceTask> get scopedTasks {
    if (selectedLocationId == null) return data.maintenanceTasks;
    return data.maintenanceTasks
        .where((t) => t.locationId == selectedLocationId)
        .toList();
  }

  List<VenuePurchaseSubmission> get scopedPurchases {
    if (selectedLocationId == null) return data.purchaseSubmissions;
    return data.purchaseSubmissions
        .where((p) => p.locationId == selectedLocationId)
        .toList();
  }

  int get openTaskCount => scopedTasks
      .where((t) => t.status != VenueMaintenanceTaskStatus.completed)
      .length;

  int get checkedInCount => data.bookings
      .where((b) =>
          (selectedLocationId == null || b.locationId == selectedLocationId) &&
          b.status == PartnerBookingStatus.checkedIn)
      .length;

  double get collectedOfflineInr => data.bookings
      .where((b) =>
          (selectedLocationId == null || b.locationId == selectedLocationId) &&
          b.status != PartnerBookingStatus.cancelled &&
          b.status != PartnerBookingStatus.declined &&
          b.paymentStatus == ManualPaymentStatus.paidAtVenue)
      .fold<double>(0, (sum, b) => sum + b.amountInr);

  VenueStaffLoaded copyWith({
    VenueStaffWorkspaceData? data,
    String? selectedLocationId,
    bool clearLocationFilter = false,
    PartnerBookingStatus? bookingFilter,
    bool clearBookingFilter = false,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? isErrorFeedback,
  }) {
    return VenueStaffLoaded(
      data: data ?? this.data,
      selectedLocationId: clearLocationFilter
          ? null
          : (selectedLocationId ?? this.selectedLocationId),
      bookingFilter:
          clearBookingFilter ? null : (bookingFilter ?? this.bookingFilter),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isErrorFeedback:
          clearFeedback ? false : (isErrorFeedback ?? this.isErrorFeedback),
    );
  }

  @override
  List<Object?> get props => [
        data,
        selectedLocationId,
        bookingFilter,
        feedbackMessage,
        isErrorFeedback,
      ];
}

class VenueStaffFailure extends VenueStaffState {
  final Failure failure;

  const VenueStaffFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
