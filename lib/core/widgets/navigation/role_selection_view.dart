import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/session_context.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';

/// Screen allowing multi-role users to select or switch their active platform role.
///
/// Conforms to FSD §3.1 and supports "Remember preferred role" preferences.
class RoleSelectionView extends StatelessWidget {
  const RoleSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, SessionContext>(
      builder: (context, session) {
        final roles = session.availableRoles;

        return Scaffold(
          appBar: const CommonAppBar(
            title: 'Select Active Role',
            subtitle: 'Choose your operating context',
          ),
          body: roles.isEmpty
              ? const EmptyStateView(
                  title: 'No Roles Assigned',
                  message:
                      'Your account currently has no active platform roles assigned. '
                      'Please contact platform support or your organization administrator.',
                )
              : Center(
                  child: SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 550),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Operating Role Context',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Select the role you wish to operate in. You can switch roles '
                            'at any time from the navigation menu.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ...roles.map((role) {
                            final isActive = session.activeRole == role;

                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSpacing.sm),
                              child: AppCard(
                                onTap: () async {
                                  final cubit = context.read<SessionCubit>();
                                  await cubit.switchRole(role);
                                  if (context.mounted) {
                                    context.go(role.defaultDashboardPath);
                                  }
                                },
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius:
                                            AppSpacing.borderRadiusSm,
                                      ),
                                      child: Icon(
                                        role.icon,
                                        size: AppSpacing.iconMd,
                                        color: isActive
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            role.displayName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          Text(
                                            role.routePrefix,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isActive)
                                      const AppChip.success(label: 'Active')
                                    else
                                      const Icon(
                                        Icons.chevron_right,
                                        color: Colors.grey,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: AppSpacing.md),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Remember preferred role'),
                            subtitle: const Text(
                              'Automatically activate this role on subsequent sign-ins',
                            ),
                            value: session.rememberPreferredRole,
                            onChanged: (value) {
                              context
                                  .read<SessionCubit>()
                                  .setRememberPreferredRole(value);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
