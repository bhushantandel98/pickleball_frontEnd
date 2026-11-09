import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/match_day_data.dart';

/// Card rendering a player tournament fixture with live score tracking and check-in trigger.
class MatchScoreCard extends StatelessWidget {
  final PlayerMatch match;
  final VoidCallback? onCheckIn;
  final bool isCheckingIn;
  final bool isHero;

  const MatchScoreCard({
    super.key,
    required this.match,
    this.onCheckIn,
    this.isCheckingIn = false,
    this.isHero = false,
  });

  Widget _buildStatusChip(BuildContext context) {
    switch (match.status) {
      case MatchStatus.live:
        return AppChip.error(
          label: 'LIVE',
          icon: const Icon(Icons.fiber_manual_record, size: 12, color: Colors.white),
        );
      case MatchStatus.warmup:
        return AppChip.warning(label: 'Warmup');
      case MatchStatus.scheduled:
        return AppChip.info(label: match.formattedTime);
      case MatchStatus.completed:
        return AppChip.success(label: 'Final');
      case MatchStatus.delayed:
        return AppChip.warning(label: 'Delayed');
    }
  }

  Widget _buildPlayerRow(
    BuildContext context, {
    required String name,
    int? seed,
    required List<int> scores,
    required bool isServing,
    required bool isWinner,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Server Indicator Dot
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (match.isLive && isServing)
                  ? theme.colorScheme.primary
                  : Colors.transparent,
            ),
          ),

          // Player Name & Seed
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isWinner || isServing ? FontWeight.bold : FontWeight.w500,
                      color: isWinner ? theme.colorScheme.primary : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (seed != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$seed',
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Set Scores
          if (scores.isNotEmpty)
            Row(
              children: scores.asMap().entries.map((entry) {
                final setIdx = entry.key;
                final score = entry.value;
                final isCurrentSet = match.isLive && (setIdx + 1 == match.currentSet);

                return Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(left: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCurrentSet
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$score',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: isCurrentSet ? FontWeight.bold : FontWeight.w600,
                      color: isCurrentSet ? theme.colorScheme.primary : null,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            Text(
              '-',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Round, Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${match.category} • ${match.round}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _buildStatusChip(context),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          // Court Allocation
          Row(
            children: [
              Icon(
                Icons.stadium_outlined,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  match.courtName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Scoreboard Rows
          _buildPlayerRow(
            context,
            name: match.player1Name,
            seed: match.player1Seed,
            scores: match.player1Score,
            isServing: match.serverIndex == 1,
            isWinner: match.winnerName == match.player1Name,
          ),
          _buildPlayerRow(
            context,
            name: match.player2Name,
            seed: match.player2Seed,
            scores: match.player2Score,
            isServing: match.serverIndex == 2,
            isWinner: match.winnerName == match.player2Name,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Footer: Referee & Check-in CTA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (match.refereeName != null)
                Row(
                  children: [
                    Icon(
                      Icons.sports_rounded,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Ref: ${match.refereeName!}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox.shrink(),

              // Check-in status or button
              if (match.isCheckedIn)
                AppChip.success(
                  label: 'Checked In',
                  icon: const Icon(Icons.check, size: 12),
                )
              else if (onCheckIn != null && match.isScheduled)
                AppButton.primary(
                  key: Key('check_in_button_${match.id}'),
                  label: 'Check In',
                  icon: const Icon(Icons.how_to_reg_outlined, size: 16),
                  isLoading: isCheckingIn,
                  onPressed: isCheckingIn ? null : onCheckIn,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
