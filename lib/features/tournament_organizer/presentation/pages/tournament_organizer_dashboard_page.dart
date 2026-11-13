import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_cubit.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_state.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/widgets/tournament_organizer_page_scaffold.dart';

/// Primary Tournament Organizer Dashboard (Phase 5 — Feature 5.1).
class TournamentOrganizerDashboardPage extends StatelessWidget {
  final TournamentOrganizerCubit? cubit;
  final String? organizerId;

  const TournamentOrganizerDashboardPage({
    super.key,
    this.cubit,
    this.organizerId,
  });

  @override
  Widget build(BuildContext context) {
    return TournamentOrganizerPageScaffold(
      cubit: cubit,
      organizerId: organizerId,
      title: 'Tournament Organizer Dashboard',
      subtitle:
          'Manage tournaments, categories, automatic registrations, draws, Match Day monitoring & finances.',
      bodyBuilder: (context, state) {
        final cubit = context.read<TournamentOrganizerCubit>();
        final theme = Theme.of(context);
        final tournament = state.selectedTournament;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrganizerHeader(context, theme, cubit, state),
            const SizedBox(height: AppSpacing.md),
            _buildKpiRow(context, state),
            const SizedBox(height: AppSpacing.md),
            if (tournament == null)
              EmptyStateView(
                title: 'No Tournaments Yet',
                message: 'Create your first tournament to configure categories and draws.',
                actionLabel: 'Create Tournament',
                onAction: () => context.go(AppRoutes.tournamentOrganizerCreate),
              )
            else ...[
              _buildTournamentControlCard(context, theme, cubit, tournament),
              const SizedBox(height: AppSpacing.md),
              _buildCategoriesCard(context, theme, cubit, tournament),
              const SizedBox(height: AppSpacing.md),
              _buildRegistrationsCard(context, theme, cubit, state, tournament),
              const SizedBox(height: AppSpacing.md),
              _buildMatchDayAndFinanceCard(context, theme, cubit, state, tournament),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOrganizerHeader(
    BuildContext context,
    ThemeData theme,
    TournamentOrganizerCubit cubit,
    TournamentOrganizerLoaded state,
  ) {
    return AppCard(
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
                      state.data.organizationName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Organizer ID: ${state.data.organizerId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => context.go(AppRoutes.tournamentOrganizerCreate),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Create Tournament'),
              ),
            ],
          ),
          if (state.data.tournaments.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: state.data.tournaments.map((t) {
                return ChoiceChip(
                  label: Text('${t.name} (${t.status.label})'),
                  selected: t.id == state.selectedTournament?.id,
                  onSelected: (_) => cubit.selectTournament(t.id),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, TournamentOrganizerLoaded state) {
    final cards = [
      _KpiTile(
        label: 'Owned Tournaments',
        value: '${state.data.tournaments.length}',
        icon: Icons.emoji_events_outlined,
        color: AppColors.primary,
      ),
      _KpiTile(
        label: 'Confirmed Entries',
        value: '${state.tournamentRegistrations.length}',
        icon: Icons.groups_outlined,
        color: AppColors.success,
      ),
      _KpiTile(
        label: 'Matches Scheduled',
        value: '${state.tournamentMatches.length}',
        icon: Icons.sports_tennis,
        color: AppColors.warning,
      ),
      _KpiTile(
        label: 'Gross Entry Fees',
        value: '₹${state.tournamentGrossFeesInr.toStringAsFixed(0)}',
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.info,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 560 ? 2 : 1);
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * AppSpacing.sm) / columns;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: cards
              .map((c) => SizedBox(width: itemWidth, child: c))
              .toList(),
        );
      },
    );
  }

  Widget _buildTournamentControlCard(
    BuildContext context,
    ThemeData theme,
    TournamentOrganizerCubit cubit,
    OrganizerTournament tournament,
  ) {
    return AppCard(
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
                      tournament.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${tournament.venueName}, ${tournament.city} • ${tournament.formattedDateRange} • Prize Pool: ${tournament.prizePool}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scoring Rules: ${tournament.defaultScoring.formattedSummary}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Chip(label: Text(tournament.status.label)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              FilledButton.icon(
                onPressed: () =>
                    context.go('/tournament-organizer/${tournament.id}/draws'),
                icon: const Icon(Icons.account_tree_outlined, size: 18),
                label: const Text('Draws & Schedule'),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    context.go('/tournament-organizer/${tournament.id}/staff'),
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Staff & Referees'),
              ),
              if (tournament.status == OrganizerTournamentStatus.draft)
                FilledButton.tonal(
                  onPressed: () => cubit.updateTournamentStatus(
                    tournamentId: tournament.id,
                    status: OrganizerTournamentStatus.published,
                  ),
                  child: const Text('Publish'),
                ),
              if (tournament.status == OrganizerTournamentStatus.published)
                FilledButton.tonal(
                  onPressed: () => cubit.updateTournamentStatus(
                    tournamentId: tournament.id,
                    status: OrganizerTournamentStatus.registrationOpen,
                  ),
                  child: const Text('Open Registration'),
                ),
              if (tournament.status == OrganizerTournamentStatus.registrationOpen)
                FilledButton.tonal(
                  onPressed: () => cubit.updateTournamentStatus(
                    tournamentId: tournament.id,
                    status: OrganizerTournamentStatus.inProgress,
                  ),
                  child: const Text('Start Match Day'),
                ),
              if (tournament.status == OrganizerTournamentStatus.inProgress)
                FilledButton.tonal(
                  onPressed: () => cubit.updateTournamentStatus(
                    tournamentId: tournament.id,
                    status: OrganizerTournamentStatus.completed,
                  ),
                  child: const Text('Mark Completed'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard(
    BuildContext context,
    ThemeData theme,
    TournamentOrganizerCubit cubit,
    OrganizerTournament tournament,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Categories & Eligibility (${tournament.categories.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _showAddCategoryDialog(context, cubit, tournament),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (tournament.categories.isEmpty)
            const EmptyStateView(
              title: 'No Categories',
              message: 'Add Singles, Doubles, Mixed Doubles, or Team categories.',
            )
          else
            ...tournament.categories.map(
              (cat) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(cat.name),
                subtitle: Text(
                  '${cat.eligibilitySummary} • Fee: ₹${cat.entryFeeInr.toStringAsFixed(0)}'
                  '${cat.autoApproveEligible ? ' • Auto-Confirm On' : ' • Manual Review'}',
                ),
                trailing: Chip(
                  label: Text('${cat.registeredCount}/${cat.maxParticipants}'),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRegistrationsCard(
    BuildContext context,
    ThemeData theme,
    TournamentOrganizerCubit cubit,
    TournamentOrganizerLoaded state,
    OrganizerTournament tournament,
  ) {
    final regs = state.tournamentRegistrations;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Registrations (${regs.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: tournament.categories.isEmpty
                    ? null
                    : () => _showAutoRegistrationDialog(
                          context,
                          cubit,
                          tournament,
                        ),
                icon: const Icon(Icons.person_add_alt_1, size: 18),
                label: const Text('Add / Test Auto-Registration'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (regs.isEmpty)
            const EmptyStateView(
              title: 'No Registrations',
              message: 'Eligible registrations will appear here once submitted.',
            )
          else
            ...regs.map(
              (reg) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(reg.displayParticipant),
                subtitle: Text(
                  '${reg.categoryName} • DUPR ${reg.playerRating} • Age ${reg.playerAge} • ₹${reg.feePaidInr.toStringAsFixed(0)}',
                ),
                trailing: Chip(
                  label: Text(reg.status.label),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchDayAndFinanceCard(
    BuildContext context,
    ThemeData theme,
    TournamentOrganizerCubit cubit,
    TournamentOrganizerLoaded state,
    OrganizerTournament tournament,
  ) {
    final matches = state.tournamentMatches;
    final breakdown = state.categoryFeeBreakdown;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Day Monitor & Finance Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (breakdown.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: breakdown.entries
                  .map(
                    (e) => Chip(
                      label: Text('${e.key}: ₹${e.value.toStringAsFixed(0)}'),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (matches.isEmpty)
            const EmptyStateView(
              title: 'No Scheduled Matches',
              message: 'Generate a draw to schedule matches and monitor Match Day.',
            )
          else
            ...matches.map(
              (m) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${m.participantA} vs ${m.participantB}'),
                subtitle: Text(
                  '${m.categoryName} • ${m.roundLabel} • ${m.courtName ?? 'Unassigned Court'}'
                  '${m.refereeName != null ? ' • Ref: ${m.refereeName}' : ''}'
                  '${m.scoreSummary != null ? ' • Score: ${m.scoreSummary} (${m.winnerLabel})' : ''}',
                ),
                trailing: TextButton(
                  onPressed: () => _showScoreDialog(context, cubit, m),
                  child: Text(
                    m.status == OrganizerMatchStatus.completed
                        ? 'Edit Score'
                        : 'Record Score',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showAddCategoryDialog(
    BuildContext context,
    TournamentOrganizerCubit cubit,
    OrganizerTournament tournament,
  ) async {
    final nameCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '1500');
    final capCtrl = TextEditingController(text: '16');
    final minRatingCtrl = TextEditingController();
    final maxRatingCtrl = TextEditingController();
    var eventFormat = TournamentEventFormat.singles;
    var bracketFormat = TournamentBracketFormat.knockout;
    var autoApprove = true;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Category'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      hintText: 'e.g. Mixed Doubles 4.0',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<TournamentEventFormat>(
                    initialValue: eventFormat,
                    decoration: const InputDecoration(labelText: 'Discipline'),
                    items: TournamentEventFormat.values
                        .map(
                          (f) => DropdownMenuItem(value: f, child: Text(f.label)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => eventFormat = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<TournamentBracketFormat>(
                    initialValue: bracketFormat,
                    decoration: const InputDecoration(labelText: 'Draw Format'),
                    items: TournamentBracketFormat.values
                        .map(
                          (f) => DropdownMenuItem(value: f, child: Text(f.label)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => bracketFormat = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: minRatingCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Min DUPR'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: maxRatingCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Max DUPR'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: feeCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Fee (INR)'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: TextFormField(
                          controller: capCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Capacity'),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-confirm eligible entries'),
                    value: autoApprove,
                    onChanged: (v) => setState(() => autoApprove = v),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await cubit.addCategory(
        tournamentId: tournament.id,
        category: OrganizerCategoryConfig(
          id: '',
          tournamentId: tournament.id,
          organizerId: tournament.organizerId,
          name: nameCtrl.text.trim(),
          eventFormat: eventFormat,
          bracketFormat: bracketFormat,
          minRating: double.tryParse(minRatingCtrl.text.trim()),
          maxRating: double.tryParse(maxRatingCtrl.text.trim()),
          entryFeeInr: double.tryParse(feeCtrl.text.trim()) ?? 0,
          maxParticipants: int.tryParse(capCtrl.text.trim()) ?? 16,
          autoApproveEligible: autoApprove,
        ),
      );
    }

    nameCtrl.dispose();
    feeCtrl.dispose();
    capCtrl.dispose();
    minRatingCtrl.dispose();
    maxRatingCtrl.dispose();
  }

  Future<void> _showAutoRegistrationDialog(
    BuildContext context,
    TournamentOrganizerCubit cubit,
    OrganizerTournament tournament,
  ) async {
    var selectedCatId = tournament.categories.first.id;
    final playerCtrl = TextEditingController();
    final partnerCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: '+91 98200 00000');
    final ratingCtrl = TextEditingController(text: '3.5');
    final ageCtrl = TextEditingController(text: '25');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final selectedCat = tournament.categories
              .firstWhere((c) => c.id == selectedCatId);
          return AlertDialog(
            title: const Text('Register Participant / Team'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCatId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: tournament.categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text('${c.name} (${c.eventFormat.label})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => selectedCatId = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: playerCtrl,
                      decoration: InputDecoration(
                        labelText: selectedCat.eventFormat ==
                                TournamentEventFormat.team
                            ? 'Team Name'
                            : 'Player Name',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    if (selectedCat.eventFormat !=
                        TournamentEventFormat.singles) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: partnerCtrl,
                        decoration: InputDecoration(
                          labelText: selectedCat.eventFormat ==
                                  TournamentEventFormat.team
                              ? 'Squad Summary'
                              : 'Partner Name',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: ratingCtrl,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'DUPR Rating'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: ageCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Age'),
                          ),
                        ),
                      ],
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
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true) {
      await cubit.submitAutoRegistration(
        tournamentId: tournament.id,
        categoryId: selectedCatId,
        playerName: playerCtrl.text.trim(),
        partnerOrTeamName: partnerCtrl.text.trim().isEmpty
            ? null
            : partnerCtrl.text.trim(),
        playerEmail: emailCtrl.text.trim(),
        playerPhone: phoneCtrl.text.trim(),
        playerRating: double.tryParse(ratingCtrl.text.trim()) ?? 3.5,
        playerAge: int.tryParse(ageCtrl.text.trim()) ?? 25,
      );
    }

    playerCtrl.dispose();
    partnerCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    ratingCtrl.dispose();
    ageCtrl.dispose();
  }

  Future<void> _showScoreDialog(
    BuildContext context,
    TournamentOrganizerCubit cubit,
    OrganizerMatchSlot match,
  ) async {
    final scoreCtrl = TextEditingController(
      text: match.scoreSummary ?? '11-8, 11-6',
    );
    var winner = match.winnerLabel ?? match.participantA;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Record / Correct Match Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${match.participantA} vs ${match.participantB}'),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: scoreCtrl,
                decoration: const InputDecoration(labelText: 'Score Summary'),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save Score'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await cubit.updateMatchScore(
        tournamentId: match.tournamentId,
        matchId: match.id,
        scoreSummary: scoreCtrl.text.trim(),
        winnerLabel: winner,
      );
    }
    scoreCtrl.dispose();
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
