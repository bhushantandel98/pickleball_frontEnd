import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/features/application_admin/presentation/bloc/application_admin_cubit.dart';
import 'package:pickleball_platform/features/application_admin/presentation/widgets/application_admin_scaffold.dart';

/// Feature 7.2 — Immutable Application Admin Governance Audit Logs screen.
class ApplicationAdminAuditLogsPage extends StatefulWidget {
  final ApplicationAdminCubit? cubit;
  final String? adminUserId;

  const ApplicationAdminAuditLogsPage({
    super.key,
    this.cubit,
    this.adminUserId,
  });

  @override
  State<ApplicationAdminAuditLogsPage> createState() =>
      _ApplicationAdminAuditLogsPageState();
}

class _ApplicationAdminAuditLogsPageState
    extends State<ApplicationAdminAuditLogsPage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ApplicationAdminScaffold(
      cubit: widget.cubit,
      adminUserId: widget.adminUserId,
      title: 'Governance Audit Logs',
      subtitle:
          'Immutable read-only log of Application Admin approvals, staff scope edits & policy updates.',
      actionsBuilder: (context, _) => [
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.applicationAdminDashboard),
          icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Dashboard'),
        ),
      ],
      bodyBuilder: (context, state) {
        final theme = Theme.of(context);
        final cubit = context.read<ApplicationAdminCubit>();
        final df = DateFormat('dd MMM yyyy, HH:mm');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by action, organization, target ID, or detail...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: state.auditQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            cubit.searchAuditLogs('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: cubit.searchAuditLogs,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (state.auditLogs.isEmpty)
              const EmptyStateView(
                title: 'No Matching Audit Logs',
                message: 'No governance audit entries match your search query.',
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.auditLogs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final entry = state.auditLogs[index];
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(label: Text(entry.action)),
                            Text(
                              '${entry.actorRole} (${entry.actorUserId})',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              df.format(entry.timestamp),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Target: ${entry.targetType}/${entry.targetId} • Org: ${entry.organizationId}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(entry.detail, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
