import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/personal_coaching_booking.dart';

/// Displays a single personal coaching booking with status badge,
/// non-blocking conflict warning (if any), and coach-permitted actions.
class PersonalBookingCard extends StatelessWidget {
  final PersonalCoachingBooking booking;
  final VoidCallback onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;

  const PersonalBookingCard({
    super.key,
    required this.booking,
    required this.onViewDetails,
    this.onEdit,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme, booking.status);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.status.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  booking.sessionType,
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            booking.sessionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.playerContact.isNotEmpty
                      ? '${booking.playerName} • ${booking.playerContact}'
                      : booking.playerName,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatDateTimeRange(booking.startTime, booking.endTime),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  booking.venueName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (booking.playerResponseNote != null &&
              booking.playerResponseNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Player note: ${booking.playerResponseNote!}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (booking.cancellationReason != null &&
              booking.cancellationReason!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Cancellation reason: ${booking.cancellationReason!}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          if (booking.conflictWarning != null &&
              booking.conflictWarning!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      booking.conflictWarning!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.history_outlined, size: 16),
                label: const Text('Details & History'),
              ),
              if (booking.canEdit && onEdit != null)
                FilledButton.tonalIcon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                ),
              if (booking.canCancel && onCancel != null)
                TextButton.icon(
                  onPressed: onCancel,
                  icon: Icon(
                    Icons.cancel_outlined,
                    size: 16,
                    color: theme.colorScheme.error,
                  ),
                  label: Text(
                    'Cancel Booking',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(ThemeData theme, PersonalBookingStatus status) {
    return switch (status) {
      PersonalBookingStatus.pendingPlayerApproval => AppColors.warning,
      PersonalBookingStatus.confirmed => AppColors.success,
      PersonalBookingStatus.declined => AppColors.error,
      PersonalBookingStatus.cancelled => theme.colorScheme.onSurfaceVariant,
    };
  }

  String _formatDateTimeRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final sH = start.hour.toString().padLeft(2, '0');
    final sM = start.minute.toString().padLeft(2, '0');
    final eH = end.hour.toString().padLeft(2, '0');
    final eM = end.minute.toString().padLeft(2, '0');
    return '${months[start.month - 1]} ${start.day}, ${start.year} • $sH:$sM – $eH:$eM';
  }
}
