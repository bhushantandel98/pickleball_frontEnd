import 'package:equatable/equatable.dart';

/// Push notification channel category toggles.
class PushNotificationPreferences extends Equatable {
  final bool accountSecurity;
  final bool bookingUpdates;
  final bool tournamentUpdates;
  final bool matchScoringUpdates;
  final bool coachingAcademyUpdates;
  final bool marketplaceUpdates;
  final bool communityUpdates;
  final bool promotions;

  const PushNotificationPreferences({
    required this.accountSecurity,
    required this.bookingUpdates,
    required this.tournamentUpdates,
    required this.matchScoringUpdates,
    required this.coachingAcademyUpdates,
    required this.marketplaceUpdates,
    required this.communityUpdates,
    required this.promotions,
  });

  /// Sensible default preferences for push channel.
  factory PushNotificationPreferences.defaults() {
    return const PushNotificationPreferences(
      accountSecurity: true,
      bookingUpdates: true,
      tournamentUpdates: true,
      matchScoringUpdates: true,
      coachingAcademyUpdates: true,
      marketplaceUpdates: true,
      communityUpdates: true,
      promotions: false,
    );
  }

  PushNotificationPreferences copyWith({
    bool? accountSecurity,
    bool? bookingUpdates,
    bool? tournamentUpdates,
    bool? matchScoringUpdates,
    bool? coachingAcademyUpdates,
    bool? marketplaceUpdates,
    bool? communityUpdates,
    bool? promotions,
  }) {
    return PushNotificationPreferences(
      accountSecurity: accountSecurity ?? this.accountSecurity,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      tournamentUpdates: tournamentUpdates ?? this.tournamentUpdates,
      matchScoringUpdates: matchScoringUpdates ?? this.matchScoringUpdates,
      coachingAcademyUpdates:
          coachingAcademyUpdates ?? this.coachingAcademyUpdates,
      marketplaceUpdates: marketplaceUpdates ?? this.marketplaceUpdates,
      communityUpdates: communityUpdates ?? this.communityUpdates,
      promotions: promotions ?? this.promotions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountSecurity': accountSecurity,
      'bookingUpdates': bookingUpdates,
      'tournamentUpdates': tournamentUpdates,
      'matchScoringUpdates': matchScoringUpdates,
      'coachingAcademyUpdates': coachingAcademyUpdates,
      'marketplaceUpdates': marketplaceUpdates,
      'communityUpdates': communityUpdates,
      'promotions': promotions,
    };
  }

