import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/features/role_selection/data/repositories/mock_role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/domain/entities/role_context.dart';
import 'package:pickleball_platform/features/role_selection/domain/repositories/role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/presentation/cubit/role_selection_cubit.dart';

/// Screen allowing authenticated multi-role users to select or switch their active platform role.
///
/// Features:
/// - Single-role users auto-redirect directly to their dashboard.
/// - Multi-role users see active role profiles, organization badges, and descriptions.
/// - "Remember my choice" stores preference in [RolePreferenceStorage].
/// - If a preferred role is revoked or invalid, cleanly presents available roles.
/// - Zero-role accounts display a clean empty state with options to register or sign out.
/// - Centralized dashboard routing delegates to [RoleDashboardRouter].
class RoleSelectionPage extends StatelessWidget {
  final String? userId;
  final bool bypassAutoRedirect;
  final RoleSelectionCubit? cubit;
  final void Function(UserRole role)? onRoleSelected;
  final void Function(RoleProfile assignment)? onAssignmentSelected;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onSignOut;

  const RoleSelectionPage({
    super.key,
    this.userId,
    this.bypassAutoRedirect = false,
    this.cubit,
    this.onRoleSelected,
    this.onAssignmentSelected,
    this.onCreateAccount,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<RoleSelectionCubit>.value(
        value: cubit!,
        child: _RoleSelectionView(
          userId: userId,
          bypassAutoRedirect: bypassAutoRedirect,
          onRoleSelected: onRoleSelected,
          onAssignmentSelected: onAssignmentSelected,
          onCreateAccount: onCreateAccount,
          onSignOut: onSignOut,
        ),
      );
    }

    return BlocProvider<RoleSelectionCubit>(
      create: (_) {
        if (sl.isRegistered<RoleSelectionCubit>()) {
          return sl<RoleSelectionCubit>();
        }
        final repo = sl.isRegistered<RoleContextRepository>()
            ? sl<RoleContextRepository>()
            : MockRoleContextRepository();
        final storage = sl.isRegistered<RolePreferenceStorage>()
            ? sl<RolePreferenceStorage>()
            : null;
        return RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      },
      child: _RoleSelectionView(
        userId: userId,
        bypassAutoRedirect: bypassAutoRedirect,
        onRoleSelected: onRoleSelected,
        onAssignmentSelected: onAssignmentSelected,
        onCreateAccount: onCreateAccount,
        onSignOut: onSignOut,
      ),
    );
  }
}

class _RoleSelectionView extends StatefulWidget {
  final String? userId;
  final bool bypassAutoRedirect;
  final void Function(UserRole role)? onRoleSelected;
  final void Function(RoleProfile assignment)? onAssignmentSelected;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onSignOut;

  const _RoleSelectionView({
    this.userId,
    this.bypassAutoRedirect = false,
    this.onRoleSelected,
    this.onAssignmentSelected,
    this.onCreateAccount,
    this.onSignOut,
  });

  @override
  State<_RoleSelectionView> createState() => _RoleSelectionViewState();
}

