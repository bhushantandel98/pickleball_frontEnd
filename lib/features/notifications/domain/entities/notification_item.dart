import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/access/user_role.dart';

/// Supported notification categories consistent with approved PRDs.
enum NotificationCategory {
  bookings('bookings', 'Bookings', Icons.calendar_today_outlined),
  tournaments('tournaments', 'Tournaments', Icons.emoji_events_outlined),
  matches('matches', 'Matches', Icons.sports_tennis_outlined),
  coachingAcademy('coaching_academy', 'Coaching & Academy', Icons.school_outlined),
  marketplace('marketplace', 'Marketplace', Icons.shopping_bag_outlined),
  community('community', 'Community', Icons.groups_outlined),
  accountSecurity('account_security', 'Account & Security', Icons.shield_outlined);

  final String id;
  final String label;
  final IconData icon;

  const NotificationCategory(this.id, this.label, this.icon);

  static NotificationCategory fromId(String id) {
    return NotificationCategory.values.firstWhere(
      (cat) => cat.id == id,
      orElse: () => NotificationCategory.accountSecurity,
    );
  }
}

/// Filter options presented in the Notification Centre tabs/chips.
enum NotificationFilterCategory {
  all('all', 'All'),
  unread('unread', 'Unread'),
  bookings('bookings', 'Bookings'),
  tournaments('tournaments', 'Tournaments'),
  matches('matches', 'Matches'),
  coachingAcademy('coaching_academy', 'Coaching & Academy'),
  marketplace('marketplace', 'Marketplace'),
  community('community', 'Community'),
  accountSecurity('account_security', 'Account & Security');

  final String id;
  final String label;

  const NotificationFilterCategory(this.id, this.label);
}

/// Entity representing an individual platform notification item.
class NotificationItem extends Equatable {
  final String id;
  final String title;
  final String description;
  final NotificationCategory category;
  final DateTime timestamp;
  final bool isRead;
  final String? destinationRoute;
  final String? relatedEntityId;
  final String? organizationId;
  final String? organizationName;
  final String? tournamentId;
  final String? tournamentName;
  final UserRole? roleContext;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.destinationRoute,
    this.relatedEntityId,
    this.organizationId,
    this.organizationName,
    this.tournamentId,
    this.tournamentName,
    this.roleContext,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? description,
    NotificationCategory? category,
    DateTime? timestamp,
    bool? isRead,
    String? destinationRoute,
    String? relatedEntityId,
    String? organizationId,
    String? organizationName,
    String? tournamentId,
    String? tournamentName,
    UserRole? roleContext,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      destinationRoute: destinationRoute ?? this.destinationRoute,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      roleContext: roleContext ?? this.roleContext,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.id,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'destinationRoute': destinationRoute,
      'relatedEntityId': relatedEntityId,
      'organizationId': organizationId,
      'organizationName': organizationName,
      'tournamentId': tournamentId,
      'tournamentName': tournamentName,
      'roleContext': roleContext?.id,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      category: NotificationCategory.fromId(map['category'] as String? ?? ''),
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['isRead'] as bool? ?? false,
      destinationRoute: map['destinationRoute'] as String?,
      relatedEntityId: map['relatedEntityId'] as String?,
      organizationId: map['organizationId'] as String?,
      organizationName: map['organizationName'] as String?,
      tournamentId: map['tournamentId'] as String?,
      tournamentName: map['tournamentName'] as String?,
      roleContext: map['roleContext'] != null
          ? UserRole.fromId(map['roleContext'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        timestamp,
        isRead,
        destinationRoute,
        relatedEntityId,
        organizationId,
        organizationName,
        tournamentId,
        tournamentName,
        roleContext,
      ];
}
