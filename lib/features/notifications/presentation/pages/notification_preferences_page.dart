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
import 'package:pickleball_platform/features/notifications/domain/entities/notification_preferences.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notification_preferences_cubit.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notification_preferences_state.dart';
import 'package:pickleball_platform/features/notifications/presentation/widgets/preference_switch_tile.dart';

/// Responsive Notification Preferences screen organized into Push, Email,
/// and General sound/display settings.
class NotificationPreferencesPage extends StatelessWidget {
  final NotificationPreferencesCubit? cubit;
  final String? userId;
  final VoidCallback? onBack;

  const NotificationPreferencesPage({
    super.key,
    this.cubit,
    this.userId,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<NotificationPreferencesCubit>.value(
        value: cubit!,
        child: _NotificationPreferencesView(
          userId: userId,
          onBack: onBack,
        ),
      );
    }

    try {
      final existing = context.read<NotificationPreferencesCubit>();
      return BlocProvider<NotificationPreferencesCubit>.value(
        value: existing,
        child: _NotificationPreferencesView(
          userId: userId,
          onBack: onBack,
        ),
      );
    } catch (_) {
      return BlocProvider<NotificationPreferencesCubit>(
        create: (_) => sl<NotificationPreferencesCubit>(),
        child: _NotificationPreferencesView(
          userId: userId,
          onBack: onBack,
        ),
      );
    }
  }
}

class _NotificationPreferencesView extends StatefulWidget {
  final String? userId;
  final VoidCallback? onBack;

  const _NotificationPreferencesView({
    this.userId,
    this.onBack,
  });

  @override
  State<_NotificationPreferencesView> createState() =>
      _NotificationPreferencesViewState();
}

