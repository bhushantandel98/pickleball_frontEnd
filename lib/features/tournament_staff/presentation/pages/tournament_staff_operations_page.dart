import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';
import 'package:pickleball_platform/features/tournament_staff/domain/entities/tournament_staff_entities.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/cubit/tournament_staff_cubit.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/cubit/tournament_staff_state.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/widgets/tournament_staff_page_scaffold.dart';

/// Tournament Staff operations screen for delegated check-ins, referee
/// assignments (when [TournamentStaffPermission.manageReferees] is delegated),
/// and score corrections (when [TournamentStaffPermission.editMatchScore] is
/// delegated) (Phase 5 — Feature 5.2).
class TournamentStaffOperationsPage extends StatelessWidget {
  final TournamentStaffCubit? cubit;
  final String? tournamentId;
  final String? staffId;

  const TournamentStaffOperationsPage({
    super.key,
    this.cubit,
    this.tournamentId,
    this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    return TournamentStaffPageScaffold(
      cubit: cubit,
      tournamentId: tournamentId,
      staffId: staffId,
      title: 'Tournament Staff Operations',
      subtitle:
          'Execute delegated check-in, referee assignment, and score correction tasks.',
      bodyBuilder: (context, state) {
        final canCheckIn =
            state.hasPermission(TournamentStaffPermission.manageCheckIn);
        final canManageRefs =
            state.hasPermission(TournamentStaffPermission.manageReferees);
        final canEditScore =
            state.hasPermission(TournamentStaffPermission.editMatchScore);

        if (!canCheckIn && !canManageRefs && !canEditScore) {
          return const EmptyStateView(
            title: 'Operations Restricted',
            message:
                'No operational permissions have been delegated to your Tournament Staff role.',
          );
        }

        final cubit = context.read<TournamentStaffCubit>();
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canCheckIn) ...[
              _buildCheckInSection(theme, cubit, state),
              const SizedBox(height: AppSpacing.md),
            ],
            _buildMatchesOperationsSection(
              context,
              theme,
              cubit,
              state,
              canManageRefs: canManageRefs,
              canEditScore: canEditScore,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCheckInSection(
    ThemeData theme,
    TournamentStaffCubit cubit,
    TournamentStaffLoaded state,
  ) {
    final checkIns = state.data.checkIns;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Participant Check-In (${state.checkedInCount}/${checkIns.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (checkIns.isEmpty)
            const EmptyStateView(
              title: 'No Entries',
              message: 'No confirmed entries found for this tournament.',
            )
          else
            ...checkIns.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  item.isCheckedIn
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: item.isCheckedIn
                      ? AppColors.success
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(item.participantLabel),
                subtitle: Text(
                  '${item.categoryName} • ${item.eventFormat.label}',
                ),
                trailing: item.isCheckedIn
                    ? OutlinedButton(
                        onPressed: () => cubit.toggleCheckIn(
                          checkInId: item.id,
                          isCheckedIn: false,
                        ),
                        child: const Text('Undo'),
                      )
                    : FilledButton(
                        onPressed: () => cubit.toggleCheckIn(
                          checkInId: item.id,
                          isCheckedIn: true,
                        ),
                        child: const Text('Check In'),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchesOperationsSection(
    BuildContext context,
    ThemeData theme,
    TournamentStaffCubit cubit,
    TournamentStaffLoaded state, {
    required bool canManageRefs,
    required bool canEditScore,
  }) {
    final matches = state.data.matches;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Operations (${matches.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (matches.isEmpty)
            const EmptyStateView(
              title: 'No Matches',
              message: 'No matches are scheduled for this tournament.',
            )
          else
            ...matches.map(
              (match) => Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${match.participantA} vs ${match.participantB}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(match.status.label),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    Text(
                      '${match.categoryName} • ${match.roundLabel} • ${match.courtName ?? 'No Court'}'
                      '${match.refereeName != null ? ' • Ref: ${match.refereeName}' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (match.scoreSummary != null)
                      Text(
                        'Score: ${match.scoreSummary} • Winner: ${match.winnerLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (canManageRefs || canEditScore) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (canManageRefs && state.data.referees.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () => _showAssignRefereeDialog(
                                context,
                                cubit,
                                state,
                                match,
                              ),
                              icon: const Icon(Icons.sports_outlined, size: 18),
                              label: const Text('Assign Referee'),
                            ),
                          if (canEditScore)
                            FilledButton.tonalIcon(
                              onPressed: () => _showCorrectScoreDialog(
                                context,
                                cubit,
                                match,
                              ),
                              icon: const Icon(Icons.edit_note, size: 18),
                              label: const Text('Correct Score'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAssignRefereeDialog(
    BuildContext context,
    TournamentStaffCubit cubit,
    TournamentStaffLoaded state,
    OrganizerMatchSlot match,
  ) async {
    final activeRefs = state.data.referees.where((r) => r.isActive).toList();
    var selectedRefId = activeRefs.first.refereeAssignmentId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign / Reassign Referee'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedRefId,
            decoration: const InputDecoration(labelText: 'Tournament Referee'),
            items: activeRefs
                .map(
                  (r) => DropdownMenuItem(
                    value: r.refereeAssignmentId,
                    child: Text(r.name),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => selectedRefId = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await cubit.assignMatchReferee(
        matchId: match.id,
        refereeAssignmentId: selectedRefId,
      );
    }
  }

  Future<void> _showCorrectScoreDialog(
    BuildContext context,
    TournamentStaffCubit cubit,
    OrganizerMatchSlot match,
  ) async {
    final scoreCtrl = TextEditingController(
      text: match.scoreSummary ?? '11-8, 11-9',
    );
    final reasonCtrl = TextEditingController();
    var winner = match.winnerLabel ?? match.participantA;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Correct Match Score'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${match.participantA} vs ${match.participantB}'),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: scoreCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Corrected Score'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: winner,
                    decoration: const InputDecoration(labelText: 'Winner'),
                    items: [match.participantA, match.participantB]
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => winner = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Correction Reason',
                      hintText: 'e.g. Official scorecard verification',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Correction reason is required'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Save Correction'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await cubit.correctMatchScore(
        matchId: match.id,
        scoreSummary: scoreCtrl.text.trim(),
        winnerLabel: winner,
        correctionReason: reasonCtrl.text.trim(),
      );
    }

    scoreCtrl.dispose();
    reasonCtrl.dispose();
  }
}
