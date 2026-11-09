import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_item.dart';

/// Base state for Notification Centre operations.
sealed class NotificationsState extends Equatable {
  const NotificationsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before notifications have been loaded.
final class NotificationsInitial extends NotificationsState {
  const NotificationsInitial();
}

/// Loading state while fetching or refreshing notifications.
final class NotificationsLoading extends NotificationsState {
  const NotificationsLoading();
}

/// State emitted when notifications are loaded and ready for interaction.
final class NotificationsLoaded extends NotificationsState {
  final List<NotificationItem> allNotifications;
  final NotificationFilterCategory selectedFilter;
  final String? feedbackMessage;

  const NotificationsLoaded({
    required this.allNotifications,
    this.selectedFilter = NotificationFilterCategory.all,
    this.feedbackMessage,
  });

  /// Filtered subset of notifications according to [selectedFilter].
  List<NotificationItem> get filteredNotifications {
    switch (selectedFilter) {
      case NotificationFilterCategory.all:
        return allNotifications;
      case NotificationFilterCategory.unread:
        return allNotifications.where((n) => !n.isRead).toList();
      case NotificationFilterCategory.bookings:
        return allNotifications
            .where((n) => n.category == NotificationCategory.bookings)
            .toList();
      case NotificationFilterCategory.tournaments:
        return allNotifications
            .where((n) => n.category == NotificationCategory.tournaments)
            .toList();
      case NotificationFilterCategory.matches:
        return allNotifications
            .where((n) => n.category == NotificationCategory.matches)
            .toList();
      case NotificationFilterCategory.coachingAcademy:
        return allNotifications
            .where((n) => n.category == NotificationCategory.coachingAcademy)
            .toList();
      case NotificationFilterCategory.marketplace:
        return allNotifications
            .where((n) => n.category == NotificationCategory.marketplace)
            .toList();
      case NotificationFilterCategory.community:
        return allNotifications
            .where((n) => n.category == NotificationCategory.community)
            .toList();
      case NotificationFilterCategory.accountSecurity:
        return allNotifications
            .where((n) => n.category == NotificationCategory.accountSecurity)
            .toList();
    }
  }

  /// Total count of unread notifications.
  int get unreadCount => allNotifications.where((n) => !n.isRead).length;

  NotificationsLoaded copyWith({
    List<NotificationItem>? allNotifications,
    NotificationFilterCategory? selectedFilter,
    String? feedbackMessage,
  }) {
    return NotificationsLoaded(
      allNotifications: allNotifications ?? this.allNotifications,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      feedbackMessage: feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
        allNotifications,
        selectedFilter,
        feedbackMessage,
      ];
}

/// State emitted when notification loading or mutating encounters an error.
final class NotificationsFailure extends NotificationsState {
  final String message;
  final List<NotificationItem>? fallbackNotifications;

  const NotificationsFailure({
    required this.message,
    this.fallbackNotifications,
  });

  @override
  List<Object?> get props => [message, fallbackNotifications];
}
