import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_cubit.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/widgets/tournament_organizer_page_scaffold.dart';

/// Tournament creation & configuration wizard (Phase 5 — Feature 5.1).
class TournamentCreateWizardPage extends StatefulWidget {
  final TournamentOrganizerCubit? cubit;
  final String? organizerId;

  const TournamentCreateWizardPage({
    super.key,
    this.cubit,
    this.organizerId,
  });

  @override
  State<TournamentCreateWizardPage> createState() =>
      _TournamentCreateWizardPageState();
}

class _TournamentCreateWizardPageState
    extends State<TournamentCreateWizardPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Mumbai');
  final _addressCtrl = TextEditingController();
  final _prizeCtrl = TextEditingController(text: '₹1,00,000');
  final _descCtrl = TextEditingController();
  final _courtsCtrl = TextEditingController(text: 'Court 1, Court 2, Court 3');

  TournamentScoringMethod _scoringMethod =
      TournamentScoringMethod.sideOutScoring;
  int _pointsPerGame = 11;
  int _bestOfGames = 3;
  int _winBy = 2;
  bool _trackPositions = true;
  bool _publishImmediately = true;

  final List<OrganizerCategoryConfig> _draftCategories = [
    const OrganizerCategoryConfig(
      id: 'draft_1',
      tournamentId: '',
      organizerId: '',
      name: "Men's Singles Open",
      eventFormat: TournamentEventFormat.singles,
      bracketFormat: TournamentBracketFormat.knockout,
      entryFeeInr: 1500,
      maxParticipants: 16,
      autoApproveEligible: true,
    ),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _venueCtrl.dispose();
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _prizeCtrl.dispose();
    _descCtrl.dispose();
    _courtsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TournamentOrganizerPageScaffold(
      cubit: widget.cubit,
      organizerId: widget.organizerId,
      title: 'Create Tournament',
      subtitle:
          'Configure tournament details, scoring rules, courts, and event categories.',
      bodyBuilder: (context, state) {
        final cubit = context.read<TournamentOrganizerCubit>();
        final theme = Theme.of(context);

        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Tournament Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tournament Name',
                        hintText: 'e.g. Western India Open 2026',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _venueCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Venue Name',
                        hintText: 'e.g. Grand Slam Pickleball Arena',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityCtrl,
                            decoration: const InputDecoration(labelText: 'City'),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: TextFormField(
                            controller: _prizeCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Prize Pool'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _courtsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Available Courts (comma-separated)',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
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
                      '2. Organizer Scoring Rules (Enforced by Referee UI)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<TournamentScoringMethod>(
                      initialValue: _scoringMethod,
                      decoration:
                          const InputDecoration(labelText: 'Scoring Method'),
                      items: TournamentScoringMethod.values
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m.label)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _scoringMethod = v);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _pointsPerGame,
                            decoration:
                                const InputDecoration(labelText: 'Target Points'),
                            items: const [11, 15, 21]
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text('$p pts'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _pointsPerGame = v);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _bestOfGames,
                            decoration:
                                const InputDecoration(labelText: 'Match Format'),
                            items: const [1, 3, 5]
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text('Best of $g'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _bestOfGames = v);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: _winBy,
                            decoration:
                                const InputDecoration(labelText: 'Win By'),
                            items: const [1, 2]
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w,
                                    child: Text('Win by $w'),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _winBy = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Track Positions & Service Order'),
                      value: _trackPositions,
                      onChanged: (v) => setState(() => _trackPositions = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '3. Categories (${_draftCategories.length})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _addQuickCategory,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Category'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ..._draftCategories.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final cat = entry.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(cat.name),
                        subtitle: Text(
                          '${cat.eligibilitySummary} • Capacity: ${cat.maxParticipants} • Fee: ₹${cat.entryFeeInr.toStringAsFixed(0)}',
                        ),
                        trailing: _draftCategories.length > 1
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => setState(
                                  () => _draftCategories.removeAt(idx),
                                ),
                              )
                            : null,
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                title: const Text('Publish & Open Registration Immediately'),
                value: _publishImmediately,
                onChanged: (v) => setState(() => _publishImmediately = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        context.go(AppRoutes.tournamentOrganizerDashboard),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    onPressed: () => _submit(context, cubit, state.data.organizerId),
                    icon: const Icon(Icons.check),
                    label: const Text('Save Tournament'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addQuickCategory() async {
    final nameCtrl = TextEditingController();
    var format = TournamentEventFormat.doubles;
    var bracket = TournamentBracketFormat.roundRobin;
    final feeCtrl = TextEditingController(text: '2000');
    final capCtrl = TextEditingController(text: '12');

    final added = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Event Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Mixed Doubles 3.5',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<TournamentEventFormat>(
                  initialValue: format,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: TournamentEventFormat.values
                      .map((f) => DropdownMenuItem(value: f, child: Text(f.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => format = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<TournamentBracketFormat>(
                  initialValue: bracket,
                  decoration: const InputDecoration(labelText: 'Draw Format'),
                  items: TournamentBracketFormat.values
                      .map((b) => DropdownMenuItem(value: b, child: Text(b.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => bracket = v);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Entry Fee (INR)'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: capCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Capacity'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (added == true && nameCtrl.text.trim().isNotEmpty) {
      setState(() {
        _draftCategories.add(
          OrganizerCategoryConfig(
            id: 'draft_${_draftCategories.length + 1}',
            tournamentId: '',
            organizerId: '',
            name: nameCtrl.text.trim(),
            eventFormat: format,
            bracketFormat: bracket,
            entryFeeInr: double.tryParse(feeCtrl.text.trim()) ?? 1500,
            maxParticipants: int.tryParse(capCtrl.text.trim()) ?? 16,
            autoApproveEligible: true,
          ),
        );
      });
    }

    nameCtrl.dispose();
    feeCtrl.dispose();
    capCtrl.dispose();
  }

  Future<void> _submit(
    BuildContext context,
    TournamentOrganizerCubit cubit,
    String organizerId,
  ) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final now = DateTime.now();
    final courts = _courtsCtrl.text
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final created = OrganizerTournament(
      id: '',
      organizerId: organizerId,
      organizationName: '',
      name: _nameCtrl.text.trim(),
      venueName: _venueCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      startDate: now.add(const Duration(days: 10)),
      endDate: now.add(const Duration(days: 12)),
      registrationDeadline: now.add(const Duration(days: 8)),
      prizePool: _prizeCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      status: _publishImmediately
          ? OrganizerTournamentStatus.registrationOpen
          : OrganizerTournamentStatus.draft,
      defaultScoring: TournamentScoringConfig(
        method: _scoringMethod,
        pointsPerGame: _pointsPerGame,
        bestOfGames: _bestOfGames,
        winBy: _winBy,
        trackPositionsAndServiceOrder: _trackPositions,
      ),
      categories: _draftCategories,
      courts: courts.isEmpty ? const ['Court 1', 'Court 2'] : courts,
      isPubliclyPublished: _publishImmediately,
    );

    final ok = await cubit.createTournament(created);
    if (ok && context.mounted) {
      context.go(AppRoutes.tournamentOrganizerDashboard);
    }
  }
}
