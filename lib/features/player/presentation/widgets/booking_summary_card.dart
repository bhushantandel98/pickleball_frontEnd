import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';

/// Summary card displaying the currently configured booking selection and Continue CTA.
class BookingSummaryCard extends StatelessWidget {
  final VenueItem venue;
  final CourtItem? court;
  final DateTime date;
  final CourtSlot? slot;
  final VoidCallback? onContinue;

  const BookingSummaryCard({
    super.key,
    required this.venue,
    this.court,
    required this.date,
    required this.slot,
    this.onContinue,
  });

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Row(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatted = DateFormat('EEE, d MMMM yyyy').format(date);
    final hasSelection = slot != null && court != null;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Booking Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          // Venue
          _buildSummaryRow(
            context,
            icon: Icons.store_outlined,
            label: 'Venue',
            value: venue.name,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Court
          _buildSummaryRow(
            context,
            icon: Icons.sports_tennis_rounded,
            label: 'Court',
            value: court != null ? '${court!.name} (${court!.surfaceType})' : 'No court selected',
            valueColor: court != null ? null : theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Date
          _buildSummaryRow(
            context,
            icon: Icons.event_outlined,
            label: 'Date',
            value: dateFormatted,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Time Slot
          _buildSummaryRow(
            context,
            icon: Icons.schedule_outlined,
            label: 'Slot',
            value: hasSelection ? slot!.formattedTime : 'No slot selected',
            valueColor: hasSelection ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          // Price breakdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Court Fee:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                hasSelection ? '₹${slot!.price.toStringAsFixed(0)}' : '₹0',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                hasSelection ? '₹${slot!.price.toStringAsFixed(0)}' : '₹0',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Continue Action Button
          SizedBox(
            width: double.infinity,
            child: AppButton.primary(
              key: const Key('court_availability_continue_button'),
              label: hasSelection ? 'Continue to Booking' : 'Select a Slot',
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: hasSelection ? onContinue : null,
            ),
          ),
        ],
      ),
    );
  }
}
