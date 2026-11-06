import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';

/// Centralized role-to-dashboard routing authority for all 12 platform roles.
///
/// Ensures role routing mappings are never hardcoded independently in individual widgets.
abstract final class RoleDashboardRouter {
  /// Comprehensive mapping from [UserRole] to dashboard entry route paths.
  static const Map<UserRole, String> _roleDashboardMap = {
    UserRole.player: AppRoutes.playerDashboard,
    UserRole.coach: AppRoutes.coachDashboard,
    UserRole.academy: AppRoutes.academyDashboard,
    UserRole.academyStaff: AppRoutes.academyStaffDashboard,
    UserRole.venuePartner: AppRoutes.venuePartnerDashboard,
    UserRole.venueStaff: AppRoutes.venueStaffDashboard,
    UserRole.tournamentOrganizer: AppRoutes.tournamentOrganizerDashboard,
    UserRole.tournamentStaff: AppRoutes.tournamentStaffDashboard,
    UserRole.referee: AppRoutes.refereeDashboard,
    UserRole.marketplaceSeller: AppRoutes.marketplaceSellerDashboard,
    UserRole.applicationStaff: AppRoutes.applicationStaffDashboard,
    UserRole.applicationAdmin: AppRoutes.applicationAdminDashboard,
  };

  /// Returns the canonical dashboard route for [role].
  static String getDashboardRoute(UserRole role) {
    return _roleDashboardMap[role] ?? role.defaultDashboardPath;
  }

  /// Navigates directly to the designated dashboard for [role] using GoRouter.
  static void navigateToDashboard(BuildContext context, UserRole role) {
    final route = getDashboardRoute(role);
    context.go(route);
  }

  /// Returns the [UserRole] corresponding to a dashboard path, or null if not a dashboard.
  static UserRole? getRoleForDashboardPath(String path) {
    for (final entry in _roleDashboardMap.entries) {
      if (entry.value == path) {
        return entry.key;
      }
    }
    return null;
  }

  /// Checks if [path] is any role's default dashboard route.
  static bool isDashboardRoute(String path) {
    return _roleDashboardMap.containsValue(path);
  }
}
