import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';

/// Displays upcoming personal coaching and assigned academy sessions.
/// Official academy schedules are strictly read-only on the Coach Dashboard.
class CoachUpcomingSessionsSection extends StatelessWidget {
  final List<CoachSessionItem> sessions;

  const CoachUpcomingSessionsSection({
    super.key,
    required this.sessions,
  });

  String _statusLabel(CoachSessionStatus status) {
    return switch (status) {
      CoachSessionStatus.confirmed => 'Confirmed',
      CoachSessionStatus.pendingApproval => 'Pending Approval',
      CoachSessionStatus.scheduled => 'Scheduled',
      CoachSessionStatus.completed => 'Completed',
      CoachSessionStatus.cancelled => 'Cancelled',
    };
  }

  Color _statusColor(BuildContext context, CoachSessionStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (status) {
      CoachSessionStatus.confirmed => AppColors.success,
      CoachSessionStatus.pendingApproval => AppColors.warning,
      CoachSessionStatus.scheduled => colorScheme.primary,
      CoachSessionStatus.completed => colorScheme.onSurfaceVariant,
      CoachSessionStatus.cancelled => colorScheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Row(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Upcoming Sessions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${sessions.length} ${sessions.length == 1 ? 'session' : 'sessions'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sessions.isEmpty)
          AppCard(
            key: const Key('coach_sessions_empty'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy_rounded,
                    size: 36,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'No upcoming sessions for the selected context.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: [
              for (int i = 0; i < sessions.length; i++) ...[
                _SessionCard(
                  session: sessions[i],
                  statusLabel: _statusLabel(sessions[i].status),
                  statusColor: _statusColor(context, sessions[i].status),
                ),
                if (i < sessions.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final CoachSessionItem session;
  final String statusLabel;
  final Color statusColor;

  const _SessionCard({
    required this.session,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAcademy = session.contextType == CoachSessionContext.academy;

    return AppCard(
      key: Key('coach_session_card_${session.id}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: (isAcademy
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    session.sessionType,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isAcademy
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  statusLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            session.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xxs,
            children: [
              _InfoMeta(
                icon: Icons.calendar_today_outlined,
                text: '${session.dateLabel} • ${session.timeRange}',
              ),
              _InfoMeta(
                icon: Icons.location_on_outlined,
                text: session.venueOrBranchName,
              ),
              _InfoMeta(
                icon: Icons.people_outline_rounded,
                text:
                    '${session.participantCount} ${session.participantCount == 1 ? 'player' : 'players'}',
              ),
            ],
          ),
          if (session.isAcademyManaged) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Expanded(
                  child: Text(
                    'Academy Managed Schedule (Read-only)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoMeta({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
