import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';

/// Base state hierarchy for the Venue Partner module (Phase 3 — Feature 3.7).
sealed class VenuePartnerState extends Equatable {
  const VenuePartnerState();

  @override
  List<Object?> get props => [];
}

class VenuePartnerInitial extends VenuePartnerState {
  const VenuePartnerInitial();
}

class VenuePartnerLoading extends VenuePartnerState {
  const VenuePartnerLoading();
}

class VenuePartnerLoaded extends VenuePartnerState {
  final VenuePartnerWorkspaceData data;
  final String? selectedLocationId;
  final PartnerBookingStatus? bookingFilter;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const VenuePartnerLoaded({
    required this.data,
    this.selectedLocationId,
    this.bookingFilter,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

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

  List<VenueExpenseRecord> get scopedExpenses {
    if (selectedLocationId == null) return data.expenses;
    return data.expenses
        .where((e) => e.locationId == selectedLocationId)
        .toList();
  }

  List<VenueStaffAssignment> get scopedStaff {
    if (selectedLocationId == null) return data.staffAssignments;
    return data.staffAssignments
        .where((s) => s.locationId == selectedLocationId)
        .toList();
  }

  int get activeLocationCount =>
      data.locations.where((l) => l.isActive).length;

  int get activeCourtCount =>
      scopedCourts.where((c) => c.isActive).length;

  int get pendingBookingCount => data.bookings
      .where((b) =>
          (selectedLocationId == null || b.locationId == selectedLocationId) &&
          b.status == PartnerBookingStatus.pending)
      .length;

  double get collectedOfflineRevenueInr => data.bookings
      .where((b) =>
          (selectedLocationId == null || b.locationId == selectedLocationId) &&
          b.status != PartnerBookingStatus.cancelled &&
          b.status != PartnerBookingStatus.declined &&
          b.paymentStatus == ManualPaymentStatus.paidAtVenue)
      .fold<double>(0, (sum, b) => sum + b.amountInr);

  double get pendingOfflineRevenueInr => data.bookings
      .where((b) =>
          (selectedLocationId == null || b.locationId == selectedLocationId) &&
          b.status != PartnerBookingStatus.cancelled &&
          b.status != PartnerBookingStatus.declined &&
          b.paymentStatus != ManualPaymentStatus.paidAtVenue)
      .fold<double>(0, (sum, b) => sum + b.amountInr);

  double get totalExpensesInr =>
      scopedExpenses.fold<double>(0, (sum, e) => sum + e.amountInr);

  VenuePartnerLoaded copyWith({
    VenuePartnerWorkspaceData? data,
    String? selectedLocationId,
    bool clearLocationFilter = false,
    PartnerBookingStatus? bookingFilter,
    bool clearBookingFilter = false,
    String? feedbackMessage,
    bool clearFeedback = false,
    bool? isErrorFeedback,
  }) {
    return VenuePartnerLoaded(
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

class VenuePartnerFailure extends VenuePartnerState {
  final Failure failure;

  const VenuePartnerFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
