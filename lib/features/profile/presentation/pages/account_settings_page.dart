import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_state.dart';
import 'package:pickleball_platform/features/profile/presentation/widgets/profile_avatar_view.dart';

/// Screen managing personal account settings, preferences, and session logout.
class AccountSettingsPage extends StatelessWidget {
  final ProfileCubit? cubit;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onChangePassword;
  final VoidCallback? onNotifications;
  final VoidCallback? onPrivacy;
  final VoidCallback? onLoggedOut;

  const AccountSettingsPage({
    super.key,
    this.cubit,
    this.onProfilePressed,
    this.onChangePassword,
    this.onNotifications,
    this.onPrivacy,
    this.onLoggedOut,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<ProfileCubit>.value(
        value: cubit!,
        child: _AccountSettingsView(
          onProfilePressed: onProfilePressed,
          onChangePassword: onChangePassword,
          onNotifications: onNotifications,
          onPrivacy: onPrivacy,
          onLoggedOut: onLoggedOut,
        ),
      );
    }

    try {
      final existing = context.read<ProfileCubit>();
      return BlocProvider<ProfileCubit>.value(
        value: existing,
        child: _AccountSettingsView(
          onProfilePressed: onProfilePressed,
          onChangePassword: onChangePassword,
          onNotifications: onNotifications,
          onPrivacy: onPrivacy,
          onLoggedOut: onLoggedOut,
        ),
      );
    } catch (_) {
      return BlocProvider<ProfileCubit>(
        create: (_) => sl<ProfileCubit>(),
        child: _AccountSettingsView(
          onProfilePressed: onProfilePressed,
          onChangePassword: onChangePassword,
          onNotifications: onNotifications,
          onPrivacy: onPrivacy,
          onLoggedOut: onLoggedOut,
        ),
      );
    }
  }
}

class _AccountSettingsView extends StatefulWidget {
  final VoidCallback? onProfilePressed;
  final VoidCallback? onChangePassword;
  final VoidCallback? onNotifications;
  final VoidCallback? onPrivacy;
  final VoidCallback? onLoggedOut;

  const _AccountSettingsView({
    this.onProfilePressed,
    this.onChangePassword,
    this.onNotifications,
    this.onPrivacy,
    this.onLoggedOut,
  });

  @override
  State<_AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<_AccountSettingsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<ProfileCubit>().state;
      if (state is ProfileInitial) {
        String effectiveId = '';
        try {
          final session = context.read<SessionCubit>().state;
          if (session.userId != null && session.userId!.isNotEmpty) {
            effectiveId = session.userId!;
          }
        } catch (_) {}
        context.read<ProfileCubit>().loadProfile(userId: effectiveId);
      }
    });
  }

  void _navigateToProfile() {
    if (widget.onProfilePressed != null) {
      widget.onProfilePressed!();
      return;
    }
    context.push(AppRoutes.profile);
  }

  void _showPlaceholderDialog({
    required String title,
    required String message,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton.primary(
            label: 'Understood',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  void _handleChangePassword() {
    if (widget.onChangePassword != null) {
      widget.onChangePassword!();
      return;
    }
    _showPlaceholderDialog(
      title: 'Change Password',
      message:
          'Password management and credential update flows will be integrated in Phase 1.3.',
    );
  }

  void _handleNotificationPreferences() {
    if (widget.onNotifications != null) {
      widget.onNotifications!();
      return;
    }
    _showPlaceholderDialog(
      title: 'Notification Preferences',
      message:
          'Push notifications, match alerts, and schedule reminders will be configurable in Phase 1.4.',
    );
  }

  void _handlePrivacySecurity() {
    if (widget.onPrivacy != null) {
      widget.onPrivacy!();
      return;
    }
    _showPlaceholderDialog(
      title: 'Privacy & Security',
      message:
          'Account data controls, privacy preferences, and session audit history will be available in Phase 1.3.',
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Log Out',
      message:
          'Are you sure you want to log out of your Pickleball account?',
      confirmLabel: 'Log Out',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      try {
        context.read<SessionCubit>().signOut();
      } catch (_) {
        // SessionCubit optional in standalone test harness
      }

      if (widget.onLoggedOut != null) {
        widget.onLoggedOut!();
        return;
      }

      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Account Settings',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.profile);
            }
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSpacing.maxFormWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Snapshot Tile
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    final profile = state is ProfileLoaded
                        ? state.profile
                        : null;

                    return AppCard(
                      padding: AppSpacing.cardPadding,
                      child: InkWell(
                        onTap: _navigateToProfile,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        child: Row(
                          children: [
                            ProfileAvatarView(
                              name: profile?.name ?? 'User',
                              avatarUrl: profile?.avatarUrl,
                              radius: 28,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile?.name ?? 'Account Profile',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxxs),
                                  Text(
                                    profile?.phone ?? 'View personal details',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.md),

                // Security & Credentials
                AppCard(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security & Credentials',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSettingsTile(
                        context,
                        icon: Icons.lock_outline,
                        title: 'Change Password',
                        subtitle: 'Update your account password',
                        onTap: _handleChangePassword,
                      ),
                      const Divider(height: AppSpacing.md),
                      _buildSettingsTile(
                        context,
                        icon: Icons.shield_outlined,
                        title: 'Privacy & Security',
                        subtitle: 'Privacy policies and session security',
                        onTap: _handlePrivacySecurity,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Preferences
                AppCard(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferences',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _buildSettingsTile(
                        context,
                        icon: Icons.notifications_outlined,
                        title: 'Notification Preferences',
                        subtitle: 'Match, tournament, and booking alerts',
                        onTap: _handleNotificationPreferences,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Logout Action
                AppButton.destructive(
                  label: 'Log Out',
                  onPressed: _handleLogout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
