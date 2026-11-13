import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/widgets/venue_location_filter_bar.dart';
import 'package:pickleball_platform/features/venue_staff/domain/entities/venue_staff_entities.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/cubit/venue_staff_cubit.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/cubit/venue_staff_state.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/widgets/venue_staff_page_scaffold.dart';

/// Venue Staff maintenance tasks, court holds, and purchase receipt submissions
/// scoped to assigned locations (Phase 3 — Feature 3.8).
class VenueStaffTasksPage extends StatelessWidget {
  final VenueStaffCubit? cubit;
  final String? partnerId;
  final String? staffId;

  const VenueStaffTasksPage({
    super.key,
    this.cubit,
    this.partnerId,
    this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    return VenueStaffPageScaffold(
      cubit: cubit,
      partnerId: partnerId,
      staffId: staffId,
      title: 'Maintenance & Purchase Receipts',
      subtitle:
          'Track assigned court maintenance tasks, create holds, and submit expense receipts.',
      bodyBuilder: (context, state) {
        final canMaintenance =
            state.hasPermission(VenueStaffPermission.manageMaintenance);
        final canSubmitPurchases =
            state.hasPermission(VenueStaffPermission.submitPurchases);

        if (!canMaintenance && !canSubmitPurchases) {
          return const EmptyStateView(
            title: 'Tasks & Receipts Restricted',
            message:
                'You do not have delegated maintenance or purchase submission permissions.',
          );
        }

        final cubit = context.read<VenueStaffCubit>();
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.data.assignedLocations.length > 1) ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: VenueLocationFilterBar(
                  locations: state.data.assignedLocations,
                  selectedLocationId: state.selectedLocationId,
                  onLocationSelected: cubit.selectLocation,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (canMaintenance) ...[
              _buildMaintenanceSection(context, theme, cubit, state),
              const SizedBox(height: AppSpacing.md),
              _buildBlocksSection(context, theme, cubit, state),
              const SizedBox(height: AppSpacing.md),
            ],
            if (canSubmitPurchases)
              _buildPurchasesSection(context, theme, cubit, state),
          ],
        );
      },
    );
  }

  Widget _buildMaintenanceSection(
    BuildContext context,
    ThemeData theme,
    VenueStaffCubit cubit,
    VenueStaffLoaded state,
  ) {
    final tasks = state.scopedTasks;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned Maintenance Tasks (${tasks.length})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (tasks.isEmpty)
            const EmptyStateView(
              title: 'No Maintenance Tasks',
              message: 'No maintenance tasks assigned for the selected scope.',
            )
          else
            ...tasks.map((task) {
              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(task.status.label),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    Text(
                      '${task.courtName} • ${task.locationName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(task.description, style: theme.textTheme.bodySmall),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: VenueMaintenanceTaskStatus.values.map((status) {
                        final selected = task.status == status;
                        return ChoiceChip(
                          label: Text(status.label),
                          selected: selected,
                          onSelected: selected
                              ? null
                              : (_) => cubit.updateTaskStatus(
                                    taskId: task.id,
                                    status: status,
                                  ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildBlocksSection(
    BuildContext context,
    ThemeData theme,
    VenueStaffCubit cubit,
    VenueStaffLoaded state,
  ) {
    final blocks = state.scopedBlocks;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Court Maintenance Holds (${blocks.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: state.data.courts.isEmpty
                    ? null
                    : () => _showCreateBlockDialog(context, cubit, state),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Hold'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (blocks.isEmpty)
            const EmptyStateView(
              title: 'No Active Court Holds',
              message: 'No maintenance holds are scheduled for these courts.',
            )
          else
            ...blocks.map(
              (block) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.build_outlined, color: AppColors.warning),
                title: Text('${block.title} • ${block.courtName}'),
                subtitle: Text(
                  '${block.reason}\n${_formatRange(block.startTime, block.endTime)}',
                ),
                isThreeLine: true,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPurchasesSection(
    BuildContext context,
    ThemeData theme,
    VenueStaffCubit cubit,
    VenueStaffLoaded state,
  ) {
    final purchases = state.scopedPurchases;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Purchase Submissions (${purchases.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: state.data.assignedLocations.isEmpty
                    ? null
                    : () => _showSubmitPurchaseDialog(context, cubit, state),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: const Text('Submit Receipt'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (purchases.isEmpty)
            const EmptyStateView(
              title: 'No Purchase Receipts',
              message: 'Submit a venue purchase with its receipt reference.',
            )
          else
            ...purchases.map(
              (purchase) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_outlined, color: AppColors.info),
                title: Text(
                  '${purchase.title} • ₹${purchase.amountInr.toStringAsFixed(0)}',
                ),
                subtitle: Text(
                  '${purchase.category} • ${purchase.locationName} • Receipt: ${purchase.receiptReference}',
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatRange(DateTime start, DateTime end) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.day)}/${two(start.month)} ${two(start.hour)}:${two(start.minute)}'
        ' - ${two(end.hour)}:${two(end.minute)}';
  }

  Future<void> _showCreateBlockDialog(
    BuildContext context,
    VenueStaffCubit cubit,
    VenueStaffLoaded state,
  ) async {
    final courts = state.scopedCourts.isNotEmpty
        ? state.scopedCourts
        : state.data.courts;
    var selectedCourtId = courts.first.id;
    final titleCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Court Maintenance Hold'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedCourtId,
                        decoration: const InputDecoration(labelText: 'Court'),
                        items: courts
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.name} (${c.locationName})'),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedCourtId = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Hold Title',
                          hintText: 'e.g. Net Tension Repair',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: reasonCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reason',
                          hintText: 'Brief maintenance reason',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
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
                  child: const Text('Create Hold'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      final now = DateTime.now();
      await cubit.createMaintenanceBlock(
        courtId: selectedCourtId,
        title: titleCtrl.text.trim(),
        reason: reasonCtrl.text.trim(),
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
      );
    }

    titleCtrl.dispose();
    reasonCtrl.dispose();
  }

  Future<void> _showSubmitPurchaseDialog(
    BuildContext context,
    VenueStaffCubit cubit,
    VenueStaffLoaded state,
  ) async {
    final locations = state.data.assignedLocations;
    var selectedLocationId = state.selectedLocationId ?? locations.first.id;
    final titleCtrl = TextEditingController();
    final categoryCtrl = TextEditingController(text: 'Court Supplies');
    final amountCtrl = TextEditingController();
    final receiptCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Submit Purchase Receipt'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedLocationId,
                        decoration:
                            const InputDecoration(labelText: 'Assigned Location'),
                        items: locations
                            .map(
                              (l) => DropdownMenuItem(
                                value: l.id,
                                child: Text(l.name),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => selectedLocationId = val);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Purchase Title',
                          hintText: 'e.g. Outdoor Pickleballs (24 pack)',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: categoryCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(labelText: 'Amount (INR)'),
                        validator: (v) {
                          final parsed = double.tryParse(v?.trim() ?? '');
                          if (parsed == null || parsed <= 0) {
                            return 'Enter a positive amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: receiptCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Receipt Reference',
                          hintText: 'e.g. RCP-2026-0412',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Receipt reference is required'
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
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true) {
      await cubit.submitPurchaseReceipt(
        locationId: selectedLocationId,
        title: titleCtrl.text.trim(),
        category: categoryCtrl.text.trim(),
        amountInr: double.parse(amountCtrl.text.trim()),
        receiptReference: receiptCtrl.text.trim(),
      );
    }

    titleCtrl.dispose();
    categoryCtrl.dispose();
    amountCtrl.dispose();
    receiptCtrl.dispose();
  }
}
