import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';

/// Screen displayed after a court booking has been successfully confirmed.
class BookingConfirmationPage extends StatelessWidget {
  final CourtBooking? booking;

  const BookingConfirmationPage({
    super.key,
    this.booking,
  });

  void _showBookingDetailsDialog(BuildContext context, CourtBooking b) {
    final theme = Theme.of(context);
    final formattedDate = DateFormat('EEEE, d MMMM yyyy').format(b.date);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.receipt_long_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
            const Text('Booking Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailItem(theme, 'Reference', b.bookingReference, isBold: true),
              _buildDetailItem(theme, 'Status', b.status.displayName),
              _buildDetailItem(theme, 'Player Name', b.playerName),
              const Divider(height: AppSpacing.md),
              _buildDetailItem(theme, 'Venue', b.venueName),
              _buildDetailItem(theme, 'Address', '${b.venueAddress}, ${b.venueCity}'),
              _buildDetailItem(theme, 'Court', '${b.courtName} (${b.surfaceType})'),
              _buildDetailItem(theme, 'Date', formattedDate),
              _buildDetailItem(theme, 'Time Slot', '${b.slotTime} (${b.durationMinutes} mins)'),
              const Divider(height: AppSpacing.md),
              _buildDetailItem(theme, 'Court Fee', '₹${b.courtFee.toStringAsFixed(0)}'),
              _buildDetailItem(
                theme,
                'Convenience Fee',
                b.platformFee == 0 ? 'FREE' : '₹${b.platformFee.toStringAsFixed(0)}',
              ),
              _buildDetailItem(theme, 'Taxes', '₹${b.taxes.toStringAsFixed(0)}'),
              const Divider(height: AppSpacing.sm),
              _buildDetailItem(
                theme,
                'Total Amount',
                '₹${b.totalAmount.toStringAsFixed(0)}',
                isBold: true,
                valueColor: theme.colorScheme.primary,
              ),
              _buildDetailItem(theme, 'Payment Mode', b.paymentMethod),
            ],
          ),
        ),
        actions: [
          AppButton.primary(
            label: 'Close',
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    ThemeData theme,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (booking == null) {
      return Scaffold(
        appBar: CommonAppBar(
          title: 'Booking Confirmation',
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go(AppRoutes.playerDashboard),
          ),
        ),
        body: ErrorStateView(
          title: 'Booking Details Missing',
          message: 'No active court booking confirmation was found.',
          onRetry: () => context.go(AppRoutes.playerDashboard),
        ),
      );
    }

    final b = booking!;
    final dateFormatted = DateFormat('EEE, d MMM yyyy').format(b.date);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Booking Confirmation',
        leading: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close and Return to Dashboard',
            onPressed: () => context.go(AppRoutes.playerDashboard),
          ),
        ],
      ),
      body: ResponsiveContainer(
        maxWidth: 680,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.sm),
              // Success Emblem
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.primary,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Booking Confirmed!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Your pickleball court has been reserved successfully.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              // Booking Reference Box
              AppCard(
                key: const Key('booking_confirmation_reference_card'),
                padding: const EdgeInsets.all(AppSpacing.md),
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'BOOKING REFERENCE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      b.bookingReference,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      alignment: WrapAlignment.center,
                      children: [
                        AppChip.warning(label: b.paymentMethod),
                        AppChip.success(label: b.status.displayName),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Reservation Details Card
              AppCard(
                key: const Key('booking_confirmation_details_card'),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reservation Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      context,
                      icon: Icons.store_outlined,
                      label: 'Venue',
                      value: b.venueName,
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: '${b.venueAddress}, ${b.venueCity}',
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.sports_tennis_rounded,
                      label: 'Court',
                      value: '${b.courtName} (${b.surfaceType})',
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.event_available_outlined,
                      label: 'Date',
                      value: dateFormatted,
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.schedule_outlined,
                      label: 'Time Slot',
                      value: '${b.slotTime} (${b.durationMinutes} mins)',
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.currency_rupee_rounded,
                      label: 'Total Amount',
                      value: '₹${b.totalAmount.toStringAsFixed(0)}',
                      valueColor: theme.colorScheme.primary,
                    ),
                    _buildInfoRow(
                      context,
                      icon: Icons.payment_outlined,
                      label: 'Payment Status',
                      value: 'Pending (Pay at Venue Counter)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Venue Check-in Instructions Notice
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Please arrive at the venue 10 minutes prior to your slot. Present your reference (${b.bookingReference}) at the desk to complete offline payment and gain court access.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: AppButton.primary(
                  key: const Key('booking_confirmation_dashboard_button'),
                  label: 'Back to Player Dashboard',
                  icon: const Icon(Icons.dashboard_rounded),
                  onPressed: () => context.go(AppRoutes.playerDashboard),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: AppButton.outline(
                  key: const Key('booking_confirmation_view_details_button'),
                  label: 'View Booking Details',
                  icon: const Icon(Icons.receipt_long_outlined),
                  onPressed: () => _showBookingDetailsDialog(context, b),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
