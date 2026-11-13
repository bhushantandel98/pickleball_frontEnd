import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_cubit.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_state.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/widgets/tournament_organizer_page_scaffold.dart';

/// Draw generation (Round Robin & Knockout), manual seeding, and court/referee
/// match scheduling screen (Phase 5 — Feature 5.1).
class TournamentDrawsPage extends StatelessWidget {
  final String? tournamentId;
  final TournamentOrganizerCubit? cubit;
  final String? organizerId;

  const TournamentDrawsPage({
    super.key,
    this.tournamentId,
    this.cubit,
    this.organizerId,
  });

  @override
  Widget build(BuildContext context) {
    return TournamentOrganizerPageScaffold(
      cubit: cubit,
      organizerId: organizerId,
      initialTournamentId: tournamentId,
      title: 'Draws, Seeding & Match Schedule',
      subtitle:
          'Generate Round Robin or Knockout draws, adjust manual seeds, and assign courts & referees.',
      bodyBuilder: (context, state) {
        final tournament = state.selectedTournament;
        if (tournament == null) {
          return EmptyStateView(
            title: 'Tournament Not Found',
            message: 'Select an owned tournament from the dashboard.',
            actionLabel: 'Back to Dashboard',
            onAction: () => context.go(AppRoutes.tournamentOrganizerDashboard),
          );
        }

        final cubit = context.read<TournamentOrganizerCubit>();
        final theme = Theme.of(context);
        final category = state.selectedCategory;
        final seeds = category != null
            ? (state.data.categoryDraws[category.id] ?? const <DrawSeedEntry>[])
            : const <DrawSeedEntry>[];
        final categoryMatches = category != null
            ? state.tournamentMatches
                .where((m) => m.categoryId == category.id)
                .toList()
            : const <OrganizerMatchSlot>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tournament.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            context.go(AppRoutes.tournamentOrganizerDashboard),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Dashboard'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: tournament.categories.map((c) {
                      return ChoiceChip(
                        label: Text('${c.name} (${c.bracketFormat.label})'),
                        selected: c.id == category?.id,
                        onSelected: (_) => cubit.selectCategory(c.id),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (category == null)
              const EmptyStateView(
                title: 'No Categories',
                message: 'Add a category to generate draws.',
              )
            else ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Seeding — ${category.name}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${category.bracketFormat.label} • ${category.eventFormat.label}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => cubit.generateDraw(
                            tournamentId: tournament.id,
                            categoryId: category.id,
                          ),
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          label: Text(
                            seeds.isEmpty ? 'Generate Draw' : 'Regenerate Draw',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (seeds.isEmpty)
                      const EmptyStateView(
                        title: 'Draw Not Generated',
                        message:
                            'Click "Generate Draw" once at least 2 confirmed entries exist.',
                      )
                    else
                      ...seeds.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final seed = entry.value;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            child: Text('${seed.seedNumber}'),
                          ),
                          title: Text(seed.participantLabel),
                          subtitle: seed.groupName != null
                              ? Text(seed.groupName!)
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Move Seed Up',
                                icon: const Icon(Icons.arrow_upward, size: 18),
                                onPressed: idx > 0
                                    ? () => cubit.swapSeedOrder(
                                          tournamentId: tournament.id,
                                          categoryId: category.id,
                                          indexA: idx,
                                          indexB: idx - 1,
                                        )
                                    : null,
                              ),
                              IconButton(
                                tooltip: 'Move Seed Down',
                                icon:
                                    const Icon(Icons.arrow_downward, size: 18),
                                onPressed: idx < seeds.length - 1
                                    ? () => cubit.swapSeedOrder(
                                          tournamentId: tournament.id,
                                          categoryId: category.id,
                                          indexA: idx,
                                          indexB: idx + 1,
                                        )
                                    : null,
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Match Schedule & Court Assignments (${categoryMatches.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (categoryMatches.isEmpty)
                      const EmptyStateView(
                        title: 'No Matches Scheduled',
                        message: 'Generate the draw to populate match slots.',
                      )
                    else
                      ...categoryMatches.map((match) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title:
                              Text('${match.participantA} vs ${match.participantB}'),
                          subtitle: Text(
                            '${match.roundLabel} • ${match.courtName ?? 'No Court'}'
                            '${match.refereeName != null ? ' • Ref: ${match.refereeName}' : ' • No Referee'}'
                            ' • ${match.status.label}',
                          ),
                          trailing: OutlinedButton(
                            onPressed: () => _showScheduleDialog(
                              context,
                              cubit,
                              state,
                              tournament,
                              match,
                            ),
                            child: const Text('Assign'),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _showScheduleDialog(
    BuildContext context,
    TournamentOrganizerCubit cubit,
    TournamentOrganizerLoaded state,
    OrganizerTournament tournament,
    OrganizerMatchSlot match,
  ) async {
    final courts = tournament.courts;
    var selectedCourt =
        match.courtName != null && courts.contains(match.courtName)
            ? match.courtName!
            : courts.first;
    final referees = state.tournamentStaff
        .where((s) => s.role == OrganizerStaffRole.referee && s.isActive)
        .toList();
    String? selectedRefId = referees.isNotEmpty ? referees.first.id : null;
    var hourOffset = 10 + match.matchNumber;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Court, Time & Referee'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedCourt,
                decoration: const InputDecoration(labelText: 'Court'),
                items: courts
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => selectedCourt = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                initialValue: hourOffset,
                decoration: const InputDecoration(labelText: 'Start Hour'),
                items: List.generate(10, (i) => 9 + i)
                    .map(
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text('${h.toString().padLeft(2, '0')}:00'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => hourOffset = v);
                },
              ),
              if (referees.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: selectedRefId,
                  decoration: const InputDecoration(labelText: 'Referee'),
                  items: referees
                      .map(
                        (r) => DropdownMenuItem(
                          value: r.id,
                          child: Text(r.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedRefId = v),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      final scheduled = DateTime(
        tournament.startDate.year,
        tournament.startDate.month,
        tournament.startDate.day,
        hourOffset,
      );
      await cubit.assignMatchScheduleAndReferee(
        tournamentId: tournament.id,
        matchId: match.id,
        courtName: selectedCourt,
        scheduledTime: scheduled,
        refereeAssignmentId: selectedRefId,
      );
    }
  }
}
