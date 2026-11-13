import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/mock/data/mock_data.dart';
import 'package:pickleball_platform/core/mock/mock_config.dart';
import 'package:pickleball_platform/core/mock/mock_network_harness.dart';
import 'package:pickleball_platform/features/identity/data/datasources/mock_user_profile_data_source.dart';
import 'package:pickleball_platform/features/identity/data/datasources/user_profile_data_source.dart';
import 'package:pickleball_platform/features/identity/data/repositories/mock_auth_repository.dart';
import 'package:pickleball_platform/features/identity/data/repositories/mock_user_profile_repository.dart';
import 'package:pickleball_platform/features/identity/data/repositories/remote_auth_repository.dart';
import 'package:pickleball_platform/features/identity/data/repositories/remote_user_profile_repository.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/auth_repository.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/forgot_password_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/login_cubit.dart';
import 'package:pickleball_platform/features/identity/presentation/bloc/registration_cubit.dart';
import 'package:pickleball_platform/features/notifications/data/repositories/mock_notification_preferences_repository.dart';
import 'package:pickleball_platform/features/notifications/data/repositories/mock_notification_repository.dart';
import 'package:pickleball_platform/features/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:pickleball_platform/features/notifications/domain/repositories/notification_repository.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notification_preferences_cubit.dart';
import 'package:pickleball_platform/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_booking_repository.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_community_repository.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_marketplace_repository.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_match_day_repository.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_player_dashboard_repository.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_tournament_repository.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_venue_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/booking_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/marketplace_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/match_day_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/player_dashboard_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/tournament_repository.dart';
import 'package:pickleball_platform/features/academy/data/repositories/mock_academy_repository.dart';
import 'package:pickleball_platform/features/academy/domain/repositories/academy_repository.dart';
import 'package:pickleball_platform/features/academy/presentation/bloc/academy_cubit.dart';
import 'package:pickleball_platform/features/academy_staff/data/repositories/mock_academy_staff_repository.dart';
import 'package:pickleball_platform/features/academy_staff/domain/repositories/academy_staff_repository.dart';
import 'package:pickleball_platform/features/academy_staff/presentation/cubit/academy_staff_cubit.dart';
import 'package:pickleball_platform/features/venue_partner/data/repositories/mock_venue_partner_repository.dart';
import 'package:pickleball_platform/features/venue_partner/domain/repositories/venue_partner_repository.dart';
import 'package:pickleball_platform/features/venue_partner/presentation/bloc/venue_partner_cubit.dart';
import 'package:pickleball_platform/features/venue_staff/data/repositories/mock_venue_staff_repository.dart';
import 'package:pickleball_platform/features/venue_staff/domain/repositories/venue_staff_repository.dart';
import 'package:pickleball_platform/features/venue_staff/presentation/cubit/venue_staff_cubit.dart';
import 'package:pickleball_platform/features/tournament_organizer/data/repositories/mock_tournament_organizer_repository.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/repositories/tournament_organizer_repository.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_cubit.dart';
import 'package:pickleball_platform/features/tournament_staff/data/repositories/mock_tournament_staff_repository.dart';
import 'package:pickleball_platform/features/tournament_staff/domain/repositories/tournament_staff_repository.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/cubit/tournament_staff_cubit.dart';
import 'package:pickleball_platform/features/referee/data/repositories/mock_referee_repository.dart';
import 'package:pickleball_platform/features/referee/domain/repositories/referee_repository.dart';
import 'package:pickleball_platform/features/referee/presentation/bloc/referee_cubit.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_coach_calendar_repository.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_coach_dashboard_repository.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_coach_profile_repository.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_personal_coaching_repository.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/coach_calendar_repository.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/coach_dashboard_repository.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/coach_profile_repository.dart';
import 'package:pickleball_platform/features/coach/domain/repositories/personal_coaching_repository.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_calendar_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_dashboard_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_profile_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/personal_coaching_cubit.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_enrollment_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_checkout_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_inquiry_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/community_feed_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_game_poll_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_post_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_cart_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_catalogue_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_orders_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/marketplace_wishlist_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/match_day_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_bookings_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_coaching_requests_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/player_dashboard_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/post_comments_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_discovery_cubit.dart';
import 'package:pickleball_platform/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:pickleball_platform/features/role_selection/data/repositories/mock_role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/data/repositories/remote_role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/domain/repositories/role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/presentation/cubit/role_selection_cubit.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Compile-time & runtime flag for mock repository registration (ADR-015).
/// In release mode, this evaluates to `false` and mock bindings are dead-code eliminated.
const bool kUseMockRepositories =
    !kReleaseMode && bool.fromEnvironment('USE_MOCKS', defaultValue: true);

