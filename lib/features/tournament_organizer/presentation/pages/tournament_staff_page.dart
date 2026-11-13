import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_cubit.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/widgets/tournament_organizer_page_scaffold.dart';

/// Tournament Staff delegation & Referee assignment screen (Phase 5 — Feature 5.1).
class TournamentStaffPage extends StatelessWidget {
  final String? tournamentId;
  final TournamentOrganizerCubit? cubit;
  final String? organizerId;

  const TournamentStaffPage({
    super.key,
    this.tournamentId,
    this.cubit,
    this.organizerId,
  });

  static const _staffPermissionOptions = <(String, String)>[
    ('VIEW_DASHBOARD', 'View Assigned Dashboard'),
    ('MANAGE_CHECK_IN', 'Check-in & Court Operations'),
    ('MANAGE_REFEREES', 'Manage Referees (Separate Permission)'),
    ('EDIT_MATCH_SCORE', 'Edit Match Score (Separate Permission)'),
  ];

  @override
  Widget build(BuildContext context) {
    return TournamentOrganizerPageScaffold(
      cubit: cubit,
      organizerId: organizerId,
      initialTournamentId: tournamentId,
      title: 'Staff Delegation & Referee Assignment',
      subtitle:
          'Assign Tournament Staff with granular delegated permissions and assign certified Referees.',
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
        final staffList = state.tournamentStaff;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
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
                          '${staffList.length} assigned personnel',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        context.go(AppRoutes.tournamentOrganizerDashboard),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Dashboard'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  FilledButton.icon(
                    onPressed: () =>
                        _showAddStaffDialog(context, cubit, tournament),
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Assign Personnel'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (staffList.isEmpty)
              const EmptyStateView(
                title: 'No Personnel Assigned',
                message: 'Assign Tournament Staff or Referees to this tournament.',
              )
            else
              ...staffList.map(
                (member) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
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
                                    '${member.name} (${member.role.label})',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    member.email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: member.isActive,
                              onChanged: (v) => cubit.toggleStaffActive(
                                tournamentId: tournament.id,
                                assignmentId: member.id,
                                isActive: v,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (member.role == OrganizerStaffRole.referee)
                          const Wrap(
                            spacing: AppSpacing.xs,
                            children: [
                              Chip(
                                label: Text('SCORE_ASSIGNED_MATCHES'),
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          )
                        else
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: _staffPermissionOptions.map((opt) {
                              final code = opt.$1;
                              final label = opt.$2;
                              final enabled =
                                  member.delegatedPermissions.contains(code);
                              return FilterChip(
                                label: Text(label),
                                selected: enabled,
                                onSelected: (selected) {
                                  final next = <String>{
                                    ...member.delegatedPermissions,
                                  };
                                  if (selected) {
                                    next.add(code);
                                  } else {
                                    next.remove(code);
                                  }
                                  cubit.updateStaffPermissions(
                                    tournamentId: tournament.id,
                                    assignmentId: member.id,
                                    delegatedPermissions: next,
                                  );
                                },
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showAddStaffDialog(
    BuildContext context,
    TournamentOrganizerCubit cubit,
    OrganizerTournament tournament,
  ) async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    var role = OrganizerStaffRole.tournamentStaff;
    final perms = <String>{'VIEW_DASHBOARD', 'MANAGE_CHECK_IN'};
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Assign Tournament Staff / Referee'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<OrganizerStaffRole>(
                    initialValue: role,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: OrganizerStaffRole.values
                        .map(
                          (r) => DropdownMenuItem(value: r, child: Text(r.label)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => role = v);
                    },
                  ),
                  if (role == OrganizerStaffRole.tournamentStaff) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ..._staffPermissionOptions.map(
                      (opt) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(opt.$2),
                        value: perms.contains(opt.$1),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              perms.add(opt.$1);
                            } else {
                              perms.remove(opt.$1);
                            }
                          });
                        },
                      ),
                    ),
                  ],
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
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      await cubit.addStaffOrReferee(
        tournamentId: tournament.id,
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        role: role,
        delegatedPermissions: perms,
      );
    }

    nameCtrl.dispose();
    emailCtrl.dispose();
  }
}
