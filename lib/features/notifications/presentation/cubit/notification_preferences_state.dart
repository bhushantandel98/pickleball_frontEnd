import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/notifications/domain/entities/notification_preferences.dart';

/// Base state for Notification Preferences operations.
sealed class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState();

  @override
  List<Object?> get props => [];
}

/// Initial state before preferences have been requested.
final class NotificationPreferencesInitial
    extends NotificationPreferencesState {
  const NotificationPreferencesInitial();
}

/// Loading state while fetching or performing initial resolution.
final class NotificationPreferencesLoading
    extends NotificationPreferencesState {
  const NotificationPreferencesLoading();
}

/// State emitted when preferences are loaded and ready for interaction.
final class NotificationPreferencesLoaded
    extends NotificationPreferencesState {
  final NotificationPreferences preferences;
  final String? feedbackMessage;
  final bool isSaving;

  const NotificationPreferencesLoaded({
    required this.preferences,
    this.feedbackMessage,
    this.isSaving = false,
  });

  NotificationPreferencesLoaded copyWith({
    NotificationPreferences? preferences,
    String? feedbackMessage,
    bool? isSaving,
  }) {
    return NotificationPreferencesLoaded(
      preferences: preferences ?? this.preferences,
      feedbackMessage: feedbackMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  @override
  List<Object?> get props => [preferences, feedbackMessage, isSaving];
}

/// Failure state when retrieval, saving, or reset encounters an issue.
final class NotificationPreferencesFailure
    extends NotificationPreferencesState {
  final String message;
  final NotificationPreferences? fallbackPreferences;

  const NotificationPreferencesFailure({
    required this.message,
    this.fallbackPreferences,
  });

  @override
  List<Object?> get props => [message, fallbackPreferences];
}
