/// Standardized route path constants for the Pickleball Multi-Role Platform.
///
/// Follows FSD §3.1, Architecture Proposal §9, and MODULE_INDEX.md.
abstract final class AppRoutes {
  // --- Root & Entry ---
  static const String root = '/';

  // --- Identity & Auth (Public / Visitor) ---
  static const String welcome = '/auth/welcome';
  static const String login = '/auth/login';
  static const String loginSuccess = '/auth/login-success';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';

  // --- Shared / Gated System Screens ---
  static const String roleSelection = '/role-selection';
  static const String accountStatus = '/account-status';
  static const String accountSuspended = '/account-suspended';
  static const String permissionDenied = '/permission-denied';
  static const String notifications = '/notifications';
  static const String notificationPreferences = '/profile/settings/notifications';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String accountSettings = '/profile/settings';

  // --- Public Unauthenticated Routes (FSD §3.1) ---
  static const String publicTournament = '/public/tournaments/:id';
  static String publicTournamentPath(String id) => '/public/tournaments/$id';
  static const String publicRankings = '/public/rankings';

  // --- Role 1: Player ---
  static const String player = '/player';
  static const String playerDashboard = '/player/dashboard';
  static const String playerVenues = '/player/discovery/venues';
  static const String playerVenueDetails = '/player/discovery/venues/:id';
  static String playerVenueDetailsPath(String id) => '/player/discovery/venues/$id';
  static const String playerCourtAvailability = '/player/discovery/venues/:id/availability';
  static String playerCourtAvailabilityPath(String id) => '/player/discovery/venues/$id/availability';
  static const String playerAcademies = '/player/discovery/academies';
  static const String playerAcademyDetails = '/player/discovery/academies/:id';
  static String playerAcademyDetailsPath(String id) => '/player/discovery/academies/$id';
  static const String playerAcademyEnrollment =
      '/player/discovery/academies/:id/enroll/:batchId';
  static String playerAcademyEnrollmentPath(String id, String batchId,
          {String? programId}) =>
      '/player/discovery/academies/$id/enroll/$batchId${programId != null ? '?programId=$programId' : ''}';
  static const String playerCoachDetails = '/player/discovery/coaches/:id';
  static String playerCoachDetailsPath(String id) =>
      '/player/discovery/coaches/$id';
  static const String playerCoachInquiry =
      '/player/discovery/coaches/:id/inquiry';
  static String playerCoachInquiryPath(String id, {String? serviceId}) =>
      '/player/discovery/coaches/$id/inquiry${serviceId != null ? '?serviceId=$serviceId' : ''}';
  static const String playerBookings = '/player/bookings';
  static const String playerBookingDetails = '/player/bookings/:id';
  static String playerBookingDetailsPath(String id) => '/player/bookings/$id';
  static const String playerBookingCheckout = '/player/bookings/checkout';
  static String playerBookingCheckoutPath() => '/player/bookings/checkout';
  static const String playerBookingConfirmation = '/player/bookings/confirmation';
  static String playerBookingConfirmationPath() => '/player/bookings/confirmation';
  static const String playerTournaments = '/player/tournaments';
  static const String playerTournamentDetails = '/player/tournaments/:id';
  static String playerTournamentDetailsPath(String id) => '/player/tournaments/$id';
  static const String playerTournamentRegistration = '/player/tournaments/:id/register';
  static String playerTournamentRegistrationPath(String id) => '/player/tournaments/$id/register';
  static const String playerTournamentConfirmation = '/player/tournaments/:id/confirmation';
  static String playerTournamentConfirmationPath(String id) => '/player/tournaments/$id/confirmation';
  static const String playerMatchDay = '/player/match-day';
  static const String playerMarketplace = '/player/marketplace';
  static const String playerProductDetails = '/player/marketplace/products/:id';
  static String playerProductDetailsPath(String id) => '/player/marketplace/products/$id';
  static const String playerMarketplaceCart = '/player/marketplace/cart';
  static const String playerMarketplaceWishlist = '/player/marketplace/wishlist';
  static const String playerMarketplaceCheckout = '/player/marketplace/checkout';
  static const String playerMarketplaceOrders = '/player/marketplace/orders';
  static const String playerMarketplaceOrderDetails = '/player/marketplace/orders/:id';
  static String playerMarketplaceOrderDetailsPath(String id) => '/player/marketplace/orders/$id';
  static const String playerCommunity = '/player/community';