/// Initialize foundational dependencies and feature service locators.
Future<void> initServiceLocator() async {
  // --- ADR-015: Strict Production Mock Isolation ---
  // Registers storage, data sources, and repositories into GetIt
  if (kUseMockRepositories) {
    initMockServiceLocator();
  } else {
    initRemoteServiceLocator();
  }

  // --- Core Session Singleton (depends on registered RolePreferenceStorage) ---
  sl.registerLazySingleton<SessionCubit>(
    () => SessionCubit(preferenceStorage: sl<RolePreferenceStorage>()),
  );

  // --- Identity & Auth Cubits ---
  sl.registerFactory<LoginCubit>(
    () => LoginCubit(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<RegistrationCubit>(
    () => RegistrationCubit(authRepository: sl<AuthRepository>()),
  );
  sl.registerFactory<ForgotPasswordCubit>(
    () => ForgotPasswordCubit(authRepository: sl<AuthRepository>()),
  );

  // --- Role Selection Cubit ---
  sl.registerFactory<RoleSelectionCubit>(
    () => RoleSelectionCubit(
      repository: sl<RoleContextRepository>(),
      preferenceStorage: sl<RolePreferenceStorage>(),
    ),
  );

  // --- Profile Cubit ---
  sl.registerFactory<ProfileCubit>(
    () => ProfileCubit(repository: sl<UserProfileRepository>()),
  );

  // --- Notification Preferences Cubit ---
  sl.registerFactory<NotificationPreferencesCubit>(
    () => NotificationPreferencesCubit(
      repository: sl<NotificationPreferencesRepository>(),
    ),
  );

  // --- Notifications Centre Cubit ---
  sl.registerFactory<NotificationsCubit>(
    () => NotificationsCubit(
      repository: sl<NotificationRepository>(),
    ),
  );

  // --- Player Dashboard Cubit ---
  sl.registerFactory<PlayerDashboardCubit>(
    () => PlayerDashboardCubit(
      repository: sl<PlayerDashboardRepository>(),
    ),
  );

  // --- Venue Discovery Cubit ---
  sl.registerFactory<VenueDiscoveryCubit>(
    () => VenueDiscoveryCubit(
      repository: sl<VenueRepository>(),
    ),
  );

  // --- Booking Checkout Cubit ---
  sl.registerFactory<BookingCheckoutCubit>(
    () => BookingCheckoutCubit(
      repository: sl<BookingRepository>(),
    ),
  );

  // --- My Bookings Cubit ---
  sl.registerFactory<MyBookingsCubit>(
    () => MyBookingsCubit(
      repository: sl<BookingRepository>(),
    ),
  );

  // --- Booking Details Cubit ---
  sl.registerFactory<BookingDetailsCubit>(
    () => BookingDetailsCubit(
      repository: sl<BookingRepository>(),
    ),
  );

  // --- Match Day Cubit ---
  sl.registerFactory<MatchDayCubit>(
    () => MatchDayCubit(
      repository: sl<MatchDayRepository>(),
    ),
  );

  // --- Tournament Discovery Cubit ---
  sl.registerFactory<TournamentDiscoveryCubit>(
    () => TournamentDiscoveryCubit(
      repository: sl<TournamentRepository>(),
    ),
  );

  // --- Marketplace Catalogue Cubit ---
  sl.registerFactory<MarketplaceCatalogueCubit>(
    () => MarketplaceCatalogueCubit(sl<MarketplaceRepository>()),
  );

  // --- Marketplace Cart Cubit ---
  sl.registerFactory<MarketplaceCartCubit>(
    () => MarketplaceCartCubit(sl<MarketplaceRepository>()),
  );

  // --- Marketplace Wishlist Cubit ---
  sl.registerFactory<MarketplaceWishlistCubit>(
    () => MarketplaceWishlistCubit(sl<MarketplaceRepository>()),
  );

  // --- Marketplace Orders Cubit ---
  sl.registerFactory<MarketplaceOrdersCubit>(
    () => MarketplaceOrdersCubit(sl<MarketplaceRepository>()),
  );

  // --- Academy Discovery Cubit ---
  sl.registerFactory<AcademyDiscoveryCubit>(
    () => AcademyDiscoveryCubit(sl<CoachingAcademyRepository>()),
  );

  // --- Academy Enrollment Cubit ---
  sl.registerFactory<AcademyEnrollmentCubit>(
    () => AcademyEnrollmentCubit(
      sl<CoachingAcademyRepository>(),
      userProfileRepository:
          sl.isRegistered<UserProfileRepository>() ? sl<UserProfileRepository>() : null,
      sessionCubit:
          sl.isRegistered<SessionCubit>() ? sl<SessionCubit>() : null,
    ),
  );

  // --- Coach Discovery Cubit ---
  sl.registerFactory<CoachDiscoveryCubit>(
    () => CoachDiscoveryCubit(sl<CoachingAcademyRepository>()),
  );

  // --- Coach Inquiry Cubit ---
  sl.registerFactory<CoachInquiryCubit>(
    () => CoachInquiryCubit(
      sl<CoachingAcademyRepository>(),
      userProfileRepository:
          sl.isRegistered<UserProfileRepository>() ? sl<UserProfileRepository>() : null,
      sessionCubit:
          sl.isRegistered<SessionCubit>() ? sl<SessionCubit>() : null,
    ),
  );

  // --- My Coaching Requests Cubit ---
  sl.registerFactory<MyCoachingRequestsCubit>(
    () => MyCoachingRequestsCubit(sl<CoachingAcademyRepository>()),
  );

  // --- Community Feed Cubit ---
  sl.registerFactory<CommunityFeedCubit>(
    () => CommunityFeedCubit(
      repository: sl<CommunityRepository>(),
      currentUserId: sl.isRegistered<SessionCubit>() &&
              sl<SessionCubit>().state.userId != null
          ? sl<SessionCubit>().state.userId!
          : MockData.playerUser.id,
    ),
  );

  // --- Create Post Cubit ---
  sl.registerFactory<CreatePostCubit>(
    () => CreatePostCubit(repository: sl<CommunityRepository>()),
  );

  // --- Create Game Poll Cubit ---
  sl.registerFactory<CreateGamePollCubit>(
    () => CreateGamePollCubit(
      communityRepository: sl<CommunityRepository>(),
      venueRepository: sl<VenueRepository>(),
    ),
  );

  // --- Post Comments Cubit ---
  sl.registerFactory<PostCommentsCubit>(
    () => PostCommentsCubit(repository: sl<CommunityRepository>()),
  );

  // --- Coach Dashboard Cubit ---
  sl.registerFactory<CoachDashboardCubit>(
    () => CoachDashboardCubit(repository: sl<CoachDashboardRepository>()),
  );

  // --- Coach Profile Cubit ---
  sl.registerFactory<CoachProfileCubit>(
    () => CoachProfileCubit(repository: sl<CoachProfileRepository>()),
  );

  // --- Coach Calendar Cubit ---
  sl.registerFactory<CoachCalendarCubit>(
    () => CoachCalendarCubit(repository: sl<CoachCalendarRepository>()),
  );

  // --- Coach Personal Coaching Cubit ---
  sl.registerFactory<PersonalCoachingCubit>(
    () => PersonalCoachingCubit(repository: sl<PersonalCoachingRepository>()),
  );

  // --- Academy Cubit ---
  sl.registerFactory<AcademyCubit>(
    () => AcademyCubit(repository: sl<AcademyRepository>()),
  );

  // --- Academy Staff Cubit ---
  sl.registerFactory<AcademyStaffCubit>(
    () => AcademyStaffCubit(repository: sl<AcademyStaffRepository>()),
  );

  // --- Venue Partner Cubit ---
  sl.registerFactory<VenuePartnerCubit>(
    () => VenuePartnerCubit(repository: sl<VenuePartnerRepository>()),
  );

  // --- Venue Staff Cubit ---
  sl.registerFactory<VenueStaffCubit>(
    () => VenueStaffCubit(repository: sl<VenueStaffRepository>()),
  );

  // --- Tournament Organizer Cubit ---
  sl.registerFactory<TournamentOrganizerCubit>(
    () => TournamentOrganizerCubit(
      repository: sl<TournamentOrganizerRepository>(),
    ),
  );

  // --- Tournament Staff Cubit ---
  sl.registerFactory<TournamentStaffCubit>(
    () => TournamentStaffCubit(
      repository: sl<TournamentStaffRepository>(),
    ),
  );

  // --- Referee Cubit ---
  sl.registerFactory<RefereeCubit>(
    () => RefereeCubit(
      repository: sl<RefereeRepository>(),
    ),
  );
}

/// Registers mock dependencies, data sources, and repositories for development/testing.
///
/// Strictly guarded against invocation in release mode (ADR-015).
void initMockServiceLocator() {
  assert(!kReleaseMode, 'initMockServiceLocator must NEVER be called in release builds (ADR-015)');
  if (kReleaseMode) {
    throw UnsupportedError('Mock service locator cannot be initialized in release mode');
  }

  // In-memory mock storage (never registered in release mode)
  sl.registerLazySingleton<RolePreferenceStorage>(
    () => MockRolePreferenceStorage(),
  );

  // Network simulation harness & config singletons
  sl.registerLazySingleton<MockConfig>(() => MockConfig.instance);
  sl.registerLazySingleton<MockNetworkHarness>(
    () => MockNetworkHarness(config: sl<MockConfig>()),
  );

  // Exemplary User Profile slice
  sl.registerLazySingleton<UserProfileDataSource>(
    () => MockUserProfileDataSource(harness: sl<MockNetworkHarness>()),
  );
  sl.registerLazySingleton<UserProfileRepository>(
    () => MockUserProfileRepository(dataSource: sl<UserProfileDataSource>()),
  );

  // Identity & Auth Repository
  sl.registerLazySingleton<AuthRepository>(
    () => MockAuthRepository(harness: sl<MockNetworkHarness>()),
  );

  // Multi-Role Context Repository
  sl.registerLazySingleton<RoleContextRepository>(
    () => MockRoleContextRepository(
      harness: sl<MockNetworkHarness>(),
      preferenceStorage: sl<RolePreferenceStorage>(),
    ),
  );

  // Notification Preferences Repository
  sl.registerLazySingleton<NotificationPreferencesRepository>(
    () => MockNotificationPreferencesRepository(),
  );

  // Notification Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => MockNotificationRepository(),
  );

  // Player Dashboard Repository
  sl.registerLazySingleton<PlayerDashboardRepository>(
    () => const MockPlayerDashboardRepository(),
  );

  // Venue Repository
  sl.registerLazySingleton<VenueRepository>(
    () => const MockVenueRepository(),
  );

  // Booking Repository
  sl.registerLazySingleton<BookingRepository>(
    () => MockBookingRepository.withDefaultBookings(),
  );

  // Match Day Repository
  sl.registerLazySingleton<MatchDayRepository>(
    () => MockMatchDayRepository(),
  );

  // Tournament Repository
  sl.registerLazySingleton<TournamentRepository>(
    () => MockTournamentRepository(),
  );

  // Marketplace Repository
  sl.registerLazySingleton<MarketplaceRepository>(
    () => MockMarketplaceRepository(),
  );

  // Coaching & Academy Repository
  sl.registerLazySingleton<CoachingAcademyRepository>(
    () => MockCoachingAcademyRepository(),
  );

  // Community Repository
  sl.registerLazySingleton<CommunityRepository>(
    () => MockCommunityRepository(),
  );

  // Coach Dashboard Repository
  sl.registerLazySingleton<CoachDashboardRepository>(
    () => const MockCoachDashboardRepository(),
  );

  // Coach Profile Repository
  sl.registerLazySingleton<CoachProfileRepository>(
    () => MockCoachProfileRepository(),
  );

  // Coach Calendar Repository
  sl.registerLazySingleton<CoachCalendarRepository>(
    () => MockCoachCalendarRepository(),
  );

  // Coach Personal Coaching Repository
  sl.registerLazySingleton<PersonalCoachingRepository>(
    () => MockPersonalCoachingRepository(),
  );

  // Academy Repository
  sl.registerLazySingleton<AcademyRepository>(
    () => MockAcademyRepository(),
  );

  // Academy Staff Repository
  sl.registerLazySingleton<AcademyStaffRepository>(
    () => MockAcademyStaffRepository(),
  );

  // Venue Partner Repository
  sl.registerLazySingleton<VenuePartnerRepository>(
    () => MockVenuePartnerRepository(),
  );

  // Venue Staff Repository
  sl.registerLazySingleton<VenueStaffRepository>(
    () => MockVenueStaffRepository(),
  );

  // Tournament Organizer Repository
  sl.registerLazySingleton<TournamentOrganizerRepository>(
    () => MockTournamentOrganizerRepository(),
  );

  // Tournament Staff Repository
  sl.registerLazySingleton<TournamentStaffRepository>(
    () => MockTournamentStaffRepository(),
  );

  // Referee Repository
  sl.registerLazySingleton<RefereeRepository>(
    () => MockRefereeRepository(),
  );
}

/// Registers real remote API dependencies, Dio clients, and production repositories.
void initRemoteServiceLocator() {
  // Production storage implementation backed by SharedPreferences
  sl.registerLazySingleton<RolePreferenceStorage>(
    () => const SharedPrefsRolePreferenceStorage(),
  );

  // Real remote repositories will connect to live backend endpoints in Phase 1+.
  sl.registerLazySingleton<UserProfileRepository>(
    () => const RemoteUserProfileRepository(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => const RemoteAuthRepository(),
  );

  // Multi-Role Context Repository (safe 503 fallback placeholder)
  sl.registerLazySingleton<RoleContextRepository>(
    () => const RemoteRoleContextRepository(),
  );

  // Notification Preferences Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<NotificationPreferencesRepository>(
    () => MockNotificationPreferencesRepository(),
  );

  // Notification Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<NotificationRepository>(
    () => MockNotificationRepository(),
  );

  // Player Dashboard Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<PlayerDashboardRepository>(
    () => const MockPlayerDashboardRepository(),
  );

  // Venue Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<VenueRepository>(
    () => const MockVenueRepository(),
  );

  // Booking Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<BookingRepository>(
    () => MockBookingRepository.withDefaultBookings(),
  );

  // Match Day Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<MatchDayRepository>(
    () => MockMatchDayRepository(),
  );

  // Tournament Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<TournamentRepository>(
    () => MockTournamentRepository(),
  );

  // Marketplace Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<MarketplaceRepository>(
    () => MockMarketplaceRepository(),
  );

  // Coaching & Academy Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<CoachingAcademyRepository>(
    () => MockCoachingAcademyRepository(),
  );

  // Community Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<CommunityRepository>(
    () => MockCommunityRepository(),
  );

  // Coach Dashboard Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<CoachDashboardRepository>(
    () => const MockCoachDashboardRepository(),
  );

  // Coach Profile Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<CoachProfileRepository>(
    () => MockCoachProfileRepository(),
  );

  // Coach Calendar Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<CoachCalendarRepository>(
    () => MockCoachCalendarRepository(),
  );

  // Coach Personal Coaching Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<PersonalCoachingRepository>(
    () => MockPersonalCoachingRepository(),
  );

  // Academy Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<AcademyRepository>(
    () => MockAcademyRepository(),
  );

  // Academy Staff Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<AcademyStaffRepository>(
    () => MockAcademyStaffRepository(),
  );

  // Venue Partner Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<VenuePartnerRepository>(
    () => MockVenuePartnerRepository(),
  );

  // Venue Staff Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<VenueStaffRepository>(
    () => MockVenueStaffRepository(),
  );

  // Tournament Organizer Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<TournamentOrganizerRepository>(
    () => MockTournamentOrganizerRepository(),
  );

  // Tournament Staff Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<TournamentStaffRepository>(
    () => MockTournamentStaffRepository(),
  );

  // Referee Repository (mock baseline until remote endpoint connects)
  sl.registerLazySingleton<RefereeRepository>(
    () => MockRefereeRepository(),
  );
}
