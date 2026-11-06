import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/session_context.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/router/app_router.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/router/route_guards.dart';
import 'package:pickleball_platform/core/widgets/state_views/account_suspended_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/permission_denied_view.dart';
import 'package:pickleball_platform/features/role_selection/domain/entities/role_context.dart';

Widget _wrapRouter({
  required GoRouter router,
  required SessionCubit sessionCubit,
}) {
  return BlocProvider<SessionCubit>.value(
    value: sessionCubit,
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
    ),
  );
}

void main() {
  group('Route Guards Unit Tests (CompositeRouteGuard)', () {
    const guards = CompositeRouteGuard();

    test('Unauthenticated user accessing protected route is redirected to welcome', () {
      const session = SessionContext.unauthenticated();
      final redirect = guards.evaluate(session, AppRoutes.playerDashboard);
      expect(redirect, equals(AppRoutes.welcome));
    });

    test('Unauthenticated user accessing public auth entry route is allowed', () {
      const session = SessionContext.unauthenticated();
      expect(guards.evaluate(session, AppRoutes.welcome), isNull);
      expect(guards.evaluate(session, AppRoutes.login), isNull);
      expect(guards.evaluate(session, AppRoutes.register), isNull);
      expect(guards.evaluate(session, AppRoutes.forgotPassword), isNull);
    });

    test('Unauthenticated user accessing public tournament routes is allowed', () {
      const session = SessionContext.unauthenticated();
      expect(guards.evaluate(session, '/public/tournaments/tournament-123'), isNull);
      expect(guards.evaluate(session, AppRoutes.publicRankings), isNull);
    });

    test('Unauthenticated user accessing root / is redirected to welcome', () {
      const session = SessionContext.unauthenticated();
      expect(guards.evaluate(session, AppRoutes.root), equals(AppRoutes.welcome));
    });

    test('Authenticated user without active role accessing protected route goes to role-selection', () {
      const session = SessionContext.authenticated(
        userId: 'u-1',
        email: 'user@test.com',
        availableRoles: [UserRole.player, UserRole.coach],
        activeRole: null,
      );

      expect(guards.evaluate(session, AppRoutes.playerDashboard), equals(AppRoutes.roleSelection));
      expect(guards.evaluate(session, AppRoutes.root), equals(AppRoutes.roleSelection));
      expect(guards.evaluate(session, AppRoutes.roleSelection), isNull);
    });

    test('Authenticated user with active role is redirected away from login/welcome to dashboard', () {
      const session = SessionContext.authenticated(
        userId: 'u-1',
        email: 'player@test.com',
        availableRoles: [UserRole.player],
        activeRole: UserRole.player,
      );

      expect(guards.evaluate(session, AppRoutes.welcome), equals(AppRoutes.playerDashboard));
      expect(guards.evaluate(session, AppRoutes.login), equals(AppRoutes.playerDashboard));
      expect(guards.evaluate(session, AppRoutes.root), equals(AppRoutes.playerDashboard));
    });

    test('Active role user accessing own role routes is allowed', () {
      const session = SessionContext.authenticated(
        userId: 'u-1',
        email: 'player@test.com',
        availableRoles: [UserRole.player],
        activeRole: UserRole.player,
      );

      expect(guards.evaluate(session, AppRoutes.playerDashboard), isNull);
      expect(guards.evaluate(session, AppRoutes.playerVenues), isNull);
      expect(guards.evaluate(session, AppRoutes.playerBookings), isNull);
    });

    test('Active role user accessing unauthorized role route is redirected to permission-denied', () {
      const session = SessionContext.authenticated(
        userId: 'u-1',
        email: 'player@test.com',
        availableRoles: [UserRole.player],
        activeRole: UserRole.player,
      );

      // Attempting to access venue-partner area as player
      expect(
        guards.evaluate(session, AppRoutes.venuePartnerDashboard),
        equals(AppRoutes.permissionDenied),
      );
      // Attempting to access admin area as player
      expect(
        guards.evaluate(session, AppRoutes.applicationAdminDashboard),
        equals(AppRoutes.permissionDenied),
      );
    });

    test('Suspended user is redirected to account-suspended for protected routes', () {
      const session = SessionContext.suspended(
        userId: 'u-99',
        email: 'banned@test.com',
        availableRoles: [UserRole.player],
      );

      expect(
        guards.evaluate(session, AppRoutes.playerDashboard),
        equals(AppRoutes.accountSuspended),
      );
      expect(
        guards.evaluate(session, AppRoutes.roleSelection),
        equals(AppRoutes.accountSuspended),
      );
      // But can view account-suspended itself and public schedules
      expect(guards.evaluate(session, AppRoutes.accountSuspended), isNull);
      expect(guards.evaluate(session, '/public/tournaments/t-1'), isNull);
    });
  });

  group('Role Preference Storage Tests', () {
    late MockRolePreferenceStorage storage;

    setUp(() {
      storage = MockRolePreferenceStorage();
    });

    test('Stores, retrieves, and clears preferred role per user ID', () async {
      expect(await storage.getPreferredRole('user-1'), isNull);

      await storage.setPreferredRole('user-1', UserRole.venuePartner);
      expect(await storage.getPreferredRole('user-1'), equals(UserRole.venuePartner));

      await storage.clearPreferredRole('user-1');
      expect(await storage.getPreferredRole('user-1'), isNull);
    });
  });

  group('SessionCubit Multi-Role State Tests', () {
    late MockRolePreferenceStorage storage;
    late SessionCubit cubit;

    setUp(() {
      storage = MockRolePreferenceStorage();
      cubit = SessionCubit(preferenceStorage: storage);
    });

    tearDown(() {
      cubit.close();
    });

    test('Initial state is unauthenticated', () {
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.activeRole, isNull);
    });

    test('signIn sets authenticated state and active role', () async {
      await cubit.signIn(
        userId: 'u-1',
        email: 'organizer@pickleball.org',
        roles: [UserRole.tournamentOrganizer, UserRole.referee],
        activeRole: UserRole.tournamentOrganizer,
      );

      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.activeRole, equals(UserRole.tournamentOrganizer));
      expect(cubit.state.availableRoles.length, equals(2));
    });

    test('switchRole transitions between available assigned roles', () async {
      await cubit.signIn(
        userId: 'u-1',
        email: 'multi@test.com',
        roles: [UserRole.player, UserRole.coach],
        activeRole: UserRole.player,
      );

      await cubit.switchRole(UserRole.coach);
      expect(cubit.state.activeRole, equals(UserRole.coach));

      // Attempting to switch to unassigned role is ignored
      await cubit.switchRole(UserRole.applicationAdmin);
      expect(cubit.state.activeRole, equals(UserRole.coach));
    });

    test('setRememberPreferredRole persists preference to storage', () async {
      await cubit.signIn(
        userId: 'u-42',
        email: 'coach@test.com',
        roles: [UserRole.coach],
        activeRole: UserRole.coach,
      );

      await cubit.setRememberPreferredRole(true);
      expect(await storage.getPreferredRole('u-42'), equals(UserRole.coach));

      await cubit.setRememberPreferredRole(false);
      expect(await storage.getPreferredRole('u-42'), isNull);
    });

    test('signIn restores saved preferred role if assigned', () async {
      await storage.setPreferredRole('u-88', UserRole.venuePartner);

      await cubit.signIn(
        userId: 'u-88',
        email: 'venue@test.com',
        roles: [UserRole.player, UserRole.venuePartner],
        // No activeRole explicitly passed
      );

      expect(cubit.state.activeRole, equals(UserRole.venuePartner));
    });

    test('signOut clears state back to unauthenticated', () async {
      await cubit.signIn(
        userId: 'u-1',
        email: 'test@test.com',
        roles: [UserRole.player],
        activeRole: UserRole.player,
      );
      expect(cubit.state.isAuthenticated, isTrue);

      cubit.signOut();
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.activeRole, isNull);
    });
  });

  group('SessionCubit Role Context Preservation & Switching Tests', () {
    late MockRolePreferenceStorage storage;
    late SessionCubit cubit;

    setUp(() {
      storage = MockRolePreferenceStorage();
      cubit = SessionCubit(preferenceStorage: storage);
    });

    tearDown(() {
      cubit.close();
    });

    test('setActiveRoleProfile preserves complete context (assignmentId, orgId, orgName, tournId, tournName)', () async {
      await cubit.signIn(
        userId: 'u-100',
        email: 'staff@pickleball.org',
        roles: [UserRole.tournamentStaff, UserRole.player],
        activeRole: null,
      );

      const profile = RoleProfile(
        roleAssignmentId: 'assign_ts_001',
        role: UserRole.tournamentStaff,
        organizationId: 'org_pac_01',
        organizationName: 'Pacific Pickleball Series',
        tournamentId: 'tourn_mumbai_01',
        tournamentName: 'Mumbai Open 2026',
        isActive: true,
      );

      await cubit.setActiveRoleProfile(profile);

      expect(cubit.state.activeRole, equals(UserRole.tournamentStaff));
      expect(cubit.state.activeRoleAssignmentId, equals('assign_ts_001'));
      expect(cubit.state.activeOrganizationId, equals('org_pac_01'));
      expect(cubit.state.activeOrganizationName, equals('Pacific Pickleball Series'));
      expect(cubit.state.activeTournamentId, equals('tourn_mumbai_01'));
      expect(cubit.state.activeTournamentName, equals('Mumbai Open 2026'));
    });

    test('Switching from tournament-scoped role to non-tournament role clears old tournament and organization context', () async {
      await cubit.signIn(
        userId: 'u-100',
        email: 'user@test.com',
        roles: [UserRole.tournamentStaff, UserRole.player],
        activeRole: UserRole.tournamentStaff,
        roleAssignmentId: 'assign_ts_001',
        organizationId: 'org_pac_01',
        organizationName: 'Pacific Pickleball Series',
        tournamentId: 'tourn_mumbai_01',
        tournamentName: 'Mumbai Open 2026',
      );

      expect(cubit.state.activeTournamentId, equals('tourn_mumbai_01'));
      expect(cubit.state.activeTournamentName, equals('Mumbai Open 2026'));

      const playerProfile = RoleProfile(
        roleAssignmentId: 'assign_player_001',
        role: UserRole.player,
        isActive: true,
      );

      await cubit.setActiveRoleProfile(playerProfile);

      expect(cubit.state.activeRole, equals(UserRole.player));
      expect(cubit.state.activeRoleAssignmentId, equals('assign_player_001'));
      expect(cubit.state.activeTournamentId, isNull);
      expect(cubit.state.activeTournamentName, isNull);
      expect(cubit.state.activeOrganizationId, isNull);
      expect(cubit.state.activeOrganizationName, isNull);
    });

    test('Switching organization updates organization context and clears tournament context', () async {
      await cubit.signIn(
        userId: 'u-100',
        email: 'staff@test.com',
        roles: [UserRole.tournamentStaff, UserRole.venueStaff],
        activeRole: UserRole.tournamentStaff,
        roleAssignmentId: 'assign_ts_001',
        organizationId: 'org_pac_01',
        organizationName: 'Pacific Pickleball Series',
        tournamentId: 'tourn_mumbai_01',
        tournamentName: 'Mumbai Open 2026',
      );

      const venueStaffProfile = RoleProfile(
        roleAssignmentId: 'assign_vs_grand_slam',
        role: UserRole.venueStaff,
        organizationId: 'org_venue_001',
        organizationName: 'Grand Slam Arena',
        isActive: true,
      );

      await cubit.setActiveRoleProfile(venueStaffProfile);

      expect(cubit.state.activeRole, equals(UserRole.venueStaff));
      expect(cubit.state.activeRoleAssignmentId, equals('assign_vs_grand_slam'));
      expect(cubit.state.activeOrganizationId, equals('org_venue_001'));
      expect(cubit.state.activeOrganizationName, equals('Grand Slam Arena'));
      expect(cubit.state.activeTournamentId, isNull);
      expect(cubit.state.activeTournamentName, isNull);
    });

    test('setActiveRoleProfile persists preferred assignment ID when rememberPreferredRole is true', () async {
      await cubit.signIn(
        userId: 'u-200',
        email: 'coach@test.com',
        roles: [UserRole.coach],
        activeRole: null,
        rememberPreferredRole: true,
      );

      const profile = RoleProfile(
        roleAssignmentId: 'assign_coach_pinnacle',
        role: UserRole.coach,
        organizationId: 'org_acad_01',
        organizationName: 'Pinnacle Academy',
        isActive: true,
      );

      await cubit.setActiveRoleProfile(profile);

      expect(await storage.getPreferredRole('u-200'), equals(UserRole.coach));
      expect(await storage.getPreferredAssignmentId('u-200'), equals('assign_coach_pinnacle'));
    });
  });

  group('GoRouter Declarative Navigation Widget Tests', () {
    late SessionCubit sessionCubit;

    setUp(() {
      sessionCubit = SessionCubit();
    });

    tearDown(() {
      sessionCubit.close();
    });

    testWidgets('Unauthenticated visit to protected route redirects to Welcome screen',
        (tester) async {
      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRoutes.playerDashboard,
      );

      await tester.pumpWidget(
        _wrapRouter(router: router, sessionCubit: sessionCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Pickleball'), findsOneWidget);
    });

    testWidgets('Public tournament bracket route is accessible without login',
        (tester) async {
      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: '/public/tournaments/national-open-2026',
      );

      await tester.pumpWidget(
        _wrapRouter(router: router, sessionCubit: sessionCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tournament Live Schedule'), findsOneWidget);
      expect(
        find.text('Route Path: /public/tournaments/national-open-2026'),
        findsOneWidget,
      );
      expect(
        find.text('Parameters: {id: national-open-2026}'),
        findsOneWidget,
      );
    });

    testWidgets('Role selection view displays available roles and activates chosen role',
        (tester) async {
      await sessionCubit.signIn(
        userId: 'user-7',
        email: 'user@test.com',
        roles: [UserRole.player, UserRole.coach],
      );

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRoutes.roleSelection,
      );

      await tester.pumpWidget(
        _wrapRouter(router: router, sessionCubit: sessionCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Select Active Role'), findsOneWidget);
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('Coach'), findsOneWidget);

      // Tap Coach card to activate
      await tester.tap(find.text('Coach'));
      await tester.pumpAndSettle();

      expect(sessionCubit.state.activeRole, equals(UserRole.coach));
      expect(find.text('Coach Dashboard'), findsOneWidget);
    });

    testWidgets('Unauthorized role route access redirects to PermissionDeniedView',
        (tester) async {
      await sessionCubit.signIn(
        userId: 'u-p',
        email: 'player@test.com',
        roles: [UserRole.player],
        activeRole: UserRole.player,
      );

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRoutes.applicationAdminDashboard,
      );

      await tester.pumpWidget(
        _wrapRouter(router: router, sessionCubit: sessionCubit),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PermissionDeniedView), findsOneWidget);
      expect(find.text('Access Restricted'), findsOneWidget);
    });

    testWidgets('Suspended account is redirected to AccountSuspendedView',
        (tester) async {
      await sessionCubit.signIn(
        userId: 'u-suspended',
        email: 'suspended@test.com',
        roles: [UserRole.player],
        activeRole: UserRole.player,
        isSuspended: true,
      );

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRoutes.playerDashboard,
      );

      await tester.pumpWidget(
        _wrapRouter(router: router, sessionCubit: sessionCubit),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AccountSuspendedView), findsOneWidget);
      expect(find.text('Account Suspended'), findsOneWidget);
    });

    testWidgets('Unknown route displays Page Not Found (404) view with return CTA',
        (tester) async {
      await sessionCubit.signIn(
        userId: 'u-1',
        email: 'user@test.com',
        roles: [UserRole.player],
        activeRole: UserRole.player,
      );

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: '/unknown/random/endpoint/404',
      );

      await tester.pumpWidget(
        _wrapRouter(router: router, sessionCubit: sessionCubit),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('Page Not Found'), findsOneWidget);
      expect(find.text('Return Home'), findsOneWidget);

      // Tap return CTA to navigate back to dashboard
      await tester.tap(find.text('Return Home'));
      await tester.pumpAndSettle();

      expect(find.text('Player Dashboard'), findsOneWidget);
    });

    testWidgets('Mobile shell (<600dp) renders bottom NavigationBar', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await sessionCubit.signIn(
        userId: 'u-1',
        email: 'player@test.com',
        roles: [UserRole.player],
        activeRole: UserRole.player,
      );

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRoutes.playerDashboard,
      );

      await tester.pumpWidget(
        _wrapRouter(router: router, sessionCubit: sessionCubit),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Courts'), findsOneWidget);
      expect(find.text('Bookings'), findsOneWidget);

      // Tap on Courts tab
      await tester.tap(find.text('Courts'));
      await tester.pumpAndSettle();

      expect(find.text('Discover Courts & Venues'), findsOneWidget);
    });

    testWidgets('Desktop shell (>1024dp) renders sidebar navigation and sign out',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await sessionCubit.signIn(
        userId: 'u-1',
        email: 'player@test.com',
        roles: [UserRole.player, UserRole.coach],
        activeRole: UserRole.player,
      );

      final router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRoutes.playerDashboard,
      );

      await tester.pumpWidget(
        _wrapRouter(router: router, sessionCubit: sessionCubit),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pickleball'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      // Sign Out from desktop sidebar
      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(sessionCubit.state.isAuthenticated, isFalse);
      expect(find.text('Welcome to Pickleball'), findsOneWidget);
    });
  });
}
