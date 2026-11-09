import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_item.dart';
import 'package:pickleball_platform/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notifications_state.dart';

/// Cubit managing loading, category filtering, unread status toggles,
/// bulk mark-all-read, and deletion actions for the Notification Centre.
class NotificationsCubit extends Cubit<NotificationsState> {
  final NotificationRepository repository;
  String _currentUserId = 'default_user';

  NotificationsCubit({
    required this.repository,
  }) : super(const NotificationsInitial());

  /// Loads all notifications for [userId].
  Future<void> loadNotifications({String? userId}) async {
    if (userId != null && userId.trim().isNotEmpty) {
      _currentUserId = userId.trim();
    }
    emit(const NotificationsLoading());

    final result = await repository.getNotifications(_currentUserId);
    switch (result) {
      case Success<List<NotificationItem>>(data: final list):
        final filter = state is NotificationsLoaded
            ? (state as NotificationsLoaded).selectedFilter
            : NotificationFilterCategory.all;
        emit(NotificationsLoaded(
          allNotifications: list,
          selectedFilter: filter,
        ));
      case FailureResult<List<NotificationItem>>(failure: final failure):
        emit(NotificationsFailure(message: failure.message));
    }
  }

  /// Sets the active notification filter category.
  void setFilter(NotificationFilterCategory filter) {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      emit(current.copyWith(selectedFilter: filter));
    }
  }

  /// Marks a specific notification as read.
  Future<void> markAsRead(String notificationId) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    // Optimistic UI update
    final updatedList = current.allNotifications.map((n) {
      return n.id == notificationId ? n.copyWith(isRead: true) : n;
    }).toList();

    emit(current.copyWith(allNotifications: updatedList));

    final result = await repository.markAsRead(notificationId);
    if (result is FailureResult<NotificationItem>) {
      // Revert if failed
      emit(current.copyWith(
        feedbackMessage: 'Failed to update notification status',
      ));
    }
  }

  /// Marks a specific notification as unread.
  Future<void> markAsUnread(String notificationId) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    // Optimistic UI update
    final updatedList = current.allNotifications.map((n) {
      return n.id == notificationId ? n.copyWith(isRead: false) : n;
    }).toList();

    emit(current.copyWith(
      allNotifications: updatedList,
      feedbackMessage: 'Marked as unread',
    ));

    final result = await repository.markAsUnread(notificationId);
    if (result is FailureResult<NotificationItem>) {
      // Revert if failed
      emit(current.copyWith(
        feedbackMessage: 'Failed to update notification status',
      ));
    }
  }

  /// Marks all notifications for the active user as read.
  Future<void> markAllAsRead() async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    // Optimistic UI update
    final updatedList = current.allNotifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    emit(current.copyWith(
      allNotifications: updatedList,
      feedbackMessage: 'All notifications marked as read',
    ));

    final result = await repository.markAllAsRead(_currentUserId);
    if (result is FailureResult<void>) {
      emit(current.copyWith(
        feedbackMessage: 'Failed to mark all as read',
      ));
    }
  }

  /// Permanently deletes [notificationId] from the user's notification list.
  Future<void> deleteNotification(String notificationId) async {
    if (state is! NotificationsLoaded) return;
    final current = state as NotificationsLoaded;

    // Optimistic UI update
    final updatedList = current.allNotifications
        .where((n) => n.id != notificationId)
        .toList();

    emit(current.copyWith(
      allNotifications: updatedList,
      feedbackMessage: 'Notification deleted',
    ));

    final result = await repository.deleteNotification(notificationId);
    if (result is FailureResult<void>) {
      emit(current.copyWith(
        allNotifications: current.allNotifications,
        feedbackMessage: 'Failed to delete notification',
      ));
    }
  }

  /// Clears any transient feedback banner messages.
  void clearFeedbackMessage() {
    if (state is NotificationsLoaded) {
      final current = state as NotificationsLoaded;
      if (current.feedbackMessage != null) {
        emit(current.copyWith(feedbackMessage: null));
      }
    }
  }
}
