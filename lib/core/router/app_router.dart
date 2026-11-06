import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/router/route_guards.dart';
import 'package:pickleball_platform/core/widgets/navigation/app_navigation_shell.dart';
import 'package:pickleball_platform/core/widgets/navigation/route_placeholder_view.dart';
import 'package:pickleball_platform/features/role_selection/presentation/pages/role_selection_page.dart';
import 'package:pickleball_platform/core/widgets/state_views/account_suspended_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/permission_denied_view.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/forgot_password_page.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/login_page.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/register_page.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/welcome_page.dart';

/// Central factory creating the declarative [GoRouter] instance for all 12 platform roles.
GoRouter createAppRouter({
  required SessionCubit sessionCubit,
  String initialLocation = AppRoutes.root,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: sessionCubit.refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      return CompositeRouteGuard.evaluateAll(
        sessionCubit.state,
        state.uri.path,
      );
    },
    errorBuilder: (BuildContext context, GoRouterState state) {
      return Scaffold(
        body: EmptyStateView(
          title: 'Page Not Found',
          message: 'The requested route "${state.uri.path}" does not exist on this platform.',
          actionLabel: 'Return Home',
          onAction: () => context.go(AppRoutes.root),
        ),
      );
    },
    routes: [
      // --- Top-level Non-Shell Routes ---
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const RoutePlaceholderView(
          title: 'Root',
          path: AppRoutes.root,
        ),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.loginSuccess,
        builder: (context, state) => const RoutePlaceholderView(
          title: 'Login Successful',
          path: AppRoutes.loginSuccess,
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: AppRoutes.roleSelection,
        builder: (context, state) {
          final bypass = state.uri.queryParameters['bypass'] == 'true' ||
              state.uri.queryParameters['switchRole'] == 'true';
          return RoleSelectionPage(bypassAutoRedirect: bypass);
        },
      ),
      GoRoute(
        path: AppRoutes.accountSuspended,
        builder: (context, state) => const AccountSuspendedView(),
      ),
      GoRoute(
        path: AppRoutes.permissionDenied,
        builder: (context, state) => const PermissionDeniedView(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const RoutePlaceholderView(
          title: 'Notification Center',
          path: AppRoutes.notifications,
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const RoutePlaceholderView(
          title: 'User Profile',
          path: AppRoutes.profile,
        ),
      ),

      // --- Public Unauthenticated Routes (FSD §3.1) ---
      GoRoute(
        path: AppRoutes.publicTournament,
        builder: (context, state) => RoutePlaceholderView(
          title: 'Tournament Live Schedule',
          path: state.uri.path,
          params: state.pathParameters,
        ),
      ),
      GoRoute(
        path: AppRoutes.publicRankings,
        builder: (context, state) => RoutePlaceholderView(
          title: 'Public Platform Rankings',
          path: state.uri.path,
        ),
      ),

      // --- Authenticated Role Shell Routes ---
      ShellRoute(
        builder: (context, state, child) {
          return AppNavigationShell(
            state: state,
            child: child,
          );
        },
        routes: [
          // 1. Player
          GoRoute(
            path: AppRoutes.playerDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Player Dashboard',
              path: AppRoutes.playerDashboard,
              role: UserRole.player,
            ),
          ),
          GoRoute(
            path: AppRoutes.playerVenues,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Discover Courts & Venues',
              path: AppRoutes.playerVenues,
              role: UserRole.player,
            ),
          ),
          GoRoute(
            path: AppRoutes.playerAcademies,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Discover Academies & Coaches',
              path: AppRoutes.playerAcademies,
              role: UserRole.player,
            ),
          ),
          GoRoute(
            path: AppRoutes.playerBookings,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'My Bookings',
              path: AppRoutes.playerBookings,
              role: UserRole.player,
            ),
          ),
          GoRoute(
            path: AppRoutes.playerTournaments,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Tournaments',
              path: AppRoutes.playerTournaments,
              role: UserRole.player,
            ),
          ),
          GoRoute(
            path: AppRoutes.playerMatchDay,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Match Day Schedule',
              path: AppRoutes.playerMatchDay,
              role: UserRole.player,
            ),
          ),
          GoRoute(
            path: AppRoutes.playerMarketplace,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Marketplace Shop',
              path: AppRoutes.playerMarketplace,
              role: UserRole.player,
            ),
          ),

          // 2. Coach
          GoRoute(
            path: AppRoutes.coachDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Coach Dashboard',
              path: AppRoutes.coachDashboard,
              role: UserRole.coach,
            ),
          ),
          GoRoute(
            path: AppRoutes.coachBatches,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Assigned Batches',
              path: AppRoutes.coachBatches,
              role: UserRole.coach,
            ),
          ),

          // 3. Academy
          GoRoute(
            path: AppRoutes.academyDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Academy Dashboard',
              path: AppRoutes.academyDashboard,
              role: UserRole.academy,
            ),
          ),
          GoRoute(
            path: AppRoutes.academyBranches,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Branch Facilities',
              path: AppRoutes.academyBranches,
              role: UserRole.academy,
            ),
          ),
          GoRoute(
            path: AppRoutes.academyPrograms,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Coaching Programs',
              path: AppRoutes.academyPrograms,
              role: UserRole.academy,
            ),
          ),
          GoRoute(
            path: AppRoutes.academyCoaches,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Coach Staff Directory',
              path: AppRoutes.academyCoaches,
              role: UserRole.academy,
            ),
          ),
          GoRoute(
            path: AppRoutes.academyEnrollments,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Student Enrollments',
              path: AppRoutes.academyEnrollments,
              role: UserRole.academy,
            ),
          ),

          // 4. Academy Staff
          GoRoute(
            path: AppRoutes.academyStaffDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Academy Staff Operations',
              path: AppRoutes.academyStaffDashboard,
              role: UserRole.academyStaff,
            ),
          ),

          // 5. Venue Partner
          GoRoute(
            path: AppRoutes.venuePartnerDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Venue Partner Dashboard',
              path: AppRoutes.venuePartnerDashboard,
              role: UserRole.venuePartner,
            ),
          ),
          GoRoute(
            path: AppRoutes.venuePartnerLocations,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Locations & Courts',
              path: AppRoutes.venuePartnerLocations,
              role: UserRole.venuePartner,
            ),
          ),
          GoRoute(
            path: AppRoutes.venuePartnerCalendar,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Court Booking Calendar',
              path: AppRoutes.venuePartnerCalendar,
              role: UserRole.venuePartner,
            ),
          ),
          GoRoute(
            path: AppRoutes.venuePartnerBookings,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Booking Requests & Payments',
              path: AppRoutes.venuePartnerBookings,
              role: UserRole.venuePartner,
            ),
          ),

          // 6. Venue Staff
          GoRoute(
            path: AppRoutes.venueStaffDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Venue Staff Daily Operations',
              path: AppRoutes.venueStaffDashboard,
              role: UserRole.venueStaff,
            ),
          ),

          // 7. Tournament Organizer
          GoRoute(
            path: AppRoutes.tournamentOrganizerDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Tournament Organizer Dashboard',
              path: AppRoutes.tournamentOrganizerDashboard,
              role: UserRole.tournamentOrganizer,
            ),
          ),
          GoRoute(
            path: AppRoutes.tournamentOrganizerCreate,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Create Tournament Wizard',
              path: AppRoutes.tournamentOrganizerCreate,
              role: UserRole.tournamentOrganizer,
            ),
          ),
          GoRoute(
            path: AppRoutes.tournamentOrganizerDraws,
            builder: (context, state) => RoutePlaceholderView(
              title: 'Tournament Draws & Seeding',
              path: state.uri.path,
              role: UserRole.tournamentOrganizer,
              params: state.pathParameters,
            ),
          ),
          GoRoute(
            path: AppRoutes.tournamentOrganizerStaff,
            builder: (context, state) => RoutePlaceholderView(
              title: 'Staff Delegation & Referee Assignment',
              path: state.uri.path,
              role: UserRole.tournamentOrganizer,
              params: state.pathParameters,
            ),
          ),

          // 8. Tournament Staff
          GoRoute(
            path: AppRoutes.tournamentStaffDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Tournament Match Monitoring',
              path: AppRoutes.tournamentStaffDashboard,
              role: UserRole.tournamentStaff,
            ),
          ),

          // 9. Referee
          GoRoute(
            path: AppRoutes.refereeDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Assigned Matches',
              path: AppRoutes.refereeDashboard,
              role: UserRole.referee,
            ),
          ),
          GoRoute(
            path: AppRoutes.refereeScoring,
            builder: (context, state) => RoutePlaceholderView(
              title: 'Match Live Scoring Pad',
              path: state.uri.path,
              role: UserRole.referee,
              params: state.pathParameters,
            ),
          ),

          // 10. Marketplace Seller
          GoRoute(
            path: AppRoutes.marketplaceSellerDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Seller Dashboard',
              path: AppRoutes.marketplaceSellerDashboard,
              role: UserRole.marketplaceSeller,
            ),
          ),
          GoRoute(
            path: AppRoutes.marketplaceSellerOnboarding,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Seller KYC Onboarding',
              path: AppRoutes.marketplaceSellerOnboarding,
              role: UserRole.marketplaceSeller,
            ),
          ),
          GoRoute(
            path: AppRoutes.marketplaceSellerProducts,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Product Creator',
              path: AppRoutes.marketplaceSellerProducts,
              role: UserRole.marketplaceSeller,
            ),
          ),
          GoRoute(
            path: AppRoutes.marketplaceSellerOrders,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Orders Fulfillment Pipeline',
              path: AppRoutes.marketplaceSellerOrders,
              role: UserRole.marketplaceSeller,
            ),
          ),
          GoRoute(
            path: AppRoutes.marketplaceSellerSettlements,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Settlements & Commission Statements',
              path: AppRoutes.marketplaceSellerSettlements,
              role: UserRole.marketplaceSeller,
            ),
          ),

          // 11. Application Staff
          GoRoute(
            path: AppRoutes.applicationStaffDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Application Staff Review Queue',
              path: AppRoutes.applicationStaffDashboard,
              role: UserRole.applicationStaff,
            ),
          ),

          // 12. Application Admin
          GoRoute(
            path: AppRoutes.applicationAdminDashboard,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Platform Macro Dashboard',
              path: AppRoutes.applicationAdminDashboard,
              role: UserRole.applicationAdmin,
            ),
          ),
          GoRoute(
            path: AppRoutes.applicationAdminStaff,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Staff Management & Capability Scopes',
              path: AppRoutes.applicationAdminStaff,
              role: UserRole.applicationAdmin,
            ),
          ),
          GoRoute(
            path: AppRoutes.applicationAdminPolicies,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Platform Commissions & Policies',
              path: AppRoutes.applicationAdminPolicies,
              role: UserRole.applicationAdmin,
            ),
          ),
          GoRoute(
            path: AppRoutes.applicationAdminAuditLogs,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Immutable Audit Log Viewer',
              path: AppRoutes.applicationAdminAuditLogs,
              role: UserRole.applicationAdmin,
            ),
          ),
        ],
      ),
    ],
  );
}
