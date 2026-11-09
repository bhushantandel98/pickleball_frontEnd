import 'package:equatable/equatable.dart';

/// Enum defining the type of upcoming activity for a player.
enum UpcomingActivityType {
  courtBooking,
  tournamentMatch,
  coachingSession;

  String get displayName {
    switch (this) {
      case UpcomingActivityType.courtBooking:
        return 'Court Booking';
      case UpcomingActivityType.tournamentMatch:
        return 'Tournament Match';
      case UpcomingActivityType.coachingSession:
        return 'Coaching Session';
    }
  }
}

/// Enum representing the status of an upcoming activity.
enum ActivityStatus {
  confirmed,
  scheduled,
  pending;

  String get label {
    switch (this) {
      case ActivityStatus.confirmed:
        return 'Confirmed';
      case ActivityStatus.scheduled:
        return 'Scheduled';
      case ActivityStatus.pending:
        return 'Payment Pending';
    }
  }
}

/// Category classification for player recent activity stream.
enum RecentActivityCategory {
  match,
  booking,
  tournament,
  marketplace;

  String get displayName {
    switch (this) {
      case RecentActivityCategory.match:
        return 'Match';
      case RecentActivityCategory.booking:
        return 'Booking';
      case RecentActivityCategory.tournament:
        return 'Tournament';
      case RecentActivityCategory.marketplace:
        return 'Order';
    }
  }
}

/// Summary entity for the active player's profile in the dashboard header.
class PlayerProfileSummary extends Equatable {
  final String userId;
  final String fullName;
  final String? avatarUrl;
  final double skillRating;
  final String ratingTier;
  final String location;
  final String playStyle;
  final DateTime memberSince;

  const PlayerProfileSummary({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.skillRating,
    required this.ratingTier,
    required this.location,
    required this.playStyle,
    required this.memberSince,
  });

  PlayerProfileSummary copyWith({
    String? userId,
    String? fullName,
    String? avatarUrl,
    double? skillRating,
    String? ratingTier,
    String? location,
    String? playStyle,
    DateTime? memberSince,
  }) {
    return PlayerProfileSummary(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      skillRating: skillRating ?? this.skillRating,
      ratingTier: ratingTier ?? this.ratingTier,
      location: location ?? this.location,
      playStyle: playStyle ?? this.playStyle,
      memberSince: memberSince ?? this.memberSince,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        fullName,
        avatarUrl,
        skillRating,
        ratingTier,
        location,
        playStyle,
        memberSince,
      ];
}

/// Entity encapsulating key player performance & booking statistics.
class PlayerStats extends Equatable {
  final int matchesPlayed;
  final double winRatePercentage;
  final int upcomingBookingsCount;
  final int tournamentsEnteredCount;
  final double skillRating;

  const PlayerStats({
    required this.matchesPlayed,
    required this.winRatePercentage,
    required this.upcomingBookingsCount,
    required this.tournamentsEnteredCount,
    required this.skillRating,
  });

  PlayerStats copyWith({
    int? matchesPlayed,
    double? winRatePercentage,
    int? upcomingBookingsCount,
    int? tournamentsEnteredCount,
    double? skillRating,
  }) {
    return PlayerStats(
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      winRatePercentage: winRatePercentage ?? this.winRatePercentage,
      upcomingBookingsCount:
          upcomingBookingsCount ?? this.upcomingBookingsCount,
      tournamentsEnteredCount:
          tournamentsEnteredCount ?? this.tournamentsEnteredCount,
      skillRating: skillRating ?? this.skillRating,
    );
  }

  @override
  List<Object?> get props => [
        matchesPlayed,
        winRatePercentage,
        upcomingBookingsCount,
        tournamentsEnteredCount,
        skillRating,
      ];
}

/// Entity representing an upcoming scheduled commitment for the player.
class UpcomingActivity extends Equatable {
  final String id;
  final String title;
  final UpcomingActivityType type;
  final String venueOrLocation;
  final String? courtName;
  final DateTime dateTime;
  final String timeSlot;
  final ActivityStatus status;
  final String statusLabel;
  final String? actionRoute;
  final String? opponentOrCoach;

  const UpcomingActivity({
    required this.id,
    required this.title,
    required this.type,
    required this.venueOrLocation,
    this.courtName,
    required this.dateTime,
    required this.timeSlot,
    required this.status,
    required this.statusLabel,
    this.actionRoute,
    this.opponentOrCoach,
  });

  UpcomingActivity copyWith({
    String? id,
    String? title,
    UpcomingActivityType? type,
    String? venueOrLocation,
    String? courtName,
    DateTime? dateTime,
    String? timeSlot,
    ActivityStatus? status,
    String? statusLabel,
    String? actionRoute,
    String? opponentOrCoach,
  }) {
    return UpcomingActivity(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      venueOrLocation: venueOrLocation ?? this.venueOrLocation,
      courtName: courtName ?? this.courtName,
      dateTime: dateTime ?? this.dateTime,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      actionRoute: actionRoute ?? this.actionRoute,
      opponentOrCoach: opponentOrCoach ?? this.opponentOrCoach,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        venueOrLocation,
        courtName,
        dateTime,
        timeSlot,
        status,
        statusLabel,
        actionRoute,
        opponentOrCoach,
      ];
}

/// Entity representing a recent completed activity or milestone.
class RecentActivityItem extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final RecentActivityCategory category;
  final String? resultBadge;
  final String? actionRoute;

  const RecentActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.category,
    this.resultBadge,
    this.actionRoute,
  });

  RecentActivityItem copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? timestamp,
    RecentActivityCategory? category,
    String? resultBadge,
    String? actionRoute,
  }) {
    return RecentActivityItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      resultBadge: resultBadge ?? this.resultBadge,
      actionRoute: actionRoute ?? this.actionRoute,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        timestamp,
        category,
        resultBadge,
        actionRoute,
      ];
}

/// Aggregate root entity containing all data required for the Player Dashboard.
class PlayerDashboardData extends Equatable {
  final PlayerProfileSummary profile;
  final PlayerStats stats;
  final List<UpcomingActivity> upcomingActivities;
  final List<RecentActivityItem> recentActivities;
  final int unreadNotificationsCount;

  const PlayerDashboardData({
    required this.profile,
    required this.stats,
    this.upcomingActivities = const [],
    this.recentActivities = const [],
    this.unreadNotificationsCount = 0,
  });

  PlayerDashboardData copyWith({
    PlayerProfileSummary? profile,
    PlayerStats? stats,
    List<UpcomingActivity>? upcomingActivities,
    List<RecentActivityItem>? recentActivities,
    int? unreadNotificationsCount,
  }) {
    return PlayerDashboardData(
      profile: profile ?? this.profile,
      stats: stats ?? this.stats,
      upcomingActivities: upcomingActivities ?? this.upcomingActivities,
      recentActivities: recentActivities ?? this.recentActivities,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        stats,
        upcomingActivities,
        recentActivities,
        unreadNotificationsCount,
      ];
}
