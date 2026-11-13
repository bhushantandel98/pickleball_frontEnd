import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/referee/domain/entities/referee_entities.dart';
import 'package:pickleball_platform/features/referee/presentation/bloc/referee_cubit.dart';
import 'package:pickleball_platform/features/referee/presentation/bloc/referee_state.dart';
import 'package:pickleball_platform/features/referee/presentation/widgets/referee_page_scaffold.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';

/// Referee Match Scoring & Result Submission page (Phase 5 — Feature 5.3).
///
/// Loads organizer-defined scoring rules as read-only and locks all score
/// mutations once the match result has been submitted.
class RefereeScoringPage extends StatelessWidget {
  final String? matchId;
  final RefereeCubit? cubit;
  final String? tournamentId;
  final String? refereeId;

  const RefereeScoringPage({
    super.key,
    this.matchId,
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
      title: 'Referee Scoring Pad',
      subtitle: 'Organizer-defined rules • Live scoring & final result lock.',
      bodyBuilder: (context, state) {
        final matches = state.data.assignedMatches;
        RefereeMatchAssignment? match;
        if (matchId == null || matchId!.isEmpty) {
          match = matches.isNotEmpty ? matches.first : null;
        } else {
          for (final item in matches) {
            if (item.id == matchId) {
              match = item;
              break;
            }
          }
        }

        if (match == null) {
          return ErrorStateView(
            title: 'Match Not Assigned',
            message:
                'This match is not assigned to your referee session or belongs to another tournament.',
            onRetry: () => context.go(AppRoutes.refereeDashboard),
          );
        }

        return _ScoringBody(match: match, state: state);
      },
    );
  }
}

class _ScoringBody extends StatelessWidget {
  final RefereeMatchAssignment match;
  final RefereeLoaded state;

  const _ScoringBody({required this.match, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cfg = match.scoringConfig;
    final methodLabel = cfg.method == TournamentScoringMethod.rallyScoring
        ? 'Rally Scoring'
        : 'Side-Out Scoring';
    final isLocked = match.isSubmitted;
    final isBusy = state.isMutating;
    final currentGame = match.games[
        match.currentGameIndex.clamp(0, match.games.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.refereeDashboard),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Dashboard'),
            ),
            const Spacer(),
            Chip(
              label: Text(
                isLocked
                    ? 'Submitted & Locked'
                    : match.status == OrganizerMatchStatus.inProgress
                        ? 'In Progress'
                        : 'Scheduled',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLocked) ...[
          AppCard(
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: AppColors.success),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Result submitted and locked. Winner: ${match.winnerLabel ?? '-'}. '
                    'Referees cannot modify submitted scores.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Organizer Scoring Rules (Read-Only)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '$methodLabel • Play to ${cfg.pointsPerGame} • Win by ${cfg.winBy} • '
                'Best of ${cfg.bestOfGames} game(s)',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                cfg.trackPositionsAndServiceOrder
                    ? 'Positions & service order tracking enabled by organizer.'
                    : 'Standard score tracking.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${match.categoryName} • ${match.roundLabel} • ${match.courtName}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ScoreColumn(
                      label: match.participantA,
                      score: currentGame.scoreA,
                      gamesWon: match.gamesWonA,
                      isServing: match.servingSide == 'A',
                      serverNumber: match.serverNumber,
                      showServiceOrder: cfg.trackPositionsAndServiceOrder,
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text('VS', style: theme.textTheme.titleMedium),
                  ),
                  Expanded(
                    child: _ScoreColumn(
                      label: match.participantB,
                      score: currentGame.scoreB,
                      gamesWon: match.gamesWonB,
                      isServing: match.servingSide == 'B',
                      serverNumber: match.serverNumber,
                      showServiceOrder: cfg.trackPositionsAndServiceOrder,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: match.games
                    .map(
                      (g) => Chip(
                        label: Text(
                          'G${g.gameNumber}: ${g.scoreA}-${g.scoreB}'
                          '${g.isComplete ? ' ✓' : ''}',
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!isLocked) ...[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (match.status == OrganizerMatchStatus.scheduled)
                      FilledButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => context
                                .read<RefereeCubit>()
                                .startMatch(match.id),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Match'),
                      ),
                    FilledButton.icon(
                      onPressed: isBusy || currentGame.isComplete
                          ? null
                          : () => context
                              .read<RefereeCubit>()
                              .awardPoint(match.id, 'A'),
                      icon: Icon(
                        cfg.method == TournamentScoringMethod.sideOutScoring &&
                                match.servingSide != 'A'
                            ? Icons.swap_horiz
                            : Icons.add,
                      ),
                      label: Text(
                        cfg.method == TournamentScoringMethod.sideOutScoring &&
                                match.servingSide != 'A'
                            ? 'Side-Out (${match.participantA} rally)'
                            : '+1 ${match.participantA}',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: isBusy || currentGame.isComplete
                          ? null
                          : () => context
                              .read<RefereeCubit>()
                              .awardPoint(match.id, 'B'),
                      icon: Icon(
                        cfg.method == TournamentScoringMethod.sideOutScoring &&
                                match.servingSide != 'B'
                            ? Icons.swap_horiz
                            : Icons.add,
                      ),
                      label: Text(
                        cfg.method == TournamentScoringMethod.sideOutScoring &&
                                match.servingSide != 'B'
                            ? 'Side-Out (${match.participantB} rally)'
                            : '+1 ${match.participantB}',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => context
                              .read<RefereeCubit>()
                              .switchServe(match.id),
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Switch Serve'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => _confirmAndSubmit(context, match),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Submit Final Result'),
                    ),
                    OutlinedButton.icon(
                      onPressed: isBusy
                          ? null
                          : () => _showFinalScoreDialog(context, match),
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Enter Final Score'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAndSubmit(
    BuildContext context,
    RefereeMatchAssignment match,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit Final Match Result?'),
        content: Text(
          'Once submitted (${match.formattedScoreSummary}), the result will be '
          'locked and cannot be modified by a Referee.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit & Lock'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<RefereeCubit>().submitMatchResult(match.id);
    }
  }

  Future<void> _showFinalScoreDialog(
    BuildContext context,
    RefereeMatchAssignment match,
  ) async {
    final scoreController = TextEditingController(
      text: match.formattedScoreSummary,
    );
    final cfg = match.scoringConfig;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Final Match Score'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: scoreController,
              decoration: const InputDecoration(
                labelText: 'Game scores (e.g. 11-7, 11-9)',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Winner is determined automatically from the validated scores '
              '(Best of ${cfg.bestOfGames}, Play to ${cfg.pointsPerGame}, Win by ${cfg.winBy}).',
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Submit & Lock'),
          ),
        ],
      ),
    );

    if (submitted == true && context.mounted) {
      await context.read<RefereeCubit>().submitMatchResult(
            match.id,
            finalScoreOverride: scoreController.text,
          );
    }
    scoreController.dispose();
  }
}

class _ScoreColumn extends StatelessWidget {
  final String label;
  final int score;
  final int gamesWon;
  final bool isServing;
  final int serverNumber;
  final bool showServiceOrder;

  const _ScoreColumn({
    required this.label,
    required this.score,
    required this.gamesWon,
    required this.isServing,
    required this.serverNumber,
    required this.showServiceOrder,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isServing
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isServing ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$score',
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Games Won: $gamesWon',
            style: theme.textTheme.bodySmall,
          ),
          if (isServing) ...[
            const SizedBox(height: AppSpacing.xs),
            Chip(
              label: Text(
                showServiceOrder ? 'Serving • #$serverNumber' : 'Serving',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
