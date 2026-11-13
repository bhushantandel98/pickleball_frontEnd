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
import 'package:pickleball_platform/features/academy/presentation/pages/academy_branches_page.dart';
import 'package:pickleball_platform/features/academy/presentation/pages/academy_coaches_page.dart';
import 'package:pickleball_platform/features/academy/presentation/pages/academy_dashboard_page.dart';
import 'package:pickleball_platform/features/academy/presentation/pages/academy_enrollments_page.dart';
import 'package:pickleball_platform/features/academy/presentation/pages/academy_programs_page.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/pages/academy_staff_attendance_page.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/pages/academy_staff_dashboard_page.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/pages/academy_staff_operations_page.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/pages/venue_partner_bookings_page.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/pages/venue_partner_calendar_page.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/pages/venue_partner_dashboard_page.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/pages/venue_partner_locations_page.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/pages/venue_staff_bookings_page.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/pages/venue_staff_dashboard_page.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/pages/venue_staff_tasks_page.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/pages/tournament_create_wizard_page.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/pages/tournament_draws_page.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/pages/tournament_organizer_dashboard_page.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/pages/tournament_staff_page.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/pages/tournament_staff_dashboard_page.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/pages/tournament_staff_operations_page.dart';
import 'package:pickleball_platform/features/referee/presentation/pages/referee_dashboard_page.dart';
import 'package:pickleball_platform/features/referee/presentation/pages/referee_scoring_page.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/pages/seller_dashboard_page.dart';
import 'package:pickleball_platform/features/marketplace_seller/presentation/pages/seller_onboarding_page.dart';
import 'package:pickleball_platform/features/coach/presentation/pages/coach_calendar_page.dart';
import 'package:pickleball_platform/features/coach/presentation/pages/coach_dashboard_page.dart';
import 'package:pickleball_platform/features/coach/presentation/pages/coach_profile_page.dart';
import 'package:pickleball_platform/features/coach/presentation/pages/personal_coaching_page.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/register_page.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/welcome_page.dart';
import 'package:pickleball_platform/features/notifications/presentation/pages/notification_center_page.dart';
import 'package:pickleball_platform/features/notifications/presentation/pages/notification_preferences_page.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/marketplace_item.dart';
import 'package:pickleball_platform/features/player/presentation/pages/booking_checkout_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/booking_confirmation_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/booking_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/academy_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/academy_enrollment_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/coach_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/coach_inquiry_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/court_availability_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/marketplace_cart_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/marketplace_catalogue_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/marketplace_checkout_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/marketplace_order_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/marketplace_orders_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/marketplace_wishlist_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/match_day_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/my_bookings_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/player_academy_coach_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/player_community_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/player_dashboard_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/product_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/tournament_confirmation_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/tournament_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/tournament_discovery_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/tournament_registration_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/venue_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/venue_discovery_page.dart';
import 'package:pickleball_platform/features/profile/presentation/pages/account_settings_page.dart';
import 'package:pickleball_platform/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:pickleball_platform/features/profile/presentation/pages/profile_page.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

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
        builder: (context, state) => const NotificationCenterPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (context, state) {
          final profile = state.extra as UserProfile?;
          return EditProfilePage(initialProfile: profile);
        },
      ),
      GoRoute(
        path: AppRoutes.accountSettings,
        builder: (context, state) => AccountSettingsPage(
          onNotifications: () =>
              context.push(AppRoutes.notificationPreferences),
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationPreferences,
        builder: (context, state) => const NotificationPreferencesPage(),
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
            builder: (context, state) => const PlayerDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.playerVenues,
            builder: (context, state) => const VenueDiscoveryPage(),
          ),
          GoRoute(
            path: AppRoutes.playerVenueDetails,
            builder: (context, state) => VenueDetailsPage(
              venueId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.playerCourtAvailability,
            builder: (context, state) => CourtAvailabilityPage(
              venueId: state.pathParameters['id'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.playerBookingCheckout,
            builder: (context, state) => BookingCheckoutPage(
              payload: state.extra as BookingSelectionPayload?,
            ),
          ),
          GoRoute(
            path: AppRoutes.playerBookingConfirmation,
            builder: (context, state) => BookingConfirmationPage(
              booking: state.extra as CourtBooking?,
            ),
          ),
          GoRoute(
            path: AppRoutes.playerAcademies,
            builder: (context, state) => const PlayerAcademyCoachPage(),
          ),
          GoRoute(
            path: AppRoutes.playerAcademyDetails,
            builder: (context, state) {
              final branchId = state.pathParameters['id'] ?? '';
              return AcademyDetailsPage(branchId: branchId);
            },
          ),
          GoRoute(
            path: AppRoutes.playerAcademyEnrollment,
            builder: (context, state) {
              final branchId = state.pathParameters['id'] ?? '';
              final batchId = state.pathParameters['batchId'] ?? '';
              final programId = state.uri.queryParameters['programId'] ?? '';
              return AcademyEnrollmentPage(
                branchId: branchId,
                programId: programId,
                batchId: batchId,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.playerCoachDetails,
            builder: (context, state) {
              final coachId = state.pathParameters['id'] ?? '';
              return CoachDetailsPage(coachId: coachId);
            },
          ),
          GoRoute(
            path: AppRoutes.playerCoachInquiry,
            builder: (context, state) {
              final coachId = state.pathParameters['id'] ?? '';
              final serviceId = state.uri.queryParameters['serviceId'];
              return CoachInquiryPage(
                coachId: coachId,
                serviceId: serviceId,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.playerBookings,
            builder: (context, state) => const MyBookingsPage(),
          ),
          GoRoute(
            path: AppRoutes.playerBookingDetails,
            builder: (context, state) {
              final bookingId = state.pathParameters['id'] ?? '';
              final initialBooking = state.extra as CourtBooking?;
              return BookingDetailsPage(
                bookingId: bookingId,
                initialBooking: initialBooking,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.playerTournaments,
            builder: (context, state) => const TournamentDiscoveryPage(),
          ),
          GoRoute(
            path: AppRoutes.playerTournamentDetails,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return TournamentDetailsPage(tournamentId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.playerTournamentRegistration,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final initialCategoryId = state.uri.queryParameters['categoryId'];
              return TournamentRegistrationPage(
                tournamentId: id,
                initialCategoryId: initialCategoryId,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.playerTournamentConfirmation,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              final reg = state.extra as TournamentRegistration?;
              return TournamentConfirmationPage(
                tournamentId: id,
                registration: reg,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.playerMatchDay,
            builder: (context, state) => const MatchDayPage(),
          ),
          GoRoute(
            path: AppRoutes.playerMarketplace,
            builder: (context, state) => const MarketplaceCataloguePage(),
          ),
          GoRoute(
            path: AppRoutes.playerProductDetails,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return ProductDetailsPage(productId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.playerMarketplaceCart,
            builder: (context, state) => const MarketplaceCartPage(),
          ),
          GoRoute(
            path: AppRoutes.playerMarketplaceWishlist,
            builder: (context, state) => const MarketplaceWishlistPage(),
          ),
          GoRoute(
            path: AppRoutes.playerMarketplaceCheckout,
            builder: (context, state) {
              final extra = state.extra;
              final directItems = extra is List<MarketplaceCartItem> ? extra : null;
              return MarketplaceCheckoutPage(directItems: directItems);
            },
          ),
          GoRoute(
            path: AppRoutes.playerMarketplaceOrders,
            builder: (context, state) => const MarketplaceOrdersPage(),
          ),
          GoRoute(
            path: AppRoutes.playerMarketplaceOrderDetails,
            builder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return MarketplaceOrderDetailsPage(orderId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.playerCommunity,
            builder: (context, state) => const PlayerCommunityPage(),
          ),

          // 2. Coach
          GoRoute(
            path: AppRoutes.coachDashboard,
            builder: (context, state) => const CoachDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.coachCalendar,
            builder: (context, state) => const CoachCalendarPage(),
          ),
          GoRoute(
            path: AppRoutes.coachPersonalCoaching,
            builder: (context, state) => const PersonalCoachingPage(),
          ),
          GoRoute(
            path: AppRoutes.coachBatches,
            builder: (context, state) => const RoutePlaceholderView(
              title: 'Assigned Batches',
              path: AppRoutes.coachBatches,
              role: UserRole.coach,
            ),
          ),
          GoRoute(
            path: AppRoutes.coachProfile,
            builder: (context, state) => const CoachProfilePage(),
          ),

          // 3. Academy
          GoRoute(
            path: AppRoutes.academyDashboard,
            builder: (context, state) => const AcademyDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.academyBranches,
            builder: (context, state) => const AcademyBranchesPage(),
          ),
          GoRoute(
            path: AppRoutes.academyPrograms,
            builder: (context, state) => const AcademyProgramsPage(),
          ),
          GoRoute(
            path: AppRoutes.academyCoaches,
            builder: (context, state) => const AcademyCoachesPage(),
          ),
          GoRoute(
            path: AppRoutes.academyEnrollments,
            builder: (context, state) => const AcademyEnrollmentsPage(),
          ),

          // 4. Academy Staff
          GoRoute(
            path: AppRoutes.academyStaffDashboard,
            builder: (context, state) => const AcademyStaffDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.academyStaffAttendance,
            builder: (context, state) => const AcademyStaffAttendancePage(),
          ),
          GoRoute(
            path: AppRoutes.academyStaffOperations,
            builder: (context, state) => const AcademyStaffOperationsPage(),
          ),

          // 5. Venue Partner
          GoRoute(
            path: AppRoutes.venuePartnerDashboard,
            builder: (context, state) => const VenuePartnerDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.venuePartnerLocations,
            builder: (context, state) => const VenuePartnerLocationsPage(),
          ),
          GoRoute(
            path: AppRoutes.venuePartnerCalendar,
            builder: (context, state) => const VenuePartnerCalendarPage(),
          ),
          GoRoute(
            path: AppRoutes.venuePartnerBookings,
            builder: (context, state) => const VenuePartnerBookingsPage(),
          ),

          // 6. Venue Staff
          GoRoute(
            path: AppRoutes.venueStaffDashboard,
            builder: (context, state) => const VenueStaffDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.venueStaffBookings,
            builder: (context, state) => const VenueStaffBookingsPage(),
          ),
          GoRoute(
            path: AppRoutes.venueStaffTasks,
            builder: (context, state) => const VenueStaffTasksPage(),
          ),

          // 7. Tournament Organizer
          GoRoute(
            path: AppRoutes.tournamentOrganizerDashboard,
            builder: (context, state) =>
                const TournamentOrganizerDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.tournamentOrganizerCreate,
            builder: (context, state) => const TournamentCreateWizardPage(),
          ),
          GoRoute(
            path: AppRoutes.tournamentOrganizerDraws,
            builder: (context, state) => TournamentDrawsPage(
              tournamentId: state.pathParameters['id'],
            ),
          ),
          GoRoute(
            path: AppRoutes.tournamentOrganizerStaff,
            builder: (context, state) => TournamentStaffPage(
              tournamentId: state.pathParameters['id'],
            ),
          ),

          // 8. Tournament Staff
          GoRoute(
            path: AppRoutes.tournamentStaffDashboard,
            builder: (context, state) => const TournamentStaffDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.tournamentStaffOperations,
            builder: (context, state) => const TournamentStaffOperationsPage(),
          ),

          // 9. Referee
          GoRoute(
            path: AppRoutes.refereeDashboard,
            builder: (context, state) => const RefereeDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.refereeScoring,
            builder: (context, state) => RefereeScoringPage(
              matchId: state.pathParameters['id'],
            ),
          ),

          // 10. Marketplace Seller
          GoRoute(
            path: AppRoutes.marketplaceSellerDashboard,
            builder: (context, state) => const SellerDashboardPage(),
          ),
          GoRoute(
            path: AppRoutes.marketplaceSellerOnboarding,
            builder: (context, state) => const SellerOnboardingPage(),
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
