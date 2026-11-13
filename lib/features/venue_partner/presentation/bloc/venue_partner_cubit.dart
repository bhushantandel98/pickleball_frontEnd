import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_partner/domain/repositories/venue_partner_repository.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_state.dart';

/// Cubit managing Venue Partner operations across Dashboard, Locations/Courts/Rules,
/// Calendar/Availability Blocks, Bookings/Manual Payments, Expenses, and Staff.
class VenuePartnerCubit extends Cubit<VenuePartnerState> {
  final VenuePartnerRepository repository;

  VenuePartnerCubit({
    required this.repository,
  }) : super(const VenuePartnerInitial());

  Future<void> loadWorkspace({String partnerId = 'org_venue_001'}) async {
    emit(const VenuePartnerLoading());
    final res = await repository.getWorkspaceData(partnerId: partnerId);
    switch (res) {
      case Success(:final data):
        emit(VenuePartnerLoaded(data: data));
      case FailureResult(:final failure):
        emit(VenuePartnerFailure(failure));
    }
  }

  Future<void> refreshWorkspace({String? partnerId}) async {
    final current = state;
    final resolvedId = partnerId ??
        (current is VenuePartnerLoaded
            ? current.data.profile.partnerId
            : 'org_venue_001');
    final res = await repository.getWorkspaceData(partnerId: resolvedId);
    switch (res) {
      case Success(:final data):
        if (current is VenuePartnerLoaded) {
          emit(current.copyWith(data: data, clearFeedback: true));
        } else {
          emit(VenuePartnerLoaded(data: data));
        }
      case FailureResult(:final failure):
        emit(VenuePartnerFailure(failure));
    }
  }

  void selectLocation(String? locationId) {
    final current = state;
    if (current is! VenuePartnerLoaded) return;
    emit(
      current.copyWith(
        selectedLocationId: locationId,
        clearLocationFilter: locationId == null,
        clearFeedback: true,
      ),
    );
  }

  void setBookingFilter(PartnerBookingStatus? status) {
    final current = state;
    if (current is! VenuePartnerLoaded) return;
    emit(
      current.copyWith(
        bookingFilter: status,
        clearBookingFilter: status == null,
        clearFeedback: true,
      ),
    );
  }

  void clearFeedback() {
    final current = state;
    if (current is VenuePartnerLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<bool> createLocation({
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int slotDurationMinutes,
    required int advanceBookingWindowDays,
    required int cancellationCutoffHours,
    required VenueBookingRuleConfirmationMode confirmationMode,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.createLocation(
      partnerId: current.data.profile.partnerId,
      name: name,
      city: city,
      address: address,
      operatingHours: operatingHours,
      slotDurationMinutes: slotDurationMinutes,
      advanceBookingWindowDays: advanceBookingWindowDays,
      cancellationCutoffHours: cancellationCutoffHours,
      confirmationMode: confirmationMode,
    );
    return _apply(res, 'Venue location created.');
  }

  Future<bool> updateLocationAndRules({
    required String locationId,
    required String name,
    required String city,
    required String address,
    required String operatingHours,
    required int slotDurationMinutes,
    required int advanceBookingWindowDays,
    required int cancellationCutoffHours,
    required VenueBookingRuleConfirmationMode confirmationMode,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.updateLocationAndRules(
      partnerId: current.data.profile.partnerId,
      locationId: locationId,
      name: name,
      city: city,
      address: address,
      operatingHours: operatingHours,
      slotDurationMinutes: slotDurationMinutes,
      advanceBookingWindowDays: advanceBookingWindowDays,
      cancellationCutoffHours: cancellationCutoffHours,
      confirmationMode: confirmationMode,
    );
    return _apply(res, 'Location & booking rules updated.');
  }

  Future<bool> toggleLocationStatus({
    required String locationId,
    required bool isActive,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.toggleLocationStatus(
      partnerId: current.data.profile.partnerId,
      locationId: locationId,
      isActive: isActive,
    );
    return _apply(
      res,
      isActive ? 'Location activated.' : 'Location deactivated.',
    );
  }

  Future<bool> createCourt({
    required String locationId,
    required String name,
    required String surfaceType,
    required bool isIndoor,
    required bool hasLighting,
    required double hourlyRateInr,
    required double peakHourlyRateInr,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.createCourt(
      partnerId: current.data.profile.partnerId,
      locationId: locationId,
      name: name,
      surfaceType: surfaceType,
      isIndoor: isIndoor,
      hasLighting: hasLighting,
      hourlyRateInr: hourlyRateInr,
      peakHourlyRateInr: peakHourlyRateInr,
    );
    return _apply(res, 'Court added.');
  }

  Future<bool> updateCourtPricing({
    required String courtId,
    required double hourlyRateInr,
    required double peakHourlyRateInr,
    required bool isActive,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.updateCourtPricing(
      partnerId: current.data.profile.partnerId,
      courtId: courtId,
      hourlyRateInr: hourlyRateInr,
      peakHourlyRateInr: peakHourlyRateInr,
      isActive: isActive,
    );
    return _apply(res, 'Court pricing & status updated.');
  }

  Future<bool> createAvailabilityBlock({
    required String courtId,
    required String title,
    required String reason,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.createAvailabilityBlock(
      partnerId: current.data.profile.partnerId,
      courtId: courtId,
      title: title,
      reason: reason,
      startTime: startTime,
      endTime: endTime,
    );
    return _apply(res, 'Court availability block added.');
  }

  Future<bool> removeAvailabilityBlock(String blockId) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.removeAvailabilityBlock(
      partnerId: current.data.profile.partnerId,
      blockId: blockId,
    );
    return _apply(res, 'Availability block removed.');
  }

  Future<bool> updateBookingStatus({
    required String bookingId,
    required PartnerBookingStatus newStatus,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.updateBookingStatus(
      partnerId: current.data.profile.partnerId,
      bookingId: bookingId,
      newStatus: newStatus,
    );
    return _apply(res, 'Booking status updated to ${newStatus.label}.');
  }

  Future<bool> recordManualPayment({
    required String bookingId,
    required ManualPaymentStatus paymentStatus,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.recordManualPayment(
      partnerId: current.data.profile.partnerId,
      bookingId: bookingId,
      paymentStatus: paymentStatus,
    );
    return _apply(res, 'Payment marked as ${paymentStatus.label}.');
  }

  Future<bool> addExpense({
    required String locationId,
    required String title,
    required String category,
    required double amountInr,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.addExpense(
      partnerId: current.data.profile.partnerId,
      locationId: locationId,
      title: title,
      category: category,
      amountInr: amountInr,
    );
    return _apply(res, 'Expense recorded.');
  }

  Future<bool> toggleStaffActive({
    required String staffAssignmentId,
    required bool isActive,
  }) async {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;
    final res = await repository.toggleStaffActive(
      partnerId: current.data.profile.partnerId,
      staffAssignmentId: staffAssignmentId,
      isActive: isActive,
    );
    return _apply(
      res,
      isActive ? 'Staff access enabled.' : 'Staff access paused.',
    );
  }

  bool _apply(Result<VenuePartnerWorkspaceData> res, String successMsg) {
    final current = state;
    if (current is! VenuePartnerLoaded) return false;

    switch (res) {
      case Success(:final data):
        emit(
          current.copyWith(
            data: data,
            feedbackMessage: successMsg,
            isErrorFeedback: false,
          ),
        );
        return true;
      case FailureResult(:final failure):
        emit(
          current.copyWith(
            feedbackMessage: failure.message,
            isErrorFeedback: true,
          ),
        );
        return false;
    }
  }
}
