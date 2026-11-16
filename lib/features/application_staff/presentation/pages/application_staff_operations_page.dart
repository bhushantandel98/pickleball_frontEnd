import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/application_staff/domain/entities/application_staff_entities.dart';
import 'package:pickleball_platform/features/application_staff/presentation/cubit/application_staff_cubit.dart';
import 'package:pickleball_platform/features/application_staff/presentation/widgets/application_staff_scaffold.dart';

/// Feature 7.1 — Application Staff Operational Queue & Triage screen.
class ApplicationStaffOperationsPage extends StatefulWidget {
  final ApplicationStaffCubit? cubit;
  final String? userId;
  final String? staffId;

  const ApplicationStaffOperationsPage({
    super.key,
    this.cubit,
    this.userId,
    this.staffId,
  });

  @override
  State<ApplicationStaffOperationsPage> createState() =>
      _ApplicationStaffOperationsPageState();
}

class _ApplicationStaffOperationsPageState
    extends State<ApplicationStaffOperationsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ApplicationStaffScaffold(
      cubit: widget.cubit,
      userId: widget.userId,
      staffId: widget.staffId,
      requiredPermission: ApplicationStaffPermission.viewDashboard,
      title: 'Staff Operational Queue',
      subtitle:
          'Review, request information, triage support & escalate to Application Admin.',
      actionsBuilder: (context, _) => [
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.applicationStaffDashboard),
          icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Dashboard'),
        ),
      ],
      bodyBuilder: (context, state) {
        final cubit = context.read<ApplicationStaffCubit>();
        final allowedCategories = StaffQueueCategory.values
            .where((c) => state.profile.hasPermission(c.requiredPermission))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by organization, title, or summary...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                cubit.applyFilters(query: '');
                              },
                            )
                          : null,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (q) => cubit.applyFilters(query: q),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Permitted'),
                          selected: state.selectedCategory == null,
                          onSelected: (_) =>
                              cubit.applyFilters(clearCategory: true),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ...allowedCategories.map(
                          (cat) => Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: FilterChip(
                              label: Text(cat.label),
                              selected: state.selectedCategory == cat,
                              onSelected: (_) =>
                                  cubit.applyFilters(category: cat),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('All Statuses'),
                          selected: state.selectedStatus == null,
                          onSelected: (_) =>
                              cubit.applyFilters(clearStatus: true),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ...StaffQueueItemStatus.values.map(
                          (st) => Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.xs),
                            child: FilterChip(
                              label: Text(st.label),
                              selected: state.selectedStatus == st,
                              onSelected: (_) =>
                                  cubit.applyFilters(status: st),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.queueItems.isEmpty)
              const EmptyStateView(
                title: 'No Matching Queue Items',
                message:
                    'No operational items match your current filters and delegated permissions.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.queueItems.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = state.queueItems[index];
                  final canAct = state.profile.hasPermission(
                    item.category.requiredPermission,
                  );
                  return _QueueItemCard(
                    item: item,
                    canAct: canAct && !state.isMutating,
                    onAction: (nextStatus) => _promptNoteAndSubmit(
                      context,
                      cubit,
                      item,
                      nextStatus,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _promptNoteAndSubmit(
    BuildContext context,
    ApplicationStaffCubit cubit,
    StaffOperationalQueueItem item,
    StaffQueueItemStatus nextStatus,
  ) async {
    final noteCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${nextStatus.label} — ${item.organizationName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action applies to ${item.category.label} (${item.organizationId}). Final Admin approvals remain restricted to Application Admin.',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Staff Audit Note *',
                hintText: 'Enter verification findings or triage notes...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.updateQueueItem(
        itemId: item.id,
        nextStatus: nextStatus,
        note: noteCtrl.text,
      );
    }
    noteCtrl.dispose();
  }
}

class _QueueItemCard extends StatelessWidget {
  final StaffOperationalQueueItem item;
  final bool canAct;
  final ValueChanged<StaffQueueItemStatus> onAction;

  const _QueueItemCard({
    required this.item,
    required this.canAct,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd MMM yyyy, HH:mm');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                item.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Chip(label: Text(item.category.label)),
              Chip(label: Text(item.status.label)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Organization: ${item.organizationName} (${item.organizationId}) • Submitted ${df.format(item.submittedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(item.summary, style: theme.textTheme.bodyMedium),
          if (item.staffNote != null && item.staffNote!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Latest Staff Note: ${item.staffNote}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const Divider(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              OutlinedButton.icon(
                onPressed: canAct
                    ? () => onAction(StaffQueueItemStatus.needsInformation)
                    : null,
                icon: const Icon(Icons.help_outline, size: 18),
                label: const Text('Request Info'),
              ),
              FilledButton.icon(
                onPressed: canAct
                    ? () => onAction(StaffQueueItemStatus.recommendedToAdmin)
                    : null,
                icon: const Icon(Icons.recommend_outlined, size: 18),
                label: const Text('Recommend to Admin'),
              ),
              OutlinedButton.icon(
                onPressed: canAct
                    ? () => onAction(StaffQueueItemStatus.escalatedToAdmin)
                    : null,
                icon: const Icon(Icons.escalator_warning_outlined, size: 18),
                label: const Text('Escalate'),
              ),
              if (item.category == StaffQueueCategory.supportTriage)
                OutlinedButton.icon(
                  onPressed: canAct
                      ? () => onAction(StaffQueueItemStatus.resolved)
                      : null,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Resolve Support'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
