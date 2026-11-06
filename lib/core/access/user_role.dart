import 'package:flutter/material.dart';

/// The 12 approved platform roles in the Pickleball Multi-Role Platform.
///
/// Follows FSD §1.2 and Architecture Proposal §9 with standardized route prefixes.
enum UserRole {
  player(
    id: 'player',
    displayName: 'Player',
    routePrefix: '/player',
    defaultDashboardPath: '/player/dashboard',
    icon: Icons.person_outline,
  ),
  coach(
    id: 'coach',
    displayName: 'Coach',
    routePrefix: '/coach',
    defaultDashboardPath: '/coach/dashboard',
    icon: Icons.sports_tennis_outlined,
  ),
  academy(
    id: 'academy',
    displayName: 'Academy Admin',
    routePrefix: '/academy',
    defaultDashboardPath: '/academy/dashboard',
    icon: Icons.school_outlined,
  ),
  academyStaff(
    id: 'academy-staff',
    displayName: 'Academy Staff',
    routePrefix: '/academy-staff',
    defaultDashboardPath: '/academy-staff/dashboard',
    icon: Icons.badge_outlined,
  ),
  venuePartner(
    id: 'venue-partner',
    displayName: 'Venue Partner',
    routePrefix: '/venue-partner',
    defaultDashboardPath: '/venue-partner/dashboard',
    icon: Icons.stadium_outlined,
  ),
  venueStaff(
    id: 'venue-staff',
    displayName: 'Venue Staff',
    routePrefix: '/venue-staff',
    defaultDashboardPath: '/venue-staff/dashboard',
    icon: Icons.storefront_outlined,
  ),
  tournamentOrganizer(
    id: 'tournament-organizer',
    displayName: 'Tournament Organizer',
    routePrefix: '/tournament-organizer',
    defaultDashboardPath: '/tournament-organizer/dashboard',
    icon: Icons.emoji_events_outlined,
  ),
  tournamentStaff(
    id: 'tournament-staff',
    displayName: 'Tournament Staff',
    routePrefix: '/tournament-staff',
    defaultDashboardPath: '/tournament-staff/dashboard',
    icon: Icons.assignment_ind_outlined,
  ),
  referee(
    id: 'referee',
    displayName: 'Referee',
    routePrefix: '/referee',
    defaultDashboardPath: '/referee/dashboard',
    icon: Icons.sports_score_outlined,
  ),
  marketplaceSeller(
    id: 'marketplace-seller',
    displayName: 'Marketplace Seller',
    routePrefix: '/marketplace-seller',
    defaultDashboardPath: '/marketplace-seller/dashboard',
    icon: Icons.store_outlined,
  ),
  applicationStaff(
    id: 'application-staff',
    displayName: 'Application Staff',
    routePrefix: '/application-staff',
    defaultDashboardPath: '/application-staff/dashboard',
    icon: Icons.admin_panel_settings_outlined,
  ),
  applicationAdmin(
    id: 'application-admin',
    displayName: 'Application Admin',
    routePrefix: '/application-admin',
    defaultDashboardPath: '/application-admin/dashboard',
    icon: Icons.security_outlined,
  );

  final String id;
  final String displayName;
  final String routePrefix;
  final String defaultDashboardPath;
  final IconData icon;

  const UserRole({
    required this.id,
    required this.displayName,
    required this.routePrefix,
    required this.defaultDashboardPath,
    required this.icon,
  });

  /// Whether this role is an operational/management role with desktop/web-priority UI requirements.
  ///
  /// The 8 web-priority roles are:
  /// Academy, Academy Staff, Tournament Organizer, Tournament Staff,
  /// Venue Partner, Venue Staff, Application Admin, and Application Staff.
  bool get isWebPriority {
    switch (this) {
      case UserRole.academy:
      case UserRole.academyStaff:
      case UserRole.tournamentOrganizer:
      case UserRole.tournamentStaff:
      case UserRole.venuePartner:
      case UserRole.venueStaff:
      case UserRole.applicationAdmin:
      case UserRole.applicationStaff:
        return true;
      case UserRole.player:
      case UserRole.coach:
      case UserRole.referee:
      case UserRole.marketplaceSeller:
        return false;
    }
  }

  /// Resolves a [UserRole] from a route path string.
  ///
  /// Returns `null` if the route path does not match any role prefix.
  static UserRole? fromRoutePath(String path) {
    for (final role in UserRole.values) {
      if (path == role.routePrefix || path.startsWith('${role.routePrefix}/')) {
        return role;
      }
    }
    return null;
  }

  /// Resolves a [UserRole] from its unique string ID.
  static UserRole? fromId(String id) {
    for (final role in UserRole.values) {
      if (role.id == id) {
        return role;
      }
    }
    return null;
  }
}
