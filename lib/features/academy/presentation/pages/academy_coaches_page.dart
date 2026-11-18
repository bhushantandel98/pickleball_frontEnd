import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/academy/domain/entities/academy_entities.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_state.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_branch_filter_bar.dart';
import 'package:pickleball_platform/features/academy/presentation/widgets/academy_page_scaffold.dart';
import 'package:pickleball_platform/features/academy_staff/domain/entities/academy_staff_entities.dart';

/// Shared Academy Coaches management page (Coach Search, Requests, Approved List & Batch Assignment).
class AcademyCoachesPage extends StatefulWidget {
  final AcademyCubit? cubit;
  final String academyId;

  const AcademyCoachesPage({
    super.key,
    this.cubit,
    this.academyId = 'acad_001',
  });

  @override
  State<AcademyCoachesPage> createState() => _AcademyCoachesPageState();
}

class _AcademyCoachesPageState extends State<AcademyCoachesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AcademyPageScaffold(
      cubit: widget.cubit,
      academyId: widget.academyId,
      title: 'Academy Coaches',
      subtitle:
          'Search coaches by name or mobile, manage connection requests, and assign approved coaches to batches.',
      bodyBuilder: (context, state) {
        if (!state.isAdmin &&
            !state.hasPermission(AcademyStaffPermission.viewCoaches)) {
          return const EmptyStateView(
            icon: Icon(Icons.lock_outline),
            title: 'Access Restricted',
            message: 'You do not have permission to view academy coaches.',
          );
        }

        final cubit = context.read<AcademyCubit>();
        final theme = Theme.of(context);
        final affiliations = state.scopedAffiliations;
        final approvedCoaches = affiliations
            .where((a) => a.status == CoachAffiliationStatus.accepted)
            .toList();
        final pendingRequests = affiliations
            .where((a) => a.status == CoachAffiliationStatus.pendingAcceptance)
            .toList();

        final query = _searchQuery.trim().toLowerCase();
        final searchMatches = query.isEmpty
            ? const <CoachDirectoryCandidate>[]
            : state.data.coachDirectory.where((c) {
                return c.name.toLowerCase().contains(query) ||
                    c.mobileNumber.toLowerCase().contains(query);
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AcademyBranchFilterBar(
              branches: state.scopedBranches,
              selectedBranchId: state.selectedBranchId,
              onBranchSelected: cubit.selectBranch,
            ),
            const SizedBox(height: AppSpacing.md),

            // 1. Search Coaches by Name or Mobile Number
            if (state.canManageCoaches) ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Find & Connect Coaches',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _searchController,
                      label: 'Search by coach name or mobile number',
                      hint: 'e.g. Kabir or 9820455667',
                      prefixIcon: const Icon(Icons.search),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    if (query.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      if (searchMatches.isEmpty)
                        const Text('No matching coaches found.')
                      else
                        ...searchMatches.map((candidate) {
                          final existing = state.data.coachAffiliations
                              .where((a) => a.coachId == candidate.coachId)
                              .firstOrNull;
                          final isApproved = existing?.status ==
                              CoachAffiliationStatus.accepted;
                          final isPending = existing?.status ==
                              CoachAffiliationStatus.pendingAcceptance;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Text(candidate.name[0]),
                            ),
                            title: Text(candidate.name),
                            subtitle: Text(
                              '${candidate.mobileNumber} • ${candidate.specialization}',
                            ),
                            trailing: Wrap(
                              spacing: AppSpacing.xs,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _showCandidateProfile(context, candidate),
                                  child: const Text('Profile'),
                                ),
                                if (isApproved)
                                  AppChip.info(label: 'Approved')
                                else if (isPending)
                                  AppChip.neutral(label: 'Pending')
                                else
                                  FilledButton(
                                    onPressed: () => _showConnectDialog(
                                      context,
                                      state,
                                      candidate,
                                    ),
                                    child: const Text('Connect'),
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // 2. Approved Academy Coach List
            Text(
              'Academy Coach List (${approvedCoaches.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (approvedCoaches.isEmpty)
              const AppCard(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  'No approved coaches yet. Coaches appear here after accepting your connection request.',
                ),
              )
            else
              ...approvedCoaches.map((coach) {
                final candidate = state.data.coachDirectory
                    .where((c) => c.coachId == coach.coachId)
                    .firstOrNull;
                final assignedBatches = state.scopedBatches
                    .where((b) => b.assignedCoachId == coach.coachId)
                    .toList();

                return Padding(
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
                                    coach.coachName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${coach.coachContact} • ${coach.specialization}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppChip.info(label: 'Approved'),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Branches: ${coach.assignedBranchNames.join(', ')}',
                          style: theme.textTheme.bodySmall,
                        ),
                        Text(
                          'Assigned Batches: ${assignedBatches.isEmpty ? 'None' : assignedBatches.map((b) => b.name).join(', ')}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (candidate != null)
                              TextButton(
                                onPressed: () =>
                                    _showCandidateProfile(context, candidate),
                                child: const Text('View Profile'),
                              ),
                            if (state.canManageBatches) ...[
                              const SizedBox(width: AppSpacing.xs),
                              OutlinedButton.icon(
                                onPressed: () => _showAssignBatchDialog(
                                  context,
                                  state,
                                  coach,
                                ),
                                icon: const Icon(
                                  Icons.assignment_ind_outlined,
                                  size: 18,
                                ),
                                label: const Text('Assign to Batch'),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: AppSpacing.md),

            // 3. Separate Pending Connection Requests List
            Text(
              'Pending Connection Requests (${pendingRequests.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (pendingRequests.isEmpty)
              const AppCard(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('No pending coach connection requests.'),
              )
            else
              ...pendingRequests.map(
                (req) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                req.coachName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${req.coachContact} • ${req.specialization}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Requested for: ${req.assignedBranchNames.join(', ')}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.14),
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Text(
                            'Pending Approval',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
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

  Future<void> _showCandidateProfile(
    BuildContext context,
    CoachDirectoryCandidate candidate,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(candidate.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mobile: ${candidate.mobileNumber}'),
            Text('City: ${candidate.city}'),
            Text('Specialization: ${candidate.specialization}'),
            Text('Experience: ${candidate.experienceYears} years'),
            Text('Rating: ${candidate.rating.toStringAsFixed(1)} / 5.0'),
            const SizedBox(height: AppSpacing.sm),
            Text(candidate.bio),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showConnectDialog(
    BuildContext context,
    AcademyLoaded state,
    CoachDirectoryCandidate candidate,
  ) async {
    final cubit = context.read<AcademyCubit>();
    final selectedBranches = <String>{
      if (state.scopedBranches.isNotEmpty) state.scopedBranches.first.id,
    };

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Send Connection Request to ${candidate.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select branches for this connection request. The coach will appear in your Academy Coach List after approving.',
              ),
              const SizedBox(height: AppSpacing.sm),
              ...state.scopedBranches.map(
                (b) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(b.name),
                  value: selectedBranches.contains(b.id),
                  onChanged: (v) => setDialogState(() {
                    if (v == true) {
                      selectedBranches.add(b.id);
                    } else {
                      selectedBranches.remove(b.id);
                    }
                  }),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedBranches.isEmpty
                  ? null
                  : () async {
                      final ok = await cubit.sendCoachConnectionRequest(
                        coachId: candidate.coachId,
                        branchIds: selectedBranches.toList(),
                      );
                      if (ok && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                    },
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignBatchDialog(
    BuildContext context,
    AcademyLoaded state,
    AcademyCoachAffiliation coach,
  ) async {
    final cubit = context.read<AcademyCubit>();
    final batches = state.scopedBatches;
    if (batches.isEmpty) return;

    var selectedBatchId = batches.first.id;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign ${coach.coachName} to Batch'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedBatchId,
            decoration: const InputDecoration(
              labelText: 'Select Batch',
              border: OutlineInputBorder(),
            ),
            items: batches
                .map((b) => DropdownMenuItem(
                      value: b.id,
                      child: Text('${b.name} (${b.branchName})'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setDialogState(() => selectedBatchId = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final batch =
                    batches.firstWhere((b) => b.id == selectedBatchId);
                final ok = await cubit.assignCoachToBatch(
                  batchId: batch.id,
                  branchId: batch.branchId,
                  coachId: coach.coachId,
                );
                if (ok && dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}
