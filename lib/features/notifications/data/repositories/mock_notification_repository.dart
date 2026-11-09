import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_item.dart';
import 'package:pickleball_platform/features/notifications/domain/repositories/notification_repository.dart';

/// In-memory mock repository implementing [NotificationRepository] with
/// realistic multi-role notification datasets for local UI development and testing.
class MockNotificationRepository implements NotificationRepository {
  final List<NotificationItem> _notifications = [];

  MockNotificationRepository({List<NotificationItem>? initialData}) {
    if (initialData != null) {
      _notifications.addAll(initialData);
    } else {
      _seedDefaultNotifications();
    }
  }

  void _seedDefaultNotifications() {
    final now = DateTime.now();

    _notifications.addAll([
      NotificationItem(
        id: 'notif_001',
        title: 'Court Booking Confirmed',
        description:
            'Your reservation for Court 2 at Apex Pickleball Arena is confirmed for tomorrow at 6:00 PM.',
        category: NotificationCategory.bookings,
        timestamp: now.subtract(const Duration(minutes: 30)),
        isRead: false,
        destinationRoute: '/player/bookings',
        relatedEntityId: 'bk_apex_204',
        roleContext: UserRole.player,
      ),
      NotificationItem(
        id: 'notif_002',
        title: 'Quarterfinal Score Finalized',
        description:
            'Quarterfinal against Team Falcons ended 11-8, 11-9. Victory recorded! View match scorecard.',
        category: NotificationCategory.matches,
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
        destinationRoute: '/player/match-day',
        roleContext: UserRole.player,
      ),
      NotificationItem(
        id: 'notif_003',
        title: 'Tournament Draws Published',
        description:
            'Official brackets and seedings for the Mumbai Pickleball Championship 2026 have been published.',
        category: NotificationCategory.tournaments,
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: false,
        destinationRoute: '/tournament-organizer/dashboard',
        organizationId: 'org_tourn_001',
        organizationName: 'Pacific Pickleball Series',
        tournamentId: 'tourn_001',
        tournamentName: 'Mumbai Pickleball Championship 2026',
        roleContext: UserRole.tournamentOrganizer,
      ),
      NotificationItem(
        id: 'notif_004',
        title: 'Academy Batch Schedule Update',
        description:
            'The Advance Drill session has been rescheduled to Friday, 7:00 AM at Pinnacle Sports Academy.',
        category: NotificationCategory.coachingAcademy,
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        isRead: false,
        destinationRoute: '/coach/batches',
        organizationId: 'org_acad_001',
        organizationName: 'Pinnacle Sports Academy',
        roleContext: UserRole.coach,
      ),
      NotificationItem(
        id: 'notif_005',
        title: 'Pro Carbon Paddle Dispatched',
        description:
            'Your order #ORD-8821 for Carbon Fiber Pro Paddle has been dispatched via Express Logistics.',
        category: NotificationCategory.marketplace,
        timestamp: now.subtract(const Duration(days: 1, hours: 6)),
        isRead: true,
        destinationRoute: '/player/marketplace',
        relatedEntityId: 'ORD-8821',
        roleContext: UserRole.player,
      ),
      NotificationItem(
        id: 'notif_006',
        title: 'Weekly Club Scramble Invite',
        description:
            'Mumbai Picklers invited you to join this Sunday’s social doubles round-robin scramble.',
        category: NotificationCategory.community,
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
        destinationRoute: null,
        roleContext: UserRole.player,
      ),
      NotificationItem(
        id: 'notif_007',
        title: 'New Session Login Detected',
        description:
            'A new session was authenticated on Chrome (Windows 11) from Mumbai, India.',
        category: NotificationCategory.accountSecurity,
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
        destinationRoute: '/profile/settings',
        roleContext: null,
      ),
      NotificationItem(
        id: 'notif_008',
        title: 'Court Reservation Cancelled',
        description:
            'Walk-in court slot at Grand Slam Arena on Nov 10 was cancelled. Check desk operations.',
        category: NotificationCategory.bookings,
        timestamp: now.subtract(const Duration(days: 4)),
        isRead: true,
        destinationRoute: '/venue-staff/dashboard',
        relatedEntityId: 'bk_sun_109',
        organizationId: 'org_venue_001',
        organizationName: 'Grand Slam Arena',
        roleContext: UserRole.venueStaff,
      ),
    ]);
  }

  @override
  Future<Result<List<NotificationItem>>> getNotifications(String userId) async {
    final copy = List<NotificationItem>.from(_notifications)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return Success(copy);
  }

  @override
  Future<Result<NotificationItem>> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Notification not found'));
    }
    final updated = _notifications[index].copyWith(isRead: true);
    _notifications[index] = updated;
    return Success(updated);
  }

  @override
  Future<Result<NotificationItem>> markAsUnread(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Notification not found'));
    }
    final updated = _notifications[index].copyWith(isRead: false);
    _notifications[index] = updated;
    return Success(updated);
  }

  @override
  Future<Result<void>> markAllAsRead(String userId) async {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteNotification(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Notification not found'));
    }
    _notifications.removeAt(index);
    return const Success(null);
  }
}
