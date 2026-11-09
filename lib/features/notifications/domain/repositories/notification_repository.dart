import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_item.dart';

/// Contract for fetching and interacting with in-app notifications.
abstract interface class NotificationRepository {
  /// Fetches all notifications for [userId].
  Future<Result<List<NotificationItem>>> getNotifications(String userId);

  /// Marks the designated [notificationId] as read.
  Future<Result<NotificationItem>> markAsRead(String notificationId);

  /// Marks the designated [notificationId] as unread.
  Future<Result<NotificationItem>> markAsUnread(String notificationId);

  /// Marks all notifications for [userId] as read.
  Future<Result<void>> markAllAsRead(String userId);

  /// Permanently deletes the notification identified by [notificationId].
  Future<Result<void>> deleteNotification(String notificationId);
}
