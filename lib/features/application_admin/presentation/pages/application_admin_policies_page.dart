import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/core/design_system/app_colors.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/application_admin/domain/entities/application_admin_entities.dart';
import 'package:pickleball_platform/features/application_admin/presentation/bloc/application_admin_cubit.dart';
import 'package:pickleball_platform/features/application_admin/presentation/widgets/application_admin_scaffold.dart';

/// Feature 7.2 — Platform Commissions & Policies screen.
class ApplicationAdminPoliciesPage extends StatelessWidget {
  final ApplicationAdminCubit? cubit;
  final String? adminUserId;

  const ApplicationAdminPoliciesPage({
    super.key,
    this.cubit,
    this.adminUserId,
  });

  @override
  Widget build(BuildContext context) {
    return ApplicationAdminScaffold(
      cubit: cubit,
      adminUserId: adminUserId,
      title: 'Platform Commissions & Policies',
      subtitle:
          'Configure platform commission rate and return-window policy bounds for future orders.',
      actionsBuilder: (context, _) => [
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.applicationAdminDashboard),
          icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Dashboard'),
        ),
      ],
      bodyBuilder: (context, state) {
        return _PolicyEditorCard(
          policy: state.summary.policy,
          isMutating: state.isMutating,
        );
      },
    );
  }
}

class _PolicyEditorCard extends StatefulWidget {
  final AdminCommissionPolicy policy;
  final bool isMutating;

  const _PolicyEditorCard({
    required this.policy,
    required this.isMutating,
  });

  @override
  State<_PolicyEditorCard> createState() => _PolicyEditorCardState();
}

class _PolicyEditorCardState extends State<_PolicyEditorCard> {
  late final TextEditingController _rateCtrl;
  late final TextEditingController _minDaysCtrl;
  late final TextEditingController _maxDaysCtrl;

  @override
  void initState() {
    super.initState();
    _rateCtrl = TextEditingController(
      text: widget.policy.defaultCommissionRatePercent?.toString() ?? '',
    );
    _minDaysCtrl = TextEditingController(
      text: widget.policy.minReturnWindowDays.toString(),
    );
    _maxDaysCtrl = TextEditingController(
      text: widget.policy.maxReturnWindowDays.toString(),
    );
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _minDaysCtrl.dispose();
    _maxDaysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final df = DateFormat('dd MMM yyyy, HH:mm');
    final cubit = context.read<ApplicationAdminCubit>();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Active Policy: ${widget.policy.policyId} (Version ${widget.policy.version})',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Last updated ${df.format(widget.policy.updatedAt)} by ${widget.policy.updatedByAdminId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.info),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Policy updates apply ONLY to future orders. Historical orders retain their order-placement commission and return-window snapshots.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _rateCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Platform Commission Rate (%) — leave empty if unconfigured',
              hintText: '0 to 50%',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _minDaysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Min Return Window (Days)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _maxDaysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Max Return Window (Days)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Pickleball-Only Marketplace Policy Enforced'),
            subtitle: const Text('Locked per platform governance.'),
            value: widget.policy.pickleballOnlyEnforced,
            onChanged: null,
          ),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: widget.isMutating
                ? null
                : () {
                    final rawRate = _rateCtrl.text.trim();
                    final parsedRate =
                        rawRate.isEmpty ? null : double.tryParse(rawRate);
                    if (rawRate.isNotEmpty && parsedRate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a valid numeric commission rate.'),
                        ),
                      );
                      return;
                    }
                    final minDays =
                        int.tryParse(_minDaysCtrl.text.trim()) ?? -1;
                    final maxDays =
                        int.tryParse(_maxDaysCtrl.text.trim()) ?? -1;
                    cubit.updateCommissionPolicy(
                      defaultCommissionRatePercent: parsedRate,
                      minReturnWindowDays: minDays,
                      maxReturnWindowDays: maxDays,
                    );
                  },
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Governance Policy'),
          ),
        ],
      ),
    );
  }
}
