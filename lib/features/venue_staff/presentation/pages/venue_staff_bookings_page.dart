import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_location_filter_bar.dart';
import 'package:pickleball_platform/features/venue_staff/domain/entities/venue_staff_entities.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/cubit/venue_staff_cubit.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/widgets/venue_staff_page_scaffold.dart';

/// Venue Staff daily booking operations & check-in screen (Phase 3 — Feature 3.8).
class VenueStaffBookingsPage extends StatelessWidget {
  final VenueStaffCubit? cubit;
  final String? partnerId;
  final String? staffId;

  const VenueStaffBookingsPage({
    super.key,
    this.cubit,
    this.partnerId,
    this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    return VenueStaffPageScaffold(
      cubit: cubit,
      partnerId: partnerId,
      staffId: staffId,
      title: 'Daily Check-in & Bookings',
      subtitle:
          'Manage check-ins, operational booking statuses, and offline payments for assigned locations.',
      bodyBuilder: (context, state) {
        final canCheckIn =
            state.hasPermission(VenueStaffPermission.manageCheckIn);
        final canRecordPayment =
            state.hasPermission(VenueStaffPermission.recordOfflinePayments);

        if (!canCheckIn && !canRecordPayment) {
          return const EmptyStateView(
            title: 'Booking Operations Restricted',
            message:
                'You do not have delegated check-in or offline payment permissions.',
          );
        }

        final cubit = context.read<VenueStaffCubit>();
        final bookings = state.scopedBookings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.data.assignedLocations.length > 1) ...[
                    VenueLocationFilterBar(
                      locations: state.data.assignedLocations,
                      selectedLocationId: state.selectedLocationId,
                      onLocationSelected: cubit.selectLocation,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      ChoiceChip(
                        label: const Text('All Statuses'),
                        selected: state.bookingFilter == null,
                        onSelected: (_) => cubit.setBookingFilter(null),
                      ),
                      ...PartnerBookingStatus.values.map(
                        (status) => ChoiceChip(
                          label: Text(status.label),
                          selected: state.bookingFilter == status,
                          onSelected: (_) => cubit.setBookingFilter(status),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (bookings.isEmpty)
              const EmptyStateView(
                title: 'No Matching Bookings',
                message:
                    'No bookings match the selected location or status filter.',
              )
            else
              ...bookings.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _BookingOperationCard(
                    booking: booking,
                    canCheckIn: canCheckIn,
                    canRecordPayment: canRecordPayment,
                    onUpdateStatus: (status) => _confirmAndUpdateStatus(
                      context,
                      cubit,
                      booking,
                      status,
                    ),
                    onRecordOfflinePayment: () => cubit.recordOfflinePayment(
                      bookingId: booking.id,
                      paymentStatus: ManualPaymentStatus.paidAtVenue,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndUpdateStatus(
    BuildContext context,
    VenueStaffCubit cubit,
    VenuePartnerBooking booking,
    PartnerBookingStatus nextStatus,
  ) async {
    final isDestructive = nextStatus == PartnerBookingStatus.declined;
    if (isDestructive) {
      final confirmed = await AppConfirmationDialog.show(
        context: context,
        title: 'Decline Booking',
        message:
            'Decline booking for ${booking.playerName} on ${booking.courtName}?',
        confirmLabel: 'Decline',
        isDestructive: true,
      );
      if (confirmed != true) return;
    }

    await cubit.updateBookingStatus(
      bookingId: booking.id,
      newStatus: nextStatus,
    );
  }
}

class _BookingOperationCard extends StatelessWidget {
  final VenuePartnerBooking booking;
  final bool canCheckIn;
  final bool canRecordPayment;
  final ValueChanged<PartnerBookingStatus> onUpdateStatus;
  final VoidCallback onRecordOfflinePayment;

  const _BookingOperationCard({
    required this.booking,
    required this.canCheckIn,
    required this.canRecordPayment,
    required this.onUpdateStatus,
    required this.onRecordOfflinePayment,
  });

  String _formatSlot(DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.day)}/${two(start.month)} • ${two(start.hour)}:${two(start.minute)} - ${two(end.hour)}:${two(end.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClosed = booking.status == PartnerBookingStatus.cancelled ||
        booking.status == PartnerBookingStatus.declined ||
        booking.status == PartnerBookingStatus.completed;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.playerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.playerPhone} • ${booking.courtName} (${booking.locationName})',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(booking.status.label),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                'Slot: ${_formatSlot(booking.slotStart, booking.slotEnd)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                'Amount: ₹${booking.amountInr.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Payment: ${booking.paymentStatus.label}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: booking.paymentStatus == ManualPaymentStatus.paidAtVenue
                      ? AppColors.success
                      : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (booking.notes != null && booking.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Note: ${booking.notes}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (!isClosed && (canCheckIn || canRecordPayment)) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (canCheckIn &&
                    booking.status == PartnerBookingStatus.pending) ...[
                  FilledButton.tonal(
                    onPressed: () =>
                        onUpdateStatus(PartnerBookingStatus.confirmed),
                    child: const Text('Confirm'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        onUpdateStatus(PartnerBookingStatus.declined),
                    child: const Text('Decline'),
                  ),
                ],
                if (canCheckIn &&
                    booking.status == PartnerBookingStatus.confirmed)
                  FilledButton(
                    onPressed: () =>
                        onUpdateStatus(PartnerBookingStatus.checkedIn),
                    child: const Text('Check In'),
                  ),
                if (canCheckIn &&
                    booking.status == PartnerBookingStatus.checkedIn)
                  FilledButton.tonal(
                    onPressed: () =>
                        onUpdateStatus(PartnerBookingStatus.completed),
                    child: const Text('Mark Completed'),
                  ),
                if (canRecordPayment &&
                    booking.paymentStatus != ManualPaymentStatus.paidAtVenue)
                  OutlinedButton.icon(
                    onPressed: onRecordOfflinePayment,
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Mark Paid at Venue'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
