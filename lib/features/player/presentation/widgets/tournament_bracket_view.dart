import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/features/player/domain/entities/match_day_data.dart';

/// Elimination bracket view displaying tournament progression from Quarter-finals to the Final.
class TournamentBracketView extends StatefulWidget {
  final List<BracketNode> bracket;

  const TournamentBracketView({
    super.key,
    required this.bracket,
  });

  @override
  State<TournamentBracketView> createState() => _TournamentBracketViewState();
}

class _TournamentBracketViewState extends State<TournamentBracketView> {
  late String _selectedRound;

  @override
  void initState() {
    super.initState();
    final rounds = widget.bracket.map((b) => b.roundName).toSet().toList();
    _selectedRound = rounds.isNotEmpty ? rounds.first : 'Semi-Finals';
  }

  Widget _buildBracketCard(BuildContext context, BracketNode node) {
    final theme = Theme.of(context);
    final p1Won = node.winner == node.player1;
    final p2Won = node.winner == node.player2;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Match label + Live / Court Chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Match #${node.matchIndex}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (node.isLive)
                AppChip.error(label: 'LIVE')
              else if (node.court != null)
                AppChip.neutral(label: node.court!)
              else if (node.winner != null)
                AppChip.success(label: 'Final'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Player 1
          Row(
            children: [
              if (node.player1Seed != null)
                Text(
                  '[${node.player1Seed}] ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              Expanded(
                child: Text(
                  node.player1,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: p1Won ? FontWeight.bold : FontWeight.w500,
                    color: p1Won ? theme.colorScheme.primary : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                node.player1Score.isNotEmpty ? node.player1Score : '-',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: p1Won ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Player 2
          Row(
            children: [
              if (node.player2Seed != null)
                Text(
                  '[${node.player2Seed}] ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              Expanded(
                child: Text(
                  node.player2,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: p2Won ? FontWeight.bold : FontWeight.w500,
                    color: p2Won ? theme.colorScheme.primary : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                node.player2Score.isNotEmpty ? node.player2Score : '-',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: p2Won ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rounds = widget.bracket.map((b) => b.roundName).toSet().toList();
    final roundNodes = widget.bracket.where((b) => b.roundName == _selectedRound).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Round Selector Chips
        if (rounds.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: rounds.map((round) {
                  final isSelected = round == _selectedRound;
                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(round),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedRound = round);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

        // Fixtures in selected round
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: roundNodes.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            return _buildBracketCard(context, roundNodes[index]);
          },
        ),
      ],
    );
  }
}
