import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/session_context.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';

/// Reusable view for routing verification during Phase 0 foundation and Phase 1 transitions.
///
/// Demonstrates nested navigation, shell integration, and path parameters,
/// displaying active role badge, organization context, and quick role switching.
class RoutePlaceholderView extends StatelessWidget {
  final String title;
  final String path;
  final UserRole? role;
  final Map<String, String>? params;

  const RoutePlaceholderView({
    super.key,
    required this.title,
    required this.path,
    this.role,
    this.params,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    SessionContext? session;
    SessionCubit? sessionCubit;
    try {
      sessionCubit = context.read<SessionCubit>();
      session = sessionCubit.state;
    } catch (_) {
      // SessionCubit may not be present in isolated component tests
    }

    final effectiveRole = role ?? session?.activeRole;
    final orgId = session?.activeOrganizationId;
    final hasMultipleRoles = (session?.availableRoles.length ?? 0) > 1;
    final isAuthenticated = session?.isAuthenticated ?? false;

    bool canPop = false;
    try {
      canPop = context.canPop();
    } catch (_) {
      try {
        canPop = Navigator.of(context).canPop();
      } catch (_) {}
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: AppCard(
              padding: AppSpacing.cardPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      if (effectiveRole != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        AppChip.success(label: effectiveRole.displayName),
                      ],
                    ],
                  ),
                  if (orgId != null && orgId.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppChip.info(label: 'Org: $orgId'),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Route Path: $path',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (params != null && params!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Parameters: ${params.toString()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'This destination is registered in the routing table. '
                    'Feature implementation is scoped for subsequent development phases.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (canPop) ...[
                        AppButton.outline(
                          label: 'Back',
                          icon: const Icon(Icons.arrow_back,
                              size: AppSpacing.iconSm),
                          onPressed: () {
                            try {
                              context.pop();
                            } catch (_) {
                              Navigator.of(context).maybePop();
                            }
                          },
                        ),
                      ],
                      if (hasMultipleRoles) ...[
                        AppButton.outline(
                          label: 'Switch Role',
                          icon: const Icon(Icons.swap_horiz,
                              size: AppSpacing.iconSm),
                          onPressed: () => context.go(AppRoutes.roleSelection),
                        ),
                      ],
                      if (isAuthenticated) ...[
                        AppButton.text(
                          label: 'Sign Out Session',
                          icon: const Icon(Icons.logout,
                              size: AppSpacing.iconSm),
                          onPressed: () {
                            sessionCubit?.signOut();
                            context.go(AppRoutes.login);
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
