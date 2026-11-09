import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_spacing.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_item.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:pickleball_platform/features/notifications/presentation/router/notification_destination_router.dart';
import 'package:pickleball_platform/features/notifications/presentation/widgets/notification_category_chips.dart';
import 'package:pickleball_platform/features/notifications/presentation/widgets/notification_tile.dart';

/// Responsive Notification Centre screen with category tabs, unread highlights,
/// item management, and centralized navigation.
class NotificationCenterPage extends StatelessWidget {
  final NotificationsCubit? cubit;
  final String? userId;
  final VoidCallback? onBack;

  const NotificationCenterPage({
    super.key,
    this.cubit,
    this.userId,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (cubit != null) {
      return BlocProvider<NotificationsCubit>.value(
        value: cubit!,
        child: _NotificationCenterView(
          userId: userId,
          onBack: onBack,
        ),
      );
    }

    try {
      final existing = context.read<NotificationsCubit>();
      return BlocProvider<NotificationsCubit>.value(
        value: existing,
        child: _NotificationCenterView(
          userId: userId,
          onBack: onBack,
        ),
      );
    } catch (_) {
      return BlocProvider<NotificationsCubit>(
        create: (_) => sl<NotificationsCubit>(),
        child: _NotificationCenterView(
          userId: userId,
          onBack: onBack,
        ),
      );
    }
  }
}

class _NotificationCenterView extends StatefulWidget {
  final String? userId;
  final VoidCallback? onBack;

  const _NotificationCenterView({
    this.userId,
    this.onBack,
  });

  @override
  State<_NotificationCenterView> createState() =>
      _NotificationCenterViewState();
}

class _NotificationCenterViewState extends State<_NotificationCenterView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  void _loadNotifications() {
    String effectiveId = widget.userId ?? '';
    if (effectiveId.isEmpty) {
      try {
        final session = context.read<SessionCubit>().state;
        if (session.userId != null && session.userId!.isNotEmpty) {
          effectiveId = session.userId!;
        }
      } catch (_) {}
    }
    context.read<NotificationsCubit>().loadNotifications(userId: effectiveId);
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

  Future<void> _handleMarkAllAsRead() async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Mark all as read?',
      message: 'All unread notifications will be marked as read.',
      confirmLabel: 'Mark all as read',
      cancelLabel: 'Cancel',
    );

    if (confirmed == true && mounted) {
      context.read<NotificationsCubit>().markAllAsRead();
    }
  }

  Future<void> _handleDeleteNotification(NotificationItem item) async {
    final confirmed = await AppConfirmationDialog.show(
      context: context,
      title: 'Delete Notification?',
      message: 'Are you sure you want to remove this notification?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      context.read<NotificationsCubit>().deleteNotification(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Notification Centre',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: _handleBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: _handleMarkAllAsRead,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Notification Preferences',
            onPressed: () =>
                context.push(AppRoutes.notificationPreferences),
          ),
        ],
      ),
      body: BlocConsumer<NotificationsCubit, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsLoaded &&
              state.feedbackMessage != null) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.feedbackMessage!),
                duration: const Duration(seconds: 2),
                backgroundColor: theme.colorScheme.primary,
              ),
            );
            context.read<NotificationsCubit>().clearFeedbackMessage();
          }
        },
        builder: (context, state) {
          if (state is NotificationsLoading || state is NotificationsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is NotificationsFailure) {
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
                      'Failed to load notifications',
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
                      onPressed: _loadNotifications,
                    ),
                  ],
                ),
              ),
            );
          }

          final loadedState = state as NotificationsLoaded;
          final cubit = context.read<NotificationsCubit>();
          final filtered = loadedState.filteredNotifications;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.sm),

              // Filter Chips
              NotificationCategoryChips(
                selectedFilter: loadedState.selectedFilter,
                totalCount: loadedState.allNotifications.length,
                unreadCount: loadedState.unreadCount,
                onFilterSelected: (filter) => cubit.setFilter(filter),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Notification List or Empty Views
              Expanded(
                child: loadedState.allNotifications.isEmpty
                    ? _buildOverallEmptyState(theme)
                    : filtered.isEmpty
                        ? _buildFilterEmptyState(theme, loadedState, cubit)
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: AppSpacing.maxFormWidth,
                              ),
                              child: ListView.separated(
                                padding: AppSpacing.screenPadding,
                                itemCount: filtered.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.sm),
                                itemBuilder: (context, index) {
                                  final item = filtered[index];
                                  return NotificationTile(
                                    notification: item,
                                    onTap: () {
                                      if (!item.isRead) {
                                        cubit.markAsRead(item.id);
                                      }
                                      NotificationDestinationRouter
                                          .navigateToDestination(context, item);
                                    },
                                    onToggleRead: () {
                                      if (item.isRead) {
                                        cubit.markAsUnread(item.id);
                                      } else {
                                        cubit.markAsRead(item.id);
                                      }
                                    },
                                    onDelete: () =>
                                        _handleDeleteNotification(item),
                                  );
                                },
                              ),
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverallEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You are all caught up! New alerts and updates will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterEmptyState(
    ThemeData theme,
    NotificationsLoaded state,
    NotificationsCubit cubit,
  ) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No ${state.selectedFilter.label} Notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'No notifications found matching the active filter.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton.secondary(
              label: 'View All Notifications',
              onPressed: () =>
                  cubit.setFilter(NotificationFilterCategory.all),
            ),
          ],
        ),
      ),
    );
  }
}
