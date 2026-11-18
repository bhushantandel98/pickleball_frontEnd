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

  void _handleChangePassword() {
    if (widget.onChangePassword != null) {
      widget.onChangePassword!();
      return;
    }
    _showChangePasswordDialog();
  }

  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final currentCtrl = TextEditingController();
    final nextCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your current password.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: nextCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 8)
                    ? 'Password must be at least 8 characters.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v != nextCtrl.text ? 'Passwords do not match.' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            label: 'Update Password',
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(dialogContext).pop(true);
              }
            },
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated locally for this session (mock mode).',
          ),
        ),
      );
    }

    currentCtrl.dispose();
    nextCtrl.dispose();
    confirmCtrl.dispose();
  }

  void _handleNotificationPreferences() {
    if (widget.onNotifications != null) {
      widget.onNotifications!();
      return;
    }
    try {
      context.push(AppRoutes.notificationPreferences);
    } catch (_) {
      // Fallback when rendered outside GoRouter in standalone widget tests
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open Notification Preferences from the main app shell.'),
        ),
      );
    }
  }

  void _handlePrivacySecurity() {
    if (widget.onPrivacy != null) {
      widget.onPrivacy!();
      return;
    }
    _showPrivacySecurityDialog();
  }

  Future<void> _showPrivacySecurityDialog() async {
    var publicProfile = true;
    var showMatchHistory = true;
    String activeEmail = 'Authenticated user';
    try {
      final session = context.read<SessionCubit>().state;
      if (session.email != null && session.email!.isNotEmpty) {
        activeEmail = session.email!;
      }
    } catch (_) {}

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Privacy & Security'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active Session: $activeEmail'),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Public Player Profile'),
                value: publicProfile,
                onChanged: (v) => setDialogState(() => publicProfile = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Match & Ranking History'),
                value: showMatchHistory,
                onChanged: (v) => setDialogState(() => showMatchHistory = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            AppButton.primary(
              label: 'Save Preferences',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Privacy preferences saved for this session.'),
        ),
      );
    }
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
