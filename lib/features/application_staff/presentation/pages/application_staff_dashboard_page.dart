import 'package:flutter/material.dart';
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

/// Feature 7.1 — Application Staff Dashboard screen.
class ApplicationStaffDashboardPage extends StatelessWidget {
  final ApplicationStaffCubit? cubit;
  final String? userId;
  final String? staffId;

  const ApplicationStaffDashboardPage({
    super.key,
    this.cubit,
    this.userId,
    this.staffId,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationStaffScaffold(
      cubit: cubit,
      userId: userId,
      staffId: staffId,
      requiredPermission: ApplicationStaffPermission.viewDashboard,
      title: 'Application Staff Dashboard',
      subtitle:
          'Permission-gated platform operations, review triage & Admin escalation.',
      actionsBuilder: (context, _) => [
        FilledButton.icon(
          onPressed: () => context.go(AppRoutes.applicationStaffOperations),
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Operational Queue'),
        ),
      ],
      bodyBuilder: (context, state) {
        final theme = Theme.of(context);
        final summary = state.summary;
        final profile = summary.profile;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Staff Profile & Delegated Permissions
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.staffName} • ${profile.roleTitle}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scope: ${profile.organizationScopeId} • ${profile.staffEmail}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: profile.permissions
                        .map((p) => Chip(label: Text(p.label)))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.security_outlined,
                        size: 18,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Governance Boundary: Application Staff can review, request information, triage support, and recommend to Application Admin. Final seller/product approvals, commission policies, staff permissions, and payouts remain Application Admin-only.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Permission-Gated Operational KPIs
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (profile.hasPermission(
                  ApplicationStaffPermission.reviewSellers,
                ))
                  _StaffMetricCard(
                    label: 'Pending Seller Reviews',
                    value: '${summary.pendingSellerReviews}',
                  ),
                if (profile.hasPermission(
                  ApplicationStaffPermission.reviewProducts,
                ))
                  _StaffMetricCard(
                    label: 'Pending Product Reviews',
                    value: '${summary.pendingProductReviews}',
                  ),
                if (profile.hasPermission(
                  ApplicationStaffPermission.handleSupportTickets,
                )) ...[
                  _StaffMetricCard(
                    label: 'Open Support Tickets',
                    value: '${summary.openSupportTickets}',
                  ),
                  _StaffMetricCard(
                    label: 'Compliance Alerts',
                    value: '${summary.complianceAlerts}',
                  ),
                ],
                _StaffMetricCard(
                  label: 'Recommended to Admin',
                  value: '${summary.recommendedCount}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // 3. Recent Queue Items
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Operational Queue',
                  style: theme.textTheme.titleLarge,
                ),
                TextButton.icon(
                  onPressed: () =>
                      context.go(AppRoutes.applicationStaffOperations),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Open Queue'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (summary.recentQueueItems.isEmpty)
              const EmptyStateView(
                title: 'No Queue Items Assigned',
                message:
                    'No operational items are currently visible under your delegated permissions.',
              )
            else
              AppCard(
                child: Column(
                  children: summary.recentQueueItems.map((item) {
                    final df = DateFormat('dd MMM yyyy, HH:mm');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${item.category.label} • Org: ${item.organizationName} (${item.organizationId}) • ${df.format(item.submittedAt)}',
                      ),
                      trailing: Chip(label: Text(item.status.label)),
                      onTap: () =>
                          context.go(AppRoutes.applicationStaffOperations),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StaffMetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _StaffMetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
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
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
