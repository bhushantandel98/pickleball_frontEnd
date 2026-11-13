import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/referee/domain/entities/referee_entities.dart';
import 'package:pickleball_platform/features/referee/presentation/bloc/referee_cubit.dart';
import 'package:pickleball_platform/features/referee/presentation/widgets/referee_page_scaffold.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';

/// Referee Dashboard scoped to the authenticated Referee's assigned tournament
/// and assigned matches (Phase 5 — Feature 5.3).
class RefereeDashboardPage extends StatelessWidget {
  final RefereeCubit? cubit;
  final String? tournamentId;
  final String? refereeId;

  const RefereeDashboardPage({
    super.key,
    this.cubit,
    this.tournamentId,
    this.refereeId,
  });

  @override
  Widget build(BuildContext context) {
    return RefereePageScaffold(
      cubit: cubit,
      tournamentId: tournamentId,
      refereeId: refereeId,
      title: 'Referee Dashboard',
      subtitle:
          'Assigned matches, organizer-defined scoring rules, schedule & standings.',
      bodyBuilder: (context, state) {
        final theme = Theme.of(context);
        final data = state.data;
        final profile = data.profile;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RefereeProfileBanner(profile: profile),
            const SizedBox(height: AppSpacing.lg),
            Text('My Assigned Matches', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            if (data.assignedMatches.isEmpty)
              const EmptyStateView(
                title: 'No Assigned Matches',
                message:
                    'You have no matches assigned in this tournament right now.',
              )
            else
              ...data.assignedMatches.map(
                (match) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _AssignedMatchCard(match: match),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Tournament Match Day Schedule (Read-Only)',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (data.tournamentSchedule.isEmpty)
              const EmptyStateView(
                title: 'No Scheduled Matches',
                message: 'No Match Day schedule slots are published yet.',
              )
            else
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < data.tournamentSchedule.length; i++) ...[
                      _ScheduleRow(slot: data.tournamentSchedule[i]),
                      if (i < data.tournamentSchedule.length - 1)
                        const Divider(height: AppSpacing.lg),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Tournament Standings (Read-Only)',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (data.standings.isEmpty)
              const EmptyStateView(
                title: 'No Standings Yet',
                message: 'Standings will appear as matches are completed.',
              )
            else
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < data.standings.length; i++) ...[
                      _StandingRow(entry: data.standings[i]),
                      if (i < data.standings.length - 1)
                        const Divider(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RefereeProfileBanner extends StatelessWidget {
  final RefereeProfile profile;

  const _RefereeProfileBanner({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  profile.tournamentName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Chip(
                label: Text(profile.isActive ? 'Active Referee' : 'Inactive'),
                backgroundColor: profile.isActive
                    ? AppColors.success.withValues(alpha: 0.12)
                    : theme.colorScheme.errorContainer,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${profile.venueName} • ${profile.refereeName} (${profile.certificationLevel})',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignedMatchCard extends StatelessWidget {
  final RefereeMatchAssignment match;

  const _AssignedMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cfg = match.scoringConfig;
    final methodLabel =
        cfg.method == TournamentScoringMethod.rallyScoring ? 'Rally' : 'Side-Out';
    final statusLabel = switch (match.status) {
      OrganizerMatchStatus.scheduled => 'Scheduled',
      OrganizerMatchStatus.inProgress => 'In Progress',
      OrganizerMatchStatus.completed => 'Submitted (Locked)',
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${match.categoryName} • ${match.roundLabel}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Chip(label: Text(statusLabel)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${match.participantA}  vs  ${match.participantB}',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${match.courtName} • ${_formatTime(match.scheduledTime)} • '
            '$methodLabel to ${cfg.pointsPerGame} (Win by ${cfg.winBy}, Best of ${cfg.bestOfGames})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  match.isSubmitted
                      ? 'Final: ${match.formattedScoreSummary} • Winner: ${match.winnerLabel ?? '-'}'
                      : 'Score: ${match.formattedScoreSummary}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () =>
                    context.go('/referee/match/${match.id}/scoring'),
                icon: Icon(
                  match.isSubmitted ? Icons.visibility_outlined : Icons.scoreboard_outlined,
                ),
                label: Text(
                  match.isSubmitted ? 'View Result' : 'Open Scoring Pad',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final OrganizerMatchSlot slot;

  const _ScheduleRow({required this.slot});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${slot.categoryName} • ${slot.roundLabel}',
                style: theme.textTheme.titleSmall,
              ),
              Text(
                '${slot.participantA} vs ${slot.participantB}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${slot.courtName ?? 'Court TBD'} • ${_formatTime(slot.scheduledTime)} • Ref: ${slot.refereeName ?? 'Unassigned'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (slot.scoreSummary != null)
          Text(
            slot.scoreSummary!,
            style: theme.textTheme.labelLarge,
          )
        else
          Text(
            slot.status.name,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _StandingRow extends StatelessWidget {
  final RefereeStandingEntry entry;

  const _StandingRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.participantLabel, style: theme.textTheme.titleSmall),
              Text(
                entry.categoryName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Text(
          'P:${entry.played}  W:${entry.won}  L:${entry.lost}  PD:${entry.pointDifferential >= 0 ? '+${entry.pointDifferential}' : entry.pointDifferential}',
          style: theme.textTheme.labelMedium,
        ),
      ],
    );
  }
}

String _formatTime(DateTime? dt) {
  if (dt == null) return 'TBD';
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