class _NotificationPreferencesViewState
    extends State<_NotificationPreferencesView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPreferences();
    });
  }

  void _loadPreferences() {
    String effectiveId = widget.userId ?? '';
    if (effectiveId.isEmpty) {
      try {
        final session = context.read<SessionCubit>().state;
        if (session.userId != null && session.userId!.isNotEmpty) {
          effectiveId = session.userId!;
        }
      } catch (_) {}
    }
    context
        .read<NotificationPreferencesCubit>()
        .loadPreferences(userId: effectiveId);
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.accountSettings);
    }
  }

  Future<void> _handleReset() async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Reset Notification Preferences?',
      message:
          'This will restore all push, email, and sound preferences to their recommended platform defaults.',
      confirmLabel: 'Reset to Defaults',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      context.read<NotificationPreferencesCubit>().resetToDefaults();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Notification Preferences',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _handleBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
            onPressed: _handleReset,
          ),
        ],
      ),
      body: BlocConsumer<NotificationPreferencesCubit,
          NotificationPreferencesState>(
        listener: (context, state) {
          if (state is NotificationPreferencesLoaded &&
              state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                backgroundColor: theme.colorScheme.primary,
                duration: const Duration(seconds: 2),
              ),
            );
            context
                .read<NotificationPreferencesCubit>()
                .clearFeedbackMessage();
          }
          if (state is NotificationPreferencesFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationPreferencesLoading ||
              state is NotificationPreferencesInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationPreferencesFailure &&
              state.fallbackPreferences == null) {
            return Center(
              child: Padding(
                padding: AppSpacing.screenPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Failed to load notification preferences',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: 'Retry',
                      onPressed: _loadPreferences,
                    ),
                  ],
                ),
              ),
            );
          }

          final NotificationPreferences preferences =
              (state is NotificationPreferencesLoaded)
                  ? state.preferences
                  : (state as NotificationPreferencesFailure)
                      .fallbackPreferences!;

          final cubit = context.read<NotificationPreferencesCubit>();

          return Center(
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppSpacing.maxFormWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Section A: Push Notifications
                    _buildSectionCard(
                      context: context,
                      icon: Icons.phone_android,
                      title: 'Push Notifications',
                      subtitle: 'Real-time alerts sent directly to this device',
                      masterValue: preferences.pushMasterEnabled,
                      onMasterChanged: (val) => cubit.togglePushMaster(val),
                      isChannelEnabled: preferences.pushMasterEnabled,
                      children: [
                        if (!preferences.pushMasterEnabled)
                          _buildMutedBanner(
                            context: context,
                            message:
                                'Push notifications are turned off. Sub-categories are paused without resetting your saved settings.',
                          ),
                        PreferenceSwitchTile(
                          icon: Icons.shield_outlined,
                          title: 'Account & Security Alerts',
                          subtitle:
                              'Immediate alerts for suspicious logins, password updates, and session changes',
                          value: preferences.push.accountSecurity,
                          isChannelEnabled: preferences.pushMasterEnabled,
                          onChanged: (val) => cubit.updatePushCategory(
                            key: 'accountSecurity',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.calendar_today_outlined,
                          title: 'Booking Updates',
                          subtitle:
                              'Court reservation confirmations, cancellations, slot changes, and check-in reminders',
                          value: preferences.push.bookingUpdates,
                          isChannelEnabled: preferences.pushMasterEnabled,
                          onChanged: (val) => cubit.updatePushCategory(
                            key: 'bookingUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.emoji_events_outlined,
                          title: 'Tournament Updates',
                          subtitle:
                              'Tournament registration updates, published draws, seeds, and schedule releases',
                          value: preferences.push.tournamentUpdates,
                          isChannelEnabled: preferences.pushMasterEnabled,
                          onChanged: (val) => cubit.updatePushCategory(
                            key: 'tournamentUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.sports_tennis_outlined,
                          title: 'Match & Scoring Updates',
                          subtitle:
                              'Real-time live score progress, referee call alerts, and finalized match outcomes',
                          value: preferences.push.matchScoringUpdates,
                          isChannelEnabled: preferences.pushMasterEnabled,
                          onChanged: (val) => cubit.updatePushCategory(
                            key: 'matchScoringUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.school_outlined,
                          title: 'Coaching & Academy Updates',
                          subtitle:
                              'Training session announcements, batch timings, and coach attendance logs',
                          value: preferences.push.coachingAcademyUpdates,
                          isChannelEnabled: preferences.pushMasterEnabled,
                          onChanged: (val) => cubit.updatePushCategory(
                            key: 'coachingAcademyUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Marketplace Order Updates',
                          subtitle:
                              'Order approvals, shipping dispatches, delivery confirmations, and returns',
                          value: preferences.push.marketplaceUpdates,
                          isChannelEnabled: preferences.pushMasterEnabled,
                          onChanged: (val) => cubit.updatePushCategory(
                            key: 'marketplaceUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.groups_outlined,
                          title: 'Community & Social Updates',
                          subtitle:
                              'Club notices, social game invitations, friend connections, and community posts',
                          value: preferences.push.communityUpdates,
                          isChannelEnabled: preferences.pushMasterEnabled,
                          onChanged: (val) => cubit.updatePushCategory(
                            key: 'communityUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.campaign_outlined,
                          title: 'Promotional Announcements',
                          subtitle:
                              'Special discounts, partner perks, tournament vouchers, and seasonal offers',
                          value: preferences.push.promotions,
                          isChannelEnabled: preferences.pushMasterEnabled,
                          onChanged: (val) => cubit.updatePushCategory(
                            key: 'promotions',
                            value: val,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section B: Email Notifications
                    _buildSectionCard(
                      context: context,
                      icon: Icons.email_outlined,
                      title: 'Email Notifications',
                      subtitle:
                          'Official summaries, receipts, and invoices sent to your email',
                      masterValue: preferences.emailMasterEnabled,
                      onMasterChanged: (val) => cubit.toggleEmailMaster(val),
                      isChannelEnabled: preferences.emailMasterEnabled,
                      children: [
                        if (!preferences.emailMasterEnabled)
                          _buildMutedBanner(
                            context: context,
                            message:
                                'Email notifications are turned off. Sub-categories are paused without resetting your saved settings.',
                          ),
                        PreferenceSwitchTile(
                          icon: Icons.shield_outlined,
                          title: 'Account & Security Alerts',
                          subtitle:
                              'Security alerts, password recovery links, and verified login notifications',
                          value: preferences.email.accountSecurity,
                          isChannelEnabled: preferences.emailMasterEnabled,
                          onChanged: (val) => cubit.updateEmailCategory(
                            key: 'accountSecurity',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.receipt_long_outlined,
                          title: 'Booking Updates',
                          subtitle:
                              'Court booking receipts, cancellation credit notes, and booking confirmation PDFs',
                          value: preferences.email.bookingUpdates,
                          isChannelEnabled: preferences.emailMasterEnabled,
                          onChanged: (val) => cubit.updateEmailCategory(
                            key: 'bookingUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.emoji_events_outlined,
                          title: 'Tournament Updates',
                          subtitle:
                              'Official registration confirmations, tournament rule packages, and payment invoices',
                          value: preferences.email.tournamentUpdates,
                          isChannelEnabled: preferences.emailMasterEnabled,
                          onChanged: (val) => cubit.updateEmailCategory(
                            key: 'tournamentUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.school_outlined,
                          title: 'Coaching & Academy Updates',
                          subtitle:
                              'Academy enrollment records, program schedules, and monthly fee receipts',
                          value: preferences.email.coachingAcademyUpdates,
                          isChannelEnabled: preferences.emailMasterEnabled,
                          onChanged: (val) => cubit.updateEmailCategory(
                            key: 'coachingAcademyUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.local_shipping_outlined,
                          title: 'Marketplace Order Updates',
                          subtitle:
                              'Order confirmation invoices, dispatch tracking details, and refund statements',
                          value: preferences.email.marketplaceUpdates,
                          isChannelEnabled: preferences.emailMasterEnabled,
                          onChanged: (val) => cubit.updateEmailCategory(
                            key: 'marketplaceUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.diversity_3_outlined,
                          title: 'Community & Social Updates',
                          subtitle:
                              'Weekly community digest, club newsletters, and platform announcements',
                          value: preferences.email.communityUpdates,
                          isChannelEnabled: preferences.emailMasterEnabled,
                          onChanged: (val) => cubit.updateEmailCategory(
                            key: 'communityUpdates',
                            value: val,
                          ),
                        ),
                        const Divider(height: 1),
                        PreferenceSwitchTile(
                          icon: Icons.local_offer_outlined,
                          title: 'Promotional Announcements',
                          subtitle:
                              'Exclusive member promotions, pro gear discounts, and platform newsletters',
                          value: preferences.email.promotions,
                          isChannelEnabled: preferences.emailMasterEnabled,
                          onChanged: (val) => cubit.updateEmailCategory(
                            key: 'promotions',
                            value: val,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Section C: General Settings
                    AppCard(
                      padding: AppSpacing.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.tune_outlined,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'General Settings',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'In-app sounds and notification preview options',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Divider(),
                          PreferenceSwitchTile(
                            icon: Icons.volume_up_outlined,
                            title: 'In-App Sound',
                            subtitle:
                                'Play audible sound alerts when notifications arrive while using the app',
                            value: preferences.general.soundEnabled,
                            isChannelEnabled: true,
                            onChanged: (val) => cubit.updateGeneralSetting(
                              key: 'soundEnabled',
                              value: val,
                            ),
                          ),
                          const Divider(height: 1),
                          PreferenceSwitchTile(
                            icon: Icons.preview_outlined,
                            title: 'Notification Preview Details',
                            subtitle:
                                'Display message details, sender name, and action previews in popup banners',
                            value: preferences.general.detailedPreviews,
                            isChannelEnabled: true,
                            onChanged: (val) => cubit.updateGeneralSetting(
                              key: 'detailedPreviews',
                              value: val,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Section D: Reset Action
                    AppButton.destructive(
                      label: 'Reset to Default Settings',
                      icon: const Icon(Icons.restore_outlined),
                      onPressed: _handleReset,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Restores all push, email, and sound preferences to recommended platform defaults.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool masterValue,
    required ValueChanged<bool> onMasterChanged,
    required bool isChannelEnabled,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);

    return AppCard(
      padding: AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
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
              const SizedBox(width: AppSpacing.sm),
              Switch.adaptive(
                value: masterValue,
                onChanged: onMasterChanged,
                activeThumbColor: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildMutedBanner({
    required BuildContext context,
    required String message,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
