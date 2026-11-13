import 'package:flutter/material.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/navigation/nav_destination_item.dart';

/// Central registry mapping each [UserRole] to its primary navigation menu items.
class RoleNavConfig {
  RoleNavConfig._();

  static List<NavDestinationItem> getDestinationsForRole(UserRole role) {
    switch (role) {
      case UserRole.player:
        return const [
          NavDestinationItem(
            label: 'Home',
            routePath: AppRoutes.playerDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          NavDestinationItem(
            label: 'Courts',
            routePath: AppRoutes.playerVenues,
            icon: Icons.sports_tennis_outlined,
            selectedIcon: Icons.sports_tennis,
          ),
          NavDestinationItem(
            label: 'Bookings',
            routePath: AppRoutes.playerBookings,
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
          ),
          NavDestinationItem(
            label: 'Tournaments',
            routePath: AppRoutes.playerTournaments,
            icon: Icons.emoji_events_outlined,
            selectedIcon: Icons.emoji_events,
          ),
          NavDestinationItem(
            label: 'Shop',
            routePath: AppRoutes.playerMarketplace,
            icon: Icons.shopping_bag_outlined,
            selectedIcon: Icons.shopping_bag,
          ),
        ];

      case UserRole.coach:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.coachDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          NavDestinationItem(
            label: 'Calendar',
            routePath: AppRoutes.coachCalendar,
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
          ),
          NavDestinationItem(
            label: 'Personal',
            routePath: AppRoutes.coachPersonalCoaching,
            icon: Icons.sports_tennis_outlined,
            selectedIcon: Icons.sports_tennis,
          ),
          NavDestinationItem(
            label: 'Batches',
            routePath: AppRoutes.coachBatches,
            icon: Icons.groups_outlined,
            selectedIcon: Icons.groups,
          ),
          NavDestinationItem(
            label: 'Profile',
            routePath: AppRoutes.coachProfile,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
          ),
        ];

      case UserRole.academy:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.academyDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          NavDestinationItem(
            label: 'Branches',
            routePath: AppRoutes.academyBranches,
            icon: Icons.store_outlined,
            selectedIcon: Icons.store,
          ),
          NavDestinationItem(
            label: 'Programs',
            routePath: AppRoutes.academyPrograms,
            icon: Icons.menu_book_outlined,
            selectedIcon: Icons.menu_book,
          ),
          NavDestinationItem(
            label: 'Coaches',
            routePath: AppRoutes.academyCoaches,
            icon: Icons.sports_outlined,
            selectedIcon: Icons.sports,
          ),
          NavDestinationItem(
            label: 'Enrollments',
            routePath: AppRoutes.academyEnrollments,
            icon: Icons.badge_outlined,
            selectedIcon: Icons.badge,
          ),
        ];

      case UserRole.academyStaff:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.academyStaffDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          NavDestinationItem(
            label: 'Attendance',
            routePath: AppRoutes.academyStaffAttendance,
            icon: Icons.fact_check_outlined,
            selectedIcon: Icons.fact_check,
          ),
          NavDestinationItem(
            label: 'Operations',
            routePath: AppRoutes.academyStaffOperations,
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune,
          ),
        ];

      case UserRole.venuePartner:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.venuePartnerDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          NavDestinationItem(
            label: 'Locations',
            routePath: AppRoutes.venuePartnerLocations,
            icon: Icons.place_outlined,
            selectedIcon: Icons.place,
          ),
          NavDestinationItem(
            label: 'Calendar',
            routePath: AppRoutes.venuePartnerCalendar,
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today,
          ),
          NavDestinationItem(
            label: 'Bookings',
            routePath: AppRoutes.venuePartnerBookings,
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long,
          ),
        ];

      case UserRole.venueStaff:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.venueStaffDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
        ];

      case UserRole.tournamentOrganizer:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.tournamentOrganizerDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          NavDestinationItem(
            label: 'Create',
            routePath: AppRoutes.tournamentOrganizerCreate,
            icon: Icons.add_circle_outline,
            selectedIcon: Icons.add_circle,
          ),
        ];

      case UserRole.tournamentStaff:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.tournamentStaffDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
        ];

      case UserRole.referee:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.refereeDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
        ];

      case UserRole.marketplaceSeller:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.marketplaceSellerDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          NavDestinationItem(
            label: 'Onboarding',
            routePath: AppRoutes.marketplaceSellerOnboarding,
            icon: Icons.verified_user_outlined,
            selectedIcon: Icons.verified_user,
          ),
          NavDestinationItem(
            label: 'Orders',
            routePath: AppRoutes.marketplaceSellerOrders,
            icon: Icons.local_shipping_outlined,
            selectedIcon: Icons.local_shipping,
          ),
          NavDestinationItem(
            label: 'Settlements',
            routePath: AppRoutes.marketplaceSellerSettlements,
            icon: Icons.account_balance_wallet_outlined,
            selectedIcon: Icons.account_balance_wallet,
          ),
        ];

      case UserRole.applicationStaff:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.applicationStaffDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
        ];

      case UserRole.applicationAdmin:
        return const [
          NavDestinationItem(
            label: 'Dashboard',
            routePath: AppRoutes.applicationAdminDashboard,
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
          ),
          NavDestinationItem(
            label: 'Staff',
            routePath: AppRoutes.applicationAdminStaff,
            icon: Icons.manage_accounts_outlined,
            selectedIcon: Icons.manage_accounts,
          ),
          NavDestinationItem(
            label: 'Policies',
            routePath: AppRoutes.applicationAdminPolicies,
            icon: Icons.policy_outlined,
            selectedIcon: Icons.policy,
          ),
          NavDestinationItem(
            label: 'Audit Logs',
            routePath: AppRoutes.applicationAdminAuditLogs,
            icon: Icons.receipt_outlined,
            selectedIcon: Icons.receipt,
          ),
        ];
    }
  }
}
