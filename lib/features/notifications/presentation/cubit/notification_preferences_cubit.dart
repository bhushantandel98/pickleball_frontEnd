import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_preferences.dart';
import 'package:pickleball_platform/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notification_preferences_state.dart';

/// Cubit managing loading, channel master toggles, category preferences,
/// and default reset operations for user notification settings.
class NotificationPreferencesCubit
    extends Cubit<NotificationPreferencesState> {
  final NotificationPreferencesRepository repository;
  String _currentUserId = 'default_user';

  NotificationPreferencesCubit({
    required this.repository,
  }) : super(const NotificationPreferencesInitial());

  /// Loads notification preferences for [userId].
  Future<void> loadPreferences({String? userId}) async {
    if (userId != null && userId.trim().isNotEmpty) {
      _currentUserId = userId.trim();
    }
    emit(const NotificationPreferencesLoading());

    final result = await repository.getPreferences(_currentUserId);
    switch (result) {
      case Success<NotificationPreferences>(data: final prefs):
        emit(NotificationPreferencesLoaded(preferences: prefs));
      case FailureResult<NotificationPreferences>(failure: final failure):
        emit(NotificationPreferencesFailure(
          message: failure.message,
          fallbackPreferences:
              NotificationPreferences.defaults(userId: _currentUserId),
        ));
    }
  }

  /// Toggles master push notification channel. Sub-category preferences are preserved.
  Future<void> togglePushMaster(bool enabled) async {
    final current = _currentLoadedPreferences;
    if (current == null) return;

    final updated = current.copyWith(pushMasterEnabled: enabled);
    await _applyAndUpdate(
      updated,
      feedbackMessage: enabled
          ? 'Push notifications enabled'
          : 'Push notifications disabled',
    );
  }

  /// Toggles master email notification channel. Sub-category preferences are preserved.
  Future<void> toggleEmailMaster(bool enabled) async {
    final current = _currentLoadedPreferences;
    if (current == null) return;

    final updated = current.copyWith(emailMasterEnabled: enabled);
    await _applyAndUpdate(
      updated,
      feedbackMessage: enabled
          ? 'Email notifications enabled'
          : 'Email notifications disabled',
    );
  }

  /// Updates an individual push notification category toggle.
  Future<void> updatePushCategory({
    required String key,
    required bool value,
  }) async {
    final current = _currentLoadedPreferences;
    if (current == null) return;

    PushNotificationPreferences newPush;
    switch (key) {
      case 'accountSecurity':
        newPush = current.push.copyWith(accountSecurity: value);
        break;
      case 'bookingUpdates':
        newPush = current.push.copyWith(bookingUpdates: value);
        break;
      case 'tournamentUpdates':
        newPush = current.push.copyWith(tournamentUpdates: value);
        break;
      case 'matchScoringUpdates':
        newPush = current.push.copyWith(matchScoringUpdates: value);
        break;
      case 'coachingAcademyUpdates':
        newPush = current.push.copyWith(coachingAcademyUpdates: value);
        break;
      case 'marketplaceUpdates':
        newPush = current.push.copyWith(marketplaceUpdates: value);
        break;
      case 'communityUpdates':
        newPush = current.push.copyWith(communityUpdates: value);
        break;
      case 'promotions':
        newPush = current.push.copyWith(promotions: value);
        break;
      default:
        return;
    }

    final updated = current.copyWith(push: newPush);
    await _applyAndUpdate(updated, feedbackMessage: 'Preference updated');
  }

  /// Updates an individual email notification category toggle.
  Future<void> updateEmailCategory({
    required String key,
    required bool value,
  }) async {
    final current = _currentLoadedPreferences;
    if (current == null) return;

    EmailNotificationPreferences newEmail;
    switch (key) {
      case 'accountSecurity':
        newEmail = current.email.copyWith(accountSecurity: value);
        break;
      case 'bookingUpdates':
        newEmail = current.email.copyWith(bookingUpdates: value);
        break;
      case 'tournamentUpdates':
        newEmail = current.email.copyWith(tournamentUpdates: value);
        break;
      case 'coachingAcademyUpdates':
        newEmail = current.email.copyWith(coachingAcademyUpdates: value);
        break;
      case 'marketplaceUpdates':
        newEmail = current.email.copyWith(marketplaceUpdates: value);
        break;
      case 'communityUpdates':
        newEmail = current.email.copyWith(communityUpdates: value);
        break;
      case 'promotions':
        newEmail = current.email.copyWith(promotions: value);
        break;
      default:
        return;
    }

    final updated = current.copyWith(email: newEmail);
    await _applyAndUpdate(updated, feedbackMessage: 'Preference updated');
  }

  /// Updates general in-app sound or display preview settings.
  Future<void> updateGeneralSetting({
    required String key,
    required bool value,
  }) async {
    final current = _currentLoadedPreferences;
    if (current == null) return;

    GeneralNotificationPreferences newGeneral;
    switch (key) {
      case 'soundEnabled':
        newGeneral = current.general.copyWith(soundEnabled: value);
        break;
      case 'detailedPreviews':
        newGeneral = current.general.copyWith(detailedPreviews: value);
        break;
      default:
        return;
    }

    final updated = current.copyWith(general: newGeneral);
    await _applyAndUpdate(updated, feedbackMessage: 'Preference updated');
  }

  /// Restores all notification preferences to platform defaults.
  Future<void> resetToDefaults() async {
    emit(const NotificationPreferencesLoading());
    final result = await repository.resetPreferences(_currentUserId);
    switch (result) {
      case Success<NotificationPreferences>(data: final defaults):
        emit(NotificationPreferencesLoaded(
          preferences: defaults,
          feedbackMessage: 'Notification preferences restored to default settings',
        ));
      case FailureResult<NotificationPreferences>(failure: final failure):
        emit(NotificationPreferencesFailure(
          message: failure.message,
          fallbackPreferences: _currentLoadedPreferences,
        ));
    }
  }

  /// Clears any transient feedback banner.
  void clearFeedbackMessage() {
    if (state is NotificationPreferencesLoaded) {
      final current = state as NotificationPreferencesLoaded;
      if (current.feedbackMessage != null) {
        emit(current.copyWith(feedbackMessage: null));
      }
    }
  }

  NotificationPreferences? get _currentLoadedPreferences {
    if (state is NotificationPreferencesLoaded) {
      return (state as NotificationPreferencesLoaded).preferences;
    }
    if (state is NotificationPreferencesFailure) {
      return (state as NotificationPreferencesFailure).fallbackPreferences;
    }
    return null;
  }

  Future<void> _applyAndUpdate(
    NotificationPreferences updated, {
    String? feedbackMessage,
  }) async {
    // Optimistic UI update
    emit(NotificationPreferencesLoaded(
      preferences: updated,
      feedbackMessage: feedbackMessage,
      isSaving: true,
    ));

    final result = await repository.updatePreferences(updated);
    switch (result) {
      case Success<NotificationPreferences>(data: final saved):
        emit(NotificationPreferencesLoaded(
          preferences: saved,
          feedbackMessage: feedbackMessage,
          isSaving: false,
        ));
      case FailureResult<NotificationPreferences>(failure: final failure):
        emit(NotificationPreferencesFailure(
          message: failure.message,
          fallbackPreferences: updated,
        ));
    }
  }
}
