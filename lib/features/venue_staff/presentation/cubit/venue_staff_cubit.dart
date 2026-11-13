import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_staff/domain/entities/venue_staff_entities.dart';
import 'package:pickleball_platform/features/venue_staff/domain/repositories/venue_staff_repository.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/cubit/venue_staff_state.dart';

/// Cubit managing delegated Venue Staff daily operations across assigned locations.
class VenueStaffCubit extends Cubit<VenueStaffState> {
  final VenueStaffRepository repository;

  VenueStaffCubit({
    required this.repository,
  }) : super(const VenueStaffInitial());

  Future<void> loadWorkspace({
    required String partnerId,
    required String staffId,
  }) async {
    emit(const VenueStaffLoading());
    final res = await repository.getWorkspaceData(
      partnerId: partnerId,
      staffId: staffId,
    );
    switch (res) {
      case Success(:final data):
        emit(VenueStaffLoaded(data: data));
      case FailureResult(:final failure):
        emit(VenueStaffFailure(failure));
    }
  }

  Future<void> refreshWorkspace({
    String? partnerId,
    String? staffId,
  }) async {
    final current = state;
    final resolvedPartnerId = partnerId ??
        (current is VenueStaffLoaded
            ? current.staffProfile.partnerId
            : 'org_venue_001');
    final resolvedStaffId = staffId ??
        (current is VenueStaffLoaded
            ? current.staffProfile.staffId
            : 'user_venue_staff_001');

    final res = await repository.getWorkspaceData(
      partnerId: resolvedPartnerId,
      staffId: resolvedStaffId,
    );
    switch (res) {
      case Success(:final data):
        if (current is VenueStaffLoaded) {
          emit(current.copyWith(data: data, clearFeedback: true));
        } else {
          emit(VenueStaffLoaded(data: data));
        }
      case FailureResult(:final failure):
        emit(VenueStaffFailure(failure));
    }
  }

  void selectLocation(String? locationId) {
    final current = state;
    if (current is! VenueStaffLoaded) return;
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
    if (current is! VenueStaffLoaded) return;
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
    if (current is VenueStaffLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<bool> updateBookingStatus({
    required String bookingId,
    required PartnerBookingStatus newStatus,
  }) async {
    final current = state;
    if (current is! VenueStaffLoaded) return false;
    final res = await repository.updateBookingOperationalStatus(
      partnerId: current.staffProfile.partnerId,
      staffId: current.staffProfile.staffId,
      bookingId: bookingId,
      newStatus: newStatus,
    );
    return _apply(res, 'Booking status updated to ${newStatus.label}.');
  }

  Future<bool> recordOfflinePayment({
    required String bookingId,
    required ManualPaymentStatus paymentStatus,
  }) async {
    final current = state;
    if (current is! VenueStaffLoaded) return false;
    final res = await repository.recordOfflinePayment(
      partnerId: current.staffProfile.partnerId,
      staffId: current.staffProfile.staffId,
      bookingId: bookingId,
      paymentStatus: paymentStatus,
    );
    return _apply(res, 'Offline payment marked as ${paymentStatus.label}.');
  }

  Future<bool> updateTaskStatus({
    required String taskId,
    required VenueMaintenanceTaskStatus status,
  }) async {
    final current = state;
    if (current is! VenueStaffLoaded) return false;
    final res = await repository.updateMaintenanceTaskStatus(
      partnerId: current.staffProfile.partnerId,
      staffId: current.staffProfile.staffId,
      taskId: taskId,
      status: status,
    );
    return _apply(res, 'Maintenance task marked ${status.label}.');
  }

  Future<bool> createMaintenanceBlock({
    required String courtId,
    required String title,
    required String reason,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final current = state;
    if (current is! VenueStaffLoaded) return false;
    final res = await repository.createCourtMaintenanceBlock(
      partnerId: current.staffProfile.partnerId,
      staffId: current.staffProfile.staffId,
      courtId: courtId,
      title: title,
      reason: reason,
      startTime: startTime,
      endTime: endTime,
    );
    return _apply(res, 'Court maintenance block created.');
  }

  Future<bool> submitPurchaseReceipt({
    required String locationId,
    required String title,
    required String category,
    required double amountInr,
    required String receiptReference,
  }) async {
    final current = state;
    if (current is! VenueStaffLoaded) return false;
    final res = await repository.submitPurchaseWithReceipt(
      partnerId: current.staffProfile.partnerId,
      staffId: current.staffProfile.staffId,
      locationId: locationId,
      title: title,
      category: category,
      amountInr: amountInr,
      receiptReference: receiptReference,
    );
    return _apply(res, 'Purchase receipt submitted.');
  }

  bool _apply(Result<VenueStaffWorkspaceData> res, String successMsg) {
    final current = state;
    if (current is! VenueStaffLoaded) return false;

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