  factory PushNotificationPreferences.fromMap(Map<String, dynamic> map) {
    return PushNotificationPreferences(
      accountSecurity: map['accountSecurity'] as bool? ?? true,
      bookingUpdates: map['bookingUpdates'] as bool? ?? true,
      tournamentUpdates: map['tournamentUpdates'] as bool? ?? true,
      matchScoringUpdates: map['matchScoringUpdates'] as bool? ?? true,
      coachingAcademyUpdates: map['coachingAcademyUpdates'] as bool? ?? true,
      marketplaceUpdates: map['marketplaceUpdates'] as bool? ?? true,
      communityUpdates: map['communityUpdates'] as bool? ?? true,
      promotions: map['promotions'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        accountSecurity,
        bookingUpdates,
        tournamentUpdates,
        matchScoringUpdates,
        coachingAcademyUpdates,
        marketplaceUpdates,
        communityUpdates,
        promotions,
      ];
}

/// Email notification channel category toggles.
class EmailNotificationPreferences extends Equatable {
  final bool accountSecurity;
  final bool bookingUpdates;
  final bool tournamentUpdates;
  final bool coachingAcademyUpdates;
  final bool marketplaceUpdates;
  final bool communityUpdates;
  final bool promotions;

  const EmailNotificationPreferences({
    required this.accountSecurity,
    required this.bookingUpdates,
    required this.tournamentUpdates,
    required this.coachingAcademyUpdates,
    required this.marketplaceUpdates,
    required this.communityUpdates,
    required this.promotions,
  });

  /// Sensible default preferences for email channel.
  factory EmailNotificationPreferences.defaults() {
    return const EmailNotificationPreferences(
      accountSecurity: true,
      bookingUpdates: true,
      tournamentUpdates: true,
      coachingAcademyUpdates: true,
      marketplaceUpdates: true,
      communityUpdates: false,
      promotions: false,
    );
  }

  EmailNotificationPreferences copyWith({
    bool? accountSecurity,
    bool? bookingUpdates,
    bool? tournamentUpdates,
    bool? coachingAcademyUpdates,
    bool? marketplaceUpdates,
    bool? communityUpdates,
    bool? promotions,
  }) {
    return EmailNotificationPreferences(
      accountSecurity: accountSecurity ?? this.accountSecurity,
      bookingUpdates: bookingUpdates ?? this.bookingUpdates,
      tournamentUpdates: tournamentUpdates ?? this.tournamentUpdates,
      coachingAcademyUpdates:
          coachingAcademyUpdates ?? this.coachingAcademyUpdates,
      marketplaceUpdates: marketplaceUpdates ?? this.marketplaceUpdates,
      communityUpdates: communityUpdates ?? this.communityUpdates,
      promotions: promotions ?? this.promotions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountSecurity': accountSecurity,
      'bookingUpdates': bookingUpdates,
      'tournamentUpdates': tournamentUpdates,
      'coachingAcademyUpdates': coachingAcademyUpdates,
      'marketplaceUpdates': marketplaceUpdates,
      'communityUpdates': communityUpdates,
      'promotions': promotions,
    };
  }

  factory EmailNotificationPreferences.fromMap(Map<String, dynamic> map) {
    return EmailNotificationPreferences(
      accountSecurity: map['accountSecurity'] as bool? ?? true,
      bookingUpdates: map['bookingUpdates'] as bool? ?? true,
      tournamentUpdates: map['tournamentUpdates'] as bool? ?? true,
      coachingAcademyUpdates: map['coachingAcademyUpdates'] as bool? ?? true,
      marketplaceUpdates: map['marketplaceUpdates'] as bool? ?? true,
      communityUpdates: map['communityUpdates'] as bool? ?? false,
      promotions: map['promotions'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        accountSecurity,
        bookingUpdates,
        tournamentUpdates,
        coachingAcademyUpdates,
        marketplaceUpdates,
        communityUpdates,
        promotions,
      ];
}

/// General device/in-app notification display and sound preferences.
class GeneralNotificationPreferences extends Equatable {
  final bool soundEnabled;
  final bool detailedPreviews;

  const GeneralNotificationPreferences({
    required this.soundEnabled,
    required this.detailedPreviews,
  });

  factory GeneralNotificationPreferences.defaults() {
    return const GeneralNotificationPreferences(
      soundEnabled: true,
      detailedPreviews: true,
    );
  }

  GeneralNotificationPreferences copyWith({
    bool? soundEnabled,
    bool? detailedPreviews,
  }) {
    return GeneralNotificationPreferences(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      detailedPreviews: detailedPreviews ?? this.detailedPreviews,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'soundEnabled': soundEnabled,
      'detailedPreviews': detailedPreviews,
    };
  }

  factory GeneralNotificationPreferences.fromMap(Map<String, dynamic> map) {
    return GeneralNotificationPreferences(
      soundEnabled: map['soundEnabled'] as bool? ?? true,
      detailedPreviews: map['detailedPreviews'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [soundEnabled, detailedPreviews];
}

/// Aggregate root entity encapsulating all user notification preferences.
class NotificationPreferences extends Equatable {
  final String userId;
  final bool pushMasterEnabled;
  final bool emailMasterEnabled;
  final PushNotificationPreferences push;
  final EmailNotificationPreferences email;
  final GeneralNotificationPreferences general;

  const NotificationPreferences({
    required this.userId,
    required this.pushMasterEnabled,
    required this.emailMasterEnabled,
    required this.push,
    required this.email,
    required this.general,
  });

  /// Factory constructing verified defaults for the designated user.
  factory NotificationPreferences.defaults({String userId = 'default_user'}) {
    return NotificationPreferences(
      userId: userId,
      pushMasterEnabled: true,
      emailMasterEnabled: true,
      push: PushNotificationPreferences.defaults(),
      email: EmailNotificationPreferences.defaults(),
      general: GeneralNotificationPreferences.defaults(),
    );
  }

  NotificationPreferences copyWith({
    String? userId,
    bool? pushMasterEnabled,
    bool? emailMasterEnabled,
    PushNotificationPreferences? push,
    EmailNotificationPreferences? email,
    GeneralNotificationPreferences? general,
  }) {
    return NotificationPreferences(
      userId: userId ?? this.userId,
      pushMasterEnabled: pushMasterEnabled ?? this.pushMasterEnabled,
      emailMasterEnabled: emailMasterEnabled ?? this.emailMasterEnabled,
      push: push ?? this.push,
      email: email ?? this.email,
      general: general ?? this.general,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'pushMasterEnabled': pushMasterEnabled,
      'emailMasterEnabled': emailMasterEnabled,
      'push': push.toMap(),
      'email': email.toMap(),
      'general': general.toMap(),
    };
  }

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      userId: map['userId'] as String? ?? 'default_user',
      pushMasterEnabled: map['pushMasterEnabled'] as bool? ?? true,
      emailMasterEnabled: map['emailMasterEnabled'] as bool? ?? true,
      push: map['push'] != null
          ? PushNotificationPreferences.fromMap(
              map['push'] as Map<String, dynamic>)
          : PushNotificationPreferences.defaults(),
      email: map['email'] != null
          ? EmailNotificationPreferences.fromMap(
              map['email'] as Map<String, dynamic>)
          : EmailNotificationPreferences.defaults(),
      general: map['general'] != null
          ? GeneralNotificationPreferences.fromMap(
              map['general'] as Map<String, dynamic>)
          : GeneralNotificationPreferences.defaults(),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        pushMasterEnabled,
        emailMasterEnabled,
        push,
        email,
        general,
      ];
}
