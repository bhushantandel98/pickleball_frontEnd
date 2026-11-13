import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';

/// Displays player statistics while keeping Personal Coaching and Academy contexts strictly separate.
class CoachPlayerSummarySection extends StatelessWidget {
  final bool showPersonalContext;
  final bool showAcademyContext;
  final PersonalPlayerSummary? personalSummary;
  final List<AcademyPlayerSummary> academySummaries;

  const CoachPlayerSummarySection({
    super.key,
    required this.showPersonalContext,
    required this.showAcademyContext,
    required this.personalSummary,
    required this.academySummaries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPersonal = showPersonalContext && personalSummary != null;
    final hasAcademy = showAcademyContext && academySummaries.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
          child: Row(
            children: [
              Icon(
                Icons.groups_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Player Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!hasPersonal && !hasAcademy)
          AppCard(
            key: const Key('coach_players_empty'),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: Text(
                'No player metrics available for the selected context.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else ...[
          if (hasPersonal) ...[
            _PersonalPlayerSummaryCard(summary: personalSummary!),
            if (hasAcademy) const SizedBox(height: AppSpacing.sm),
          ],
          if (hasAcademy)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < academySummaries.length; i++) ...[
                  _AcademyPlayerSummaryCard(summary: academySummaries[i]),
                  if (i < academySummaries.length - 1)
                    const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
        ],
      ],
    );
  }
}

class _PersonalPlayerSummaryCard extends StatelessWidget {
  final PersonalPlayerSummary summary;

  const _PersonalPlayerSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: const Key('coach_personal_player_summary_card'),
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
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    'Personal Coaching Context',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${summary.totalPersonalPlayers} total students',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _MetricTile(
                label: '1-on-1 Players',
                value: summary.activePrivatePlayers.toString(),
              ),
              _MetricTile(
                label: 'Group Students',
                value: summary.activeGroupPlayers.toString(),
              ),
              _MetricTile(
                label: 'Sessions (Month)',
                value: summary.completedSessionsThisMonth.toString(),
              ),
              _MetricTile(
                label: 'New Inquiries',
                value: summary.newInquiriesCount.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AcademyPlayerSummaryCard extends StatelessWidget {
  final AcademyPlayerSummary summary;

  const _AcademyPlayerSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      key: Key(
        'coach_academy_player_summary_${summary.academyId}_${summary.branchId}',
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'Academy Context',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  summary.academyName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Assigned Branch: ${summary.branchName}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _MetricTile(
                label: 'Assigned Batches',
                value: summary.assignedBatchesCount.toString(),
              ),
              _MetricTile(
                label: 'Batch Players',
                value: summary.totalAssignedPlayers.toString(),
              ),
              _MetricTile(
                label: 'Avg. Attendance',
                value: '${summary.averageAttendancePercent.toStringAsFixed(0)}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _MetricTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
