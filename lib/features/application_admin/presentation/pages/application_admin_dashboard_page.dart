import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/application_admin/domain/entities/application_admin_entities.dart';
import 'package:pickleball_platform/features/application_admin/presentation/bloc/application_admin_cubit.dart';
import 'package:pickleball_platform/features/application_admin/presentation/widgets/application_admin_scaffold.dart';

/// Feature 7.2 — Application Admin Macro Dashboard & Final Approval Queue.
class ApplicationAdminDashboardPage extends StatelessWidget {
  final ApplicationAdminCubit? cubit;
  final String? adminUserId;

  const ApplicationAdminDashboardPage({
    super.key,
    this.cubit,
    this.adminUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationAdminScaffold(
      cubit: cubit,
      adminUserId: adminUserId,
      title: 'Application Admin Governance',
      subtitle:
          'Sole-admin final seller/product approvals, staff delegation & platform policies.',
      actionsBuilder: (context, _) => [
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.applicationAdminStaff),
          icon: const Icon(Icons.manage_accounts_outlined),
          label: const Text('Staff'),
        ),
        const SizedBox(width: AppSpacing.xs),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.applicationAdminPolicies),
          icon: const Icon(Icons.policy_outlined),
          label: const Text('Policies'),
        ),
      ],
      bodyBuilder: (context, state) {
        final theme = Theme.of(context);
        final summary = state.summary;
        final adminCubit = context.read<ApplicationAdminCubit>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Sole Admin Governance Notice
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${summary.adminName} (${summary.adminEmail})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Single Application Admin (ADR-007): Only this role grants final Seller/Product approvals, delegates Staff permissions, and configures platform commission & return-window policies.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Macro Governance KPIs
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _AdminMetricTile(
                  label: 'Pending Seller Approvals',
                  value: '${summary.pendingSellerApprovals}',
                ),
                _AdminMetricTile(
                  label: 'Pending Product Approvals',
                  value: '${summary.pendingProductApprovals}',
                ),
                _AdminMetricTile(
                  label: 'Active Staff Members',
                  value: '${summary.activeStaffCount}/${summary.totalStaffCount}',
                ),
                _AdminMetricTile(
                  label: 'Commission Policy',
                  value: summary.policy.isCommissionConfigured
                      ? '${summary.policy.defaultCommissionRatePercent!.toStringAsFixed(1)}%'
                      : 'Not configured',
                ),
                _AdminMetricTile(
                  label: 'Governance Audit Logs',
                  value: '${summary.auditLogCount}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Final Approval Queue (Sellers & Products)
            Text(
              'Final Approval Queue (Sellers & Products)',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                FilterChip(
                  label: const Text('All Types'),
                  selected: state.filterTargetType == null,
                  onSelected: (_) =>
                      adminCubit.applyApprovalFilters(clearTargetType: true),
                ),
                ...AdminApprovalTargetType.values.map(
                  (t) => FilterChip(
                    label: Text(t.label),
                    selected: state.filterTargetType == t,
                    onSelected: (_) =>
                        adminCubit.applyApprovalFilters(targetType: t),
                  ),
                ),
                FilterChip(
                  label: const Text('All Statuses'),
                  selected: state.filterStatus == null,
                  onSelected: (_) =>
                      adminCubit.applyApprovalFilters(clearStatus: true),
                ),
                ...AdminApprovalStatus.values.map(
                  (s) => FilterChip(
                    label: Text(s.label),
                    selected: state.filterStatus == s,
                    onSelected: (_) =>
                        adminCubit.applyApprovalFilters(status: s),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (state.approvals.isEmpty)
              const EmptyStateView(
                title: 'No Matching Approvals',
                message: 'No seller or product items match the active filters.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.approvals.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final item = state.approvals[index];
                  return _ApprovalItemCard(
                    item: item,
                    isMutating: state.isMutating,
                    onDecide: (decision) => _promptDecisionReason(
                      context,
                      adminCubit,
                      item,
                      decision,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _promptDecisionReason(
    BuildContext context,
    ApplicationAdminCubit cubit,
    AdminApprovalItem item,
    AdminApprovalStatus decision,
  ) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${decision.label} — ${item.organizationName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.targetType == AdminApprovalTargetType.productCatalog &&
                      decision == AdminApprovalStatus.approved
                  ? 'Approving this product does NOT auto-publish it; the seller controls publishing.'
                  : 'Provide an audit reason for this final Application Admin decision.',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Admin Decision Reason *',
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
            child: Text('Confirm ${decision.label}'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await cubit.decideApprovalItem(
        itemId: item.id,
        decision: decision,
        reason: reasonCtrl.text,
      );
    }
    reasonCtrl.dispose();
  }
}

class _AdminMetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _AdminMetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 205,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalItemCard extends StatelessWidget {
  final AdminApprovalItem item;
  final bool isMutating;
  final ValueChanged<AdminApprovalStatus> onDecide;

  const _ApprovalItemCard({
    required this.item,
    required this.isMutating,
    required this.onDecide,
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
                item.subjectTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Chip(label: Text(item.targetType.label)),
              Chip(label: Text(item.status.label)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Org: ${item.organizationName} (${item.organizationId}) • Submitted ${df.format(item.submittedAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(item.summary),
          if (item.staffRecommendationNote != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Staff Recommendation (${item.recommendedByStaffId ?? 'Staff'}): ${item.staffRecommendationNote}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.info,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (item.decisionReason != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Admin Decision Reason: ${item.decisionReason}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (item.status.isDecidable) ...[
            const Divider(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                FilledButton.icon(
                  onPressed: isMutating
                      ? null
                      : () => onDecide(AdminApprovalStatus.approved),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text('Final Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: isMutating
                      ? null
                      : () => onDecide(AdminApprovalStatus.needsInformation),
                  icon: const Icon(Icons.help_outline, size: 18),
                  label: const Text('Needs Info'),
                ),
                TextButton.icon(
                  onPressed: isMutating
                      ? null
                      : () => onDecide(AdminApprovalStatus.rejected),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
