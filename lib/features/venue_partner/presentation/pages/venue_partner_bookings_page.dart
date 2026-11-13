import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/venue_partner/domain/entities/venue_partner_entities.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_cubit.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_location_filter_bar.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_partner_page_scaffold.dart';

/// Venue Partner Booking Requests & Offline Manual Payment Tracking page (Feature 3.7).
class VenuePartnerBookingsPage extends StatelessWidget {
  final VenuePartnerCubit? cubit;
  final String partnerId;

  const VenuePartnerBookingsPage({
    super.key,
    this.cubit,
    this.partnerId = 'org_venue_001',
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('EEE, MMM d • hh:mm a');

    return VenuePartnerPageScaffold(
      cubit: cubit,
      partnerId: partnerId,
      title: 'Bookings & Manual Payments',
      subtitle:
          'Review booking requests, manage check-ins, and record offline venue payment status (V1 manual tracking only).',
      bodyBuilder: (context, state) {
        final cubit = context.read<VenuePartnerCubit>();
        final theme = Theme.of(context);
        final bookings = state.scopedBookings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VenueLocationFilterBar(
              locations: state.data.locations,
              selectedLocationId: state.selectedLocationId,
              onLocationSelected: cubit.selectLocation,
            ),
            const SizedBox(height: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.md),
            if (bookings.isEmpty)
              EmptyStateView(
                icon: const Icon(Icons.receipt_long_outlined),
                title: 'No Bookings Found',
                message:
                    'No court bookings match the selected location or status filter.',
                actionLabel:
                    state.bookingFilter != null ||
                            state.selectedLocationId != null
                        ? 'Clear Filters'
                        : null,
                onAction:
                    state.bookingFilter != null ||
                            state.selectedLocationId != null
                        ? () {
                            cubit.selectLocation(null);
                            cubit.setBookingFilter(null);
                          }
                        : null,
              )
            else
              ...bookings.map((bkg) {
                final statusColor = switch (bkg.status) {
                  PartnerBookingStatus.confirmed ||
                  PartnerBookingStatus.checkedIn ||
                  PartnerBookingStatus.completed =>
                    AppColors.success,
                  PartnerBookingStatus.pending => AppColors.warning,
                  PartnerBookingStatus.cancelled ||
                  PartnerBookingStatus.declined =>
                    AppColors.error,
                };
                final payColor = switch (bkg.paymentStatus) {
                  ManualPaymentStatus.paidAtVenue => AppColors.success,
                  ManualPaymentStatus.pendingVerification => AppColors.warning,
                  ManualPaymentStatus.unpaid => AppColors.error,
                };

                final isClosed =
                    bkg.status == PartnerBookingStatus.cancelled ||
                        bkg.status == PartnerBookingStatus.declined;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
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
                                    '${bkg.playerName} • ${bkg.courtName}',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${bkg.locationName} • ${timeFormat.format(bkg.slotStart)} • ${bkg.playerPhone}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(bkg.status.label),
                              backgroundColor:
                                  statusColor.withValues(alpha: 0.12),
                              labelStyle: theme.textTheme.labelSmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Fee: ₹${bkg.amountInr.toStringAsFixed(0)} • Offline Payment: ${bkg.paymentStatus.label}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: payColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (bkg.notes != null && bkg.notes!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Notes: ${bkg.notes}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (!isClosed) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              if (bkg.status == PartnerBookingStatus.pending) ...[
                                FilledButton.tonal(
                                  onPressed: () => cubit.updateBookingStatus(
                                    bookingId: bkg.id,
                                    newStatus: PartnerBookingStatus.confirmed,
                                  ),
                                  child: const Text('Confirm'),
                                ),
                                OutlinedButton(
                                  onPressed: () => _confirmAction(
                                    context,
                                    title: 'Decline Booking?',
                                    message:
                                        'Decline ${bkg.playerName}\'s booking request for ${bkg.courtName}?',
                                    onConfirm: () => cubit.updateBookingStatus(
                                      bookingId: bkg.id,
                                      newStatus: PartnerBookingStatus.declined,
                                    ),
                                  ),
                                  child: const Text('Decline'),
                                ),
                              ],
                              if (bkg.status == PartnerBookingStatus.confirmed)
                                FilledButton.tonal(
                                  onPressed: () => cubit.updateBookingStatus(
                                    bookingId: bkg.id,
                                    newStatus: PartnerBookingStatus.checkedIn,
                                  ),
                                  child: const Text('Check In'),
                                ),
                              if (bkg.status == PartnerBookingStatus.checkedIn)
                                FilledButton.tonal(
                                  onPressed: () => cubit.updateBookingStatus(
                                    bookingId: bkg.id,
                                    newStatus: PartnerBookingStatus.completed,
                                  ),
                                  child: const Text('Mark Completed'),
                                ),
                              if (bkg.status != PartnerBookingStatus.completed)
                                OutlinedButton(
                                  onPressed: () => _confirmAction(
                                    context,
                                    title: 'Cancel Booking?',
                                    message:
                                        'Cancel ${bkg.playerName}\'s booking for ${bkg.courtName}?',
                                    onConfirm: () => cubit.updateBookingStatus(
                                      bookingId: bkg.id,
                                      newStatus: PartnerBookingStatus.cancelled,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              if (bkg.paymentStatus !=
                                  ManualPaymentStatus.paidAtVenue)
                                OutlinedButton.icon(
                                  onPressed: () => cubit.recordManualPayment(
                                    bookingId: bkg.id,
                                    paymentStatus:
                                        ManualPaymentStatus.paidAtVenue,
                                  ),
                                  icon: const Icon(Icons.payments_outlined,
                                      size: 16),
                                  label: const Text('Mark Paid at Venue'),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required Future<void> Function() onConfirm,
  }) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: title,
      message: message,
      confirmLabel: 'Confirm',
      isDestructive: true,
    );
    if (confirmed == true) {
      await onConfirm();
    }
  }
}
