import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_preferences.dart';
import 'package:pickleball_platform/features/notifications/domain/repositories/notification_preferences_repository.dart';

/// In-memory mock repository implementing [NotificationPreferencesRepository]
/// for local UI development and unit/widget testing.
class MockNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  final Map<String, NotificationPreferences> _storage = {};

  MockNotificationPreferencesRepository({
    Map<String, NotificationPreferences>? initialData,
  }) {
    if (initialData != null) {
      _storage.addAll(initialData);
    }
  }

  @override
  Future<Result<NotificationPreferences>> getPreferences(String userId) async {
    final effectiveId = userId.trim().isEmpty ? 'default_user' : userId.trim();
    if (!_storage.containsKey(effectiveId)) {
      _storage[effectiveId] = NotificationPreferences.defaults(userId: effectiveId);
    }
    return Success(_storage[effectiveId]!);
  }

  @override
  Future<Result<NotificationPreferences>> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    final effectiveId = preferences.userId.trim().isEmpty
        ? 'default_user'
        : preferences.userId.trim();

    _storage[effectiveId] = preferences;
    return Success(preferences);
  }

  @override
  Future<Result<NotificationPreferences>> resetPreferences(String userId) async {
    final effectiveId = userId.trim().isEmpty ? 'default_user' : userId.trim();
    final defaults = NotificationPreferences.defaults(userId: effectiveId);
    _storage[effectiveId] = defaults;
    return Success(defaults);
  }
}