  // --- Role 2: Coach ---
  static const String coach = '/coach';
  static const String coachDashboard = '/coach/dashboard';
  static const String coachBatches = '/coach/batches';
  static const String coachProfile = '/coach/profile';

  // --- Role 3: Academy ---
  static const String academy = '/academy';
  static const String academyDashboard = '/academy/dashboard';
  static const String academyBranches = '/academy/branches';
  static const String academyPrograms = '/academy/programs';
  static const String academyCoaches = '/academy/coaches';
  static const String academyEnrollments = '/academy/enrollments';

  // --- Role 4: Academy Staff ---
  static const String academyStaff = '/academy-staff';
  static const String academyStaffDashboard = '/academy-staff/dashboard';

  // --- Role 5: Venue Partner ---
  static const String venuePartner = '/venue-partner';
  static const String venuePartnerDashboard = '/venue-partner/dashboard';
  static const String venuePartnerLocations = '/venue-partner/locations';
  static const String venuePartnerCalendar = '/venue-partner/calendar';
  static const String venuePartnerBookings = '/venue-partner/bookings';

  // --- Role 6: Venue Staff ---
  static const String venueStaff = '/venue-staff';
  static const String venueStaffDashboard = '/venue-staff/dashboard';

  // --- Role 7: Tournament Organizer ---
  static const String tournamentOrganizer = '/tournament-organizer';
  static const String tournamentOrganizerDashboard =
      '/tournament-organizer/dashboard';
  static const String tournamentOrganizerCreate =
      '/tournament-organizer/create';
  static const String tournamentOrganizerDraws =
      '/tournament-organizer/:id/draws';
  static const String tournamentOrganizerStaff =
      '/tournament-organizer/:id/staff';

  // --- Role 8: Tournament Staff ---
  static const String tournamentStaff = '/tournament-staff';
  static const String tournamentStaffDashboard =
      '/tournament-staff/dashboard';

  // --- Role 9: Referee ---
  static const String referee = '/referee';
  static const String refereeDashboard = '/referee/dashboard';
  static const String refereeScoring = '/referee/match/:id/scoring';

  // --- Role 10: Marketplace Seller ---
  static const String marketplaceSeller = '/marketplace-seller';
  static const String marketplaceSellerDashboard =
      '/marketplace-seller/dashboard';
  static const String marketplaceSellerOnboarding =
      '/marketplace-seller/onboarding';
  static const String marketplaceSellerProducts =
      '/marketplace-seller/products/create';
  static const String marketplaceSellerOrders =
      '/marketplace-seller/orders';
  static const String marketplaceSellerSettlements =
      '/marketplace-seller/settlements';

  // --- Role 11: Application Staff ---
  static const String applicationStaff = '/application-staff';
  static const String applicationStaffDashboard =
      '/application-staff/dashboard';

  // --- Role 12: Application Admin ---
  static const String applicationAdmin = '/application-admin';
  static const String applicationAdminDashboard =
      '/application-admin/dashboard';
  static const String applicationAdminStaff =
      '/application-admin/staff-management';
  static const String applicationAdminPolicies =
      '/application-admin/policies';
  static const String applicationAdminAuditLogs =
      '/application-admin/audit-logs';

  /// Whether the specified [path] is publicly accessible without authentication.
  static bool isPublic(String path) {
    if (path.startsWith('/public/')) return true;
    if (path == welcome ||
        path == login ||
        path == loginSuccess ||
        path == register ||
        path == forgotPassword) {
      return true;
    }
    return false;
  }

  /// Whether the specified [path] is an authentication entry screen.
  static bool isAuthEntry(String path) {
    return path == welcome ||
        path == login ||
        path == register ||
        path == forgotPassword;
  }
}
