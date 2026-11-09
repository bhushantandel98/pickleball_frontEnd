import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_state.dart';
import 'package:pickleball_platform/features/profile/presentation/widgets/profile_avatar_view.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Responsive profile screen displaying verified personal account details.
///
/// Follows Clean Architecture and FSD §3.3.
class ProfilePage extends StatelessWidget {
  final ProfileCubit? cubit;
  final String? userId;
  final FutureOr<dynamic> Function()? onEditProfile;
  final VoidCallback? onAccountSettings;
  final VoidCallback? onBack;

  const ProfilePage({
    super.key,
    this.cubit,
    this.userId,
    this.onEditProfile,
    this.onAccountSettings,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<ProfileCubit>.value(
        value: cubit!,
        child: _ProfileView(
          userId: userId,
          onEditProfile: onEditProfile,
          onAccountSettings: onAccountSettings,
          onBack: onBack,
        ),
      );
    }

    try {
      final existing = context.read<ProfileCubit>();
      return BlocProvider<ProfileCubit>.value(
        value: existing,
        child: _ProfileView(
          userId: userId,
          onEditProfile: onEditProfile,
          onAccountSettings: onAccountSettings,
          onBack: onBack,
        ),
      );
    } catch (_) {
      return BlocProvider<ProfileCubit>(
        create: (_) => sl<ProfileCubit>(),
        child: _ProfileView(
          userId: userId,
          onEditProfile: onEditProfile,
          onAccountSettings: onAccountSettings,
          onBack: onBack,
        ),
      );
    }
  }
}

class _ProfileView extends StatefulWidget {
  final String? userId;
  final FutureOr<dynamic> Function()? onEditProfile;
  final VoidCallback? onAccountSettings;
  final VoidCallback? onBack;

  const _ProfileView({
    this.userId,
    this.onEditProfile,
    this.onAccountSettings,
    this.onBack,
  });

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  void _loadProfile() {
    String effectiveId = widget.userId ?? '';
    if (effectiveId.isEmpty) {
      try {
        final session = context.read<SessionCubit>().state;
        if (session.userId != null && session.userId!.isNotEmpty) {
          effectiveId = session.userId!;
        }
      } catch (_) {}
    }
    context.read<ProfileCubit>().loadProfile(userId: effectiveId);
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.root);
    }
  }

  Future<void> _handleEditProfile(UserProfile profile) async {
    if (widget.onEditProfile != null) {
      final result = await widget.onEditProfile!();
      if (result is UserProfile && mounted) {
        context.read<ProfileCubit>().applyUpdatedProfile(result);
      }
      return;
    }
    final updatedProfile =
        await context.push<UserProfile>(AppRoutes.editProfile, extra: profile);
    if (updatedProfile != null && mounted) {
      context.read<ProfileCubit>().applyUpdatedProfile(updatedProfile);
    }
  }

  void _handleAccountSettings() {
    if (widget.onAccountSettings != null) {
      widget.onAccountSettings!();
      return;
    }
    context.push(AppRoutes.accountSettings);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'User Profile',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _handleBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Account Settings',
            onPressed: _handleAccountSettings,
          ),
        ],
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.successMessage!),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
            context.read<ProfileCubit>().clearFeedbackMessage();
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading || state is ProfileInitial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ProfileFailure && state.fallbackProfile == null) {
            return Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: theme.colorScheme.error),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Failed to load profile',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      state.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.primary(
                      label: 'Try Again',
                      onPressed: _loadProfile,
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = state is ProfileLoaded
              ? state.profile
              : (state as ProfileFailure).fallbackProfile!;

          return _buildProfileContent(context, profile);
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, UserProfile profile) {
    final theme = Theme.of(context);
    final memberSinceStr = DateFormat('MMMM yyyy').format(profile.createdAt);
    final hasEmail = profile.email.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.maxFormWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar & Name Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  children: [
                    ProfileAvatarView(
                      name: profile.name,
                      avatarUrl: profile.avatarUrl,
                      radius: 48,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      profile.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      profile.phone,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      alignment: WrapAlignment.center,
                      children: [
                        if (profile.isSuspended)
                          const AppChip.error(label: 'Account Suspended')
                        else
                          const AppChip.success(label: 'Active Account'),
                        const AppChip.info(label: 'Verified Mobile'),
                        if (profile.rating != null)
                          AppChip.neutral(
                            label: 'Rating: ${profile.rating!.toStringAsFixed(1)}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Contact & Personal Information Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      context,
                      icon: Icons.person_outline,
                      label: 'Full Name',
                      value: profile.name,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildInfoRow(
                      context,
                      icon: Icons.phone_android_outlined,
                      label: 'Mobile Number',
                      value: profile.phone,
                      badge: 'Primary ID',
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildInfoRow(
                      context,
                      icon: Icons.email_outlined,
                      label: 'Email Address',
                      value: hasEmail ? profile.email : 'Not provided',
                      isPlaceholder: !hasEmail,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Account Details Card
              AppCard(
                padding: AppSpacing.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _buildInfoRow(
                      context,
                      icon: Icons.badge_outlined,
                      label: 'User ID',
                      value: profile.id,
                    ),
                    const Divider(height: AppSpacing.lg),
                    _buildInfoRow(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: 'Member Since',
                      value: memberSinceStr,
                    ),
                    const Divider(height: AppSpacing.lg),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Authorized Platform Roles',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: profile.availableRoles
                                    .map((role) => AppChip.neutral(
                                          label: role.displayName,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action Buttons
              AppButton.primary(
                label: 'Edit Profile',
                onPressed: () => _handleEditProfile(profile),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.secondary(
                label: 'Account Settings',
                onPressed: _handleAccountSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? badge,
    bool isPlaceholder = false,
  }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xxxs),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isPlaceholder
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurface,
                  fontStyle:
                      isPlaceholder ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
        if (badge != null)
          AppChip.info(label: badge),
      ],
    );
  }
}
