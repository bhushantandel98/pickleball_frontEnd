import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';

/// Card widget rendering individual booking summary with status, details, and action triggers.
class BookingCard extends StatelessWidget {
  final CourtBooking booking;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final bool isCancelling;

  const BookingCard({
    super.key,
    required this.booking,
    required this.onTap,
    this.onCancel,
    this.isCancelling = false,
  });

  Widget _buildStatusChip(BuildContext context) {
    switch (booking.status) {
      case BookingStatus.confirmed:
        return AppChip.success(label: booking.status.displayName);
      case BookingStatus.paymentPending:
        return AppChip.warning(label: booking.status.displayName);
      case BookingStatus.completed:
        return AppChip.info(label: booking.status.displayName);
      case BookingStatus.cancelled:
        return AppChip.error(label: booking.status.displayName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('EEE, d MMM yyyy').format(booking.date);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.borderRadiusMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Reference + Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.bookingReference,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                _buildStatusChip(context),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // Venue Name
            Text(
              booking.venueName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),

            // Court & Surface
            Row(
              children: [
                Icon(
                  Icons.sports_tennis_outlined,
                  size: 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${booking.courtName} • ${booking.surfaceType}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Date & Time Slot + Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Date & Slot
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_outlined,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            booking.slotTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${booking.totalAmount.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Pay at Venue',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Card Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (booking.canCancel && onCancel != null) ...[
                  AppButton.outline(
                    key: Key('cancel_booking_${booking.id}'),
                    label: 'Cancel',
                    icon: const Icon(Icons.close, size: 16),
                    isLoading: isCancelling,
                    onPressed: isCancelling ? null : onCancel,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                AppButton.primary(
                  key: Key('view_details_${booking.id}'),
                  label: 'View Details',
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  onPressed: onTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