class _RoleSelectionViewState extends State<_RoleSelectionView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    String effectiveUserId = widget.userId ?? 'user_multi_001';
    try {
      final session = context.read<SessionCubit>().state;
      if (session.userId != null && session.userId!.isNotEmpty) {
        effectiveUserId = session.userId!;
      }
    } catch (_) {
      // SessionCubit might not be in test context
    }

    context.read<RoleSelectionCubit>().loadRoleContext(
          userId: effectiveUserId,
          bypassAutoRedirect: widget.bypassAutoRedirect,
        );
  }

  Future<void> _handleRedirect(RoleSelectionRedirect state) async {
    try {
      final sessionCubit = context.read<SessionCubit>();
      final assignment = state.selectedAssignment;

      if (sessionCubit.state.isAuthenticated) {
        await sessionCubit.setActiveRoleProfile(assignment);
      } else {
        await sessionCubit.signIn(
          userId: state.roleContext.userId,
          email: state.roleContext.email ?? '',
          displayName: state.roleContext.displayName,
          roles: state.roleContext.activeRoles,
          activeRole: assignment.role,
          roleAssignmentId: assignment.roleAssignmentId,
          organizationId: assignment.organizationId,
          organizationName: assignment.organizationName,
          tournamentId: assignment.tournamentId,
          tournamentName: assignment.tournamentName,
        );
      }
    } catch (_) {
      // SessionCubit optional in standalone tests
    }

    if (!mounted) return;

    if (widget.onAssignmentSelected != null) {
      widget.onAssignmentSelected!(state.selectedAssignment);
    }
    if (widget.onRoleSelected != null) {
      widget.onRoleSelected!(state.targetRole);
    } else if (widget.onAssignmentSelected == null) {
      try {
        context.go(state.destinationPath);
      } catch (_) {
        // Fallback when GoRouter is not provided in test environment
      }
    }
  }

  void _handleSignOut() {
    try {
      context.read<SessionCubit>().signOut();
    } catch (_) {}

    if (widget.onSignOut != null) {
      widget.onSignOut!();
    } else {
      context.go(AppRoutes.login);
    }
  }

  void _handleCreateAccount() {
    if (widget.onCreateAccount != null) {
      widget.onCreateAccount!();
    } else {
      context.go(AppRoutes.register);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoleSelectionCubit, RoleSelectionState>(
      listener: (context, state) {
        if (state is RoleSelectionRedirect) {
          _handleRedirect(state);
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);

        if (state is RoleSelectionLoading || state is RoleSelectionInitial) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(key: Key('role_selection_loading')),
                  SizedBox(height: AppSpacing.md),
                  Text('Loading role profiles...'),
                ],
              ),
            ),
          );
        }

        if (state is RoleSelectionFailure) {
          return Scaffold(
            appBar: const CommonAppBar(title: 'Role Selection'),
            body: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: AppCard(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: AppSpacing.iconXl,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Unable to Load Roles',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppButton.primary(
                          label: 'Retry',
                          onPressed: _loadData,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (state is RoleSelectionEmpty) {
          return Scaffold(
            appBar: const CommonAppBar(title: 'Role Selection'),
            body: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: AppCard(
                    padding: AppSpacing.cardPadding,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Icon(
                            Icons.badge_outlined,
                            size: AppSpacing.iconXl,
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No Active Roles Assigned',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'User: ${state.displayName} (${state.phone})',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton.primary(
                          label: 'Create Player Account',
                          onPressed: _handleCreateAccount,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppButton.outline(
                          label: 'Sign Out',
                          onPressed: _handleSignOut,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (state is RoleSelectionLoaded) {
          final cubit = context.read<RoleSelectionCubit>();
          final roleContext = state.roleContext;

          return Scaffold(
            appBar: const CommonAppBar(
              title: 'Select Active Role',
              subtitle: 'Choose your operating context',
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // User Identity Header Card
                      _buildIdentityHeader(context, roleContext),
                      const SizedBox(height: AppSpacing.lg),

                      // Section Title
                      Text(
                        'Available Roles',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Select the profile you wish to operate under during this session. '
                        'You can switch roles at any time from your dashboard.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Role Profile Cards
                      ...roleContext.activeProfiles.map((profile) {
                        final isSelected =
                            state.selectedAssignmentId == profile.roleAssignmentId;
                        return _buildRoleCard(
                          context,
                          profile: profile,
                          isSelected: isSelected,
                          onSelectOnly: () {
                            cubit.selectAssignment(profile.roleAssignmentId);
                          },
                          onTap: () async {
                            cubit.selectAssignment(profile.roleAssignmentId);
                            await cubit.confirmRoleSelection();
                          },
                        );
                      }),

                      const SizedBox(height: AppSpacing.sm),

                      // Remember Choice Switch
                      _buildRememberChoiceOption(context, state, cubit),

                      // Selected Operating Context Display
                      if (state.selectedAssignment != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        _buildSelectedContextSummary(
                          context,
                          selectedProfile: state.selectedAssignment!,
                        ),
                      ],

                      // Inline Error (if any)
                      if (state.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: AppSpacing.borderRadiusSm,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.onErrorContainer,
                                size: AppSpacing.iconSm,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  state.errorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      // Primary CTA
                      AppButton.primary(
                        label: 'Continue to Dashboard',
                        isLoading: state.isSubmitting,
                        onPressed: state.isSubmitting
                            ? null
                            : () => cubit.confirmRoleSelection(),
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Sign Out / Switch Account
                      AppButton.text(
                        label: 'Sign Out / Switch Account',
                        onPressed: state.isSubmitting ? null : _handleSignOut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildIdentityHeader(BuildContext context, RoleContext roleContext) {
    final theme = Theme.of(context);

    return AppCard(
      padding: AppSpacing.cardPadding,
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          CircleAvatar(
            radius: AppSpacing.radiusXl,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              color: theme.colorScheme.onPrimaryContainer,
              size: AppSpacing.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleContext.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxs),
                Text(
                  roleContext.phone,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (roleContext.email != null &&
                    roleContext.email!.isNotEmpty) ...[
                  Text(
                    roleContext.email!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          AppChip.info(
            label: '${roleContext.activeRoles.length} Roles',
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required RoleProfile profile,
    required bool isSelected,
    required VoidCallback onTap,
    VoidCallback? onSelectOnly,
  }) {
    final theme = Theme.of(context);
    final role = profile.role;

    final selectedBorder = BorderSide(
      color: theme.colorScheme.primary,
      width: 2,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: onTap,
        border: isSelected ? selectedBorder : null,
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15)
            : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(
                role.icon,
                size: AppSpacing.iconMd,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xxs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        role.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (profile.organizationName != null)
                        AppChip.neutral(
                          label: profile.organizationName!,
                        ),
                      if (profile.tournamentName != null &&
                          profile.tournamentName != profile.organizationName)
                        AppChip.info(
                          label: profile.tournamentName!,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    profile.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
                size: AppSpacing.iconMd,
              ),
              tooltip: isSelected ? 'Selected' : 'Select ${role.displayName}',
              onPressed: onSelectOnly ?? onTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContextSummary(
    BuildContext context, {
    required RoleProfile selectedProfile,
  }) {
    final theme = Theme.of(context);
    final role = selectedProfile.role;
    final contextName =
        selectedProfile.tournamentName ?? selectedProfile.organizationName;

    final bannerText = contextName != null
        ? 'Active Context: ${role.displayName} • $contextName'
        : 'Active Context: ${role.displayName}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified,
            size: AppSpacing.iconSm,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              bannerText,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRememberChoiceOption(
    BuildContext context,
    RoleSelectionLoaded state,
    RoleSelectionCubit cubit,
  ) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: Text(
          'Remember my choice',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Skip role selection on your next sign-in and open this dashboard automatically.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        value: state.rememberChoice,
        onChanged: cubit.toggleRememberChoice,
      ),
    );
  }
}
