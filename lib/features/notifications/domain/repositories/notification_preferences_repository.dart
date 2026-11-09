import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_preferences.dart';

/// Contract for fetching, updating, and resetting user notification preferences.
abstract interface class NotificationPreferencesRepository {
  /// Fetches the notification preferences for [userId].
  Future<Result<NotificationPreferences>> getPreferences(String userId);

  /// Persists updated [preferences] for the user.
  Future<Result<NotificationPreferences>> updatePreferences(
    NotificationPreferences preferences,
  );

  /// Resets notification preferences for [userId] back to platform defaults.
  Future<Result<NotificationPreferences>> resetPreferences(String userId);
}
