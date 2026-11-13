import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/features/coach/domain/entities/personal_coaching_booking.dart';

/// Displays full personal coaching booking details and chronological audit history.
class PersonalBookingDetailSheet extends StatelessWidget {
  final PersonalCoachingBooking booking;

  const PersonalBookingDetailSheet({
    super.key,
    required this.booking,
  });

  static Future<void> show(
    BuildContext context, {
    required PersonalCoachingBooking booking,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => PersonalBookingDetailSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(booking.sessionTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(label: 'Status', value: booking.status.label),
              _DetailRow(label: 'Player', value: booking.playerName),
              if (booking.playerContact.isNotEmpty)
                _DetailRow(label: 'Contact', value: booking.playerContact),
              _DetailRow(label: 'Session Type', value: booking.sessionType),
              _DetailRow(
                label: 'Schedule',
                value: _formatRange(booking.startTime, booking.endTime),
              ),
              _DetailRow(label: 'Venue', value: booking.venueName),
              if (booking.notes != null && booking.notes!.isNotEmpty)
                _DetailRow(label: 'Coach Notes', value: booking.notes!),
              if (booking.playerResponseNote != null &&
                  booking.playerResponseNote!.isNotEmpty)
                _DetailRow(
                  label: 'Player Response',
                  value: booking.playerResponseNote!,
                ),
              if (booking.cancellationReason != null &&
                  booking.cancellationReason!.isNotEmpty)
                _DetailRow(
                  label: 'Cancellation Reason',
                  value: booking.cancellationReason!,
                ),
              if (booking.conflictWarning != null &&
                  booking.conflictWarning!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    booking.conflictWarning!,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                'Booking History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              ...booking.history.reversed.map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            _formatTimestamp(entry.timestamp),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(entry.description, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        'Actor: ${entry.actorLabel}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final sH = start.hour.toString().padLeft(2, '0');
    final sM = start.minute.toString().padLeft(2, '0');
    final eH = end.hour.toString().padLeft(2, '0');
    final eM = end.minute.toString().padLeft(2, '0');
    return '${months[start.month - 1]} ${start.day}, ${start.year} ($sH:$sM – $eH:$eM)';
  }

  String _formatTimestamp(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$m';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
