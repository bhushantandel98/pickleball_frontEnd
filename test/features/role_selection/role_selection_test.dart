import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/mock/mock_config.dart';
import 'package:pickleball_platform/core/mock/mock_network_harness.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/role_dashboard_router.dart';
import 'package:pickleball_platform/core/widgets/navigation/route_placeholder_view.dart';
import 'package:pickleball_platform/features/role_selection/data/models/role_context_model.dart';
import 'package:pickleball_platform/features/role_selection/data/repositories/mock_role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/data/repositories/remote_role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/domain/entities/role_context.dart';
import 'package:pickleball_platform/features/role_selection/domain/repositories/role_context_repository.dart';
import 'package:pickleball_platform/features/role_selection/presentation/cubit/role_selection_cubit.dart';
import 'package:pickleball_platform/features/role_selection/presentation/pages/role_selection_page.dart';

class _FakeRoleContextRepository implements RoleContextRepository {
  Result<RoleContext> result;
  UserRole? savedPreferredRole;
  String? savedPreferredAssignmentId;
  int clearPreferredCallCount = 0;

  _FakeRoleContextRepository(this.result);

  @override
  Future<Result<RoleContext>> getRoleContext(String userId) async {
    return result;
  }

  @override
  Future<Result<void>> selectPreferredRole({
    required String userId,
    required String roleAssignmentId,
    UserRole? role,
  }) async {
    savedPreferredAssignmentId = roleAssignmentId;
    savedPreferredRole = role;
    return const Success(null);
  }

  @override
  Future<Result<void>> clearPreferredRole(String userId) async {
    clearPreferredCallCount++;
    savedPreferredRole = null;
    savedPreferredAssignmentId = null;
    return const Success(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    MockConfig.instance.reset();
  });

  group('RoleContext & RoleProfile Domain Entities', () {
    test('RoleProfile provides sensible default descriptions for all 12 roles', () {
      for (final role in UserRole.values) {
        final profile = RoleProfile(
          roleAssignmentId: 'assign_${role.id}',
          role: role,
        );
        expect(profile.description, isNotEmpty);
        expect(profile.description.length, greaterThan(15));
      }
    });

    test('RoleProfile custom description overrides default description', () {
      const custom = 'Custom special instructions for referee operations.';
      final profile = RoleProfile(
        roleAssignmentId: 'assign_referee_001',
        role: UserRole.referee,
        description: custom,
      );
      expect(profile.description, equals(custom));
    });

    test('RoleContext filters active profiles and exposes active roles', () {
      final context = RoleContext(
        userId: 'u1',
        displayName: 'Test User',
        phone: '+91 9876543210',
        roleProfiles: const [
          RoleProfile(
            roleAssignmentId: 'assign_player_001',
            role: UserRole.player,
            isActive: true,
          ),
          RoleProfile(
            roleAssignmentId: 'assign_coach_001',
            role: UserRole.coach,
            isActive: false,
          ),
          RoleProfile(
            roleAssignmentId: 'assign_acad_001',
            role: UserRole.academy,
            isActive: true,
            organizationName: 'City Academy',
          ),
        ],
      );

      expect(context.activeProfiles.length, equals(2));
      expect(context.activeRoles, equals([UserRole.player, UserRole.academy]));
      expect(context.hasMultipleRoles, isTrue);
      expect(context.hasNoRoles, isFalse);
      expect(context.profileFor(UserRole.player)?.role, equals(UserRole.player));
      expect(context.profileFor(UserRole.coach)?.isActive, isFalse);
      expect(context.profileFor(UserRole.applicationAdmin), isNull);
      expect(context.profileForAssignment('assign_acad_001')?.organizationName, equals('City Academy'));
    });

    test('RoleContext correctly detects empty roles (0 active roles)', () {
      final context = RoleContext(
        userId: 'u2',
        displayName: 'Empty User',
        phone: '+91 9876543211',
        roleProfiles: const [
          RoleProfile(
            roleAssignmentId: 'assign_player_002',
            role: UserRole.player,
            isActive: false,
          ),
        ],
      );

      expect(context.activeProfiles, isEmpty);
      expect(context.activeRoles, isEmpty);
      expect(context.hasMultipleRoles, isFalse);
      expect(context.hasNoRoles, isTrue);
    });
  });

  group('Safe API Role Parsing & DTO Serialization', () {
    test('RoleProfileModel serializes and deserializes correctly with roleAssignmentId', () {
      final model = RoleProfileModel(
        roleAssignmentId: 'assign_coach_pinnacle',
        role: 'coach',
        organizationId: 'org_1',
        organizationName: 'Elite Coaching',
        isActive: true,
        description: 'Elite training programs',
      );

      final json = model.toJson();
      final fromJson = RoleProfileModel.fromJson(json);

      expect(fromJson.roleAssignmentId, equals('assign_coach_pinnacle'));
      expect(fromJson.role, equals('coach'));
      expect(fromJson.organizationId, equals('org_1'));
      expect(fromJson.organizationName, equals('Elite Coaching'));

      final entity = model.toEntity()!;
      expect(entity.roleAssignmentId, equals('assign_coach_pinnacle'));
      expect(entity.role, equals(UserRole.coach));
      expect(entity.organizationName, equals('Elite Coaching'));
      expect(entity.isActive, isTrue);
    });

    test('Missing role in API payload NEVER defaults to player - drops invalid record', () {
      final jsonMissingRole = {
        'roleAssignmentId': 'assign_invalid_001',
        'organizationId': 'org_1',
        'isActive': true,
      };

      final model = RoleProfileModel.fromJson(jsonMissingRole);
      expect(model.role, isNull);
      expect(model.toEntity(), isNull);
    });

    test('Missing isActive in API payload NEVER defaults to true - produces inactive profile', () {
      final jsonMissingActive = {
        'roleAssignmentId': 'assign_coach_unverified',
        'role': 'coach',
        'organizationId': 'org_1',
        // isActive is omitted
      };

      final model = RoleProfileModel.fromJson(jsonMissingActive);
      expect(model.isActive, isNull);
      final entity = model.toEntity();
      expect(entity, isNotNull);
      expect(entity!.isActive, isFalse, reason: 'Omitted isActive must strictly evaluate to false');
    });

    test('Unknown or empty role strings produce null entities and are excluded from active profiles', () {
      final jsonEmptyRole = {
        'roleAssignmentId': 'assign_empty',
        'role': '   ',
        'isActive': true,
      };
      expect(RoleProfileModel.fromJson(jsonEmptyRole).toEntity(), isNull);

      final jsonUnknownRole = {
        'roleAssignmentId': 'assign_unknown',
        'role': 'super_admin_unrecognized',
        'isActive': true,
      };
      expect(RoleProfileModel.fromJson(jsonUnknownRole).toEntity(), isNull);
    });

    test('RoleContextModel maps preferredRoleAssignmentId and multi-role assignments correctly', () {
      final model = RoleContextModel(
        userId: 'user_100',
        displayName: 'Vijay Kumar',
        phone: '+91 9988776655',
        email: 'vijay@pickleball.com',
        preferredRoleAssignmentId: 'assign_vp_grand_slam',
        roles: const [
          RoleProfileModel(
            roleAssignmentId: 'assign_player_100',
            role: 'player',
            isActive: true,
          ),
          RoleProfileModel(
            roleAssignmentId: 'assign_vp_grand_slam',
            role: 'venuePartner',
            organizationId: 'org_v1',
            organizationName: 'Grand Slam Arena',
            isActive: true,
          ),
        ],
      );

      final json = model.toJson();
      final fromJson = RoleContextModel.fromJson(json);
      expect(fromJson.userId, equals('user_100'));
      expect(fromJson.preferredRoleAssignmentId, equals('assign_vp_grand_slam'));

      final entity = fromJson.toEntity();
      expect(entity.userId, equals('user_100'));
      expect(entity.preferredRoleAssignmentId, equals('assign_vp_grand_slam'));
      expect(entity.activeRoles, equals([UserRole.player, UserRole.venuePartner]));
      expect(entity.hasMultipleRoles, isTrue);
    });
  });

  group('Organization-Specific Role Assignments (Same Role in Multiple Orgs)', () {
    late MockRolePreferenceStorage storage;

    setUp(() {
      storage = MockRolePreferenceStorage();
    });

    test('Distinguishes multiple assignments of identical role across different organizations', () {
      final context = RoleContext(
        userId: 'user_multi_venue_staff',
        displayName: 'Staff Member',
        phone: '+91 9876543210',
        roleProfiles: const [
          RoleProfile(
            roleAssignmentId: 'assign_vs_grand_slam',
            role: UserRole.venueStaff,
            organizationId: 'org_venue_001',
            organizationName: 'Grand Slam Arena',
            isActive: true,
          ),
          RoleProfile(
            roleAssignmentId: 'assign_vs_metro_courts',
            role: UserRole.venueStaff,
            organizationId: 'org_venue_002',
            organizationName: 'Metro Court Center',
            isActive: true,
          ),
        ],
      );

      expect(context.activeProfiles.length, equals(2));
      expect(context.hasMultipleRoles, isTrue);

      final profileA = context.profileForAssignment('assign_vs_grand_slam');
      final profileB = context.profileForAssignment('assign_vs_metro_courts');

      expect(profileA?.organizationName, equals('Grand Slam Arena'));
      expect(profileB?.organizationName, equals('Metro Court Center'));
      expect(profileA?.role, equals(UserRole.venueStaff));
      expect(profileB?.role, equals(UserRole.venueStaff));
    });

    test('RoleSelectionCubit selects specific role assignment and preserves organization context', () async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi_venue_staff',
            displayName: 'Staff Member',
            phone: '+91 9876543210',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_vs_grand_slam',
                role: UserRole.venueStaff,
                organizationId: 'org_venue_001',
                organizationName: 'Grand Slam Arena',
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_vs_metro_courts',
                role: UserRole.venueStaff,
                organizationId: 'org_venue_002',
                organizationName: 'Metro Court Center',
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_multi_venue_staff');

      expect(cubit.state, isA<RoleSelectionLoaded>());
      final loaded = cubit.state as RoleSelectionLoaded;
      expect(loaded.selectedAssignmentId, equals('assign_vs_grand_slam'));
      expect(loaded.selectedAssignment?.organizationName, equals('Grand Slam Arena'));

      // Switch assignment to Metro Court Center
      cubit.selectAssignment('assign_vs_metro_courts');
      final updated = cubit.state as RoleSelectionLoaded;
      expect(updated.selectedAssignmentId, equals('assign_vs_metro_courts'));
      expect(updated.selectedAssignment?.organizationName, equals('Metro Court Center'));

      // Confirm with remember
      cubit.toggleRememberChoice(true);
      await cubit.confirmRoleSelection();

      expect(cubit.state, isA<RoleSelectionRedirect>());
      final redirect = cubit.state as RoleSelectionRedirect;
      expect(redirect.targetRole, equals(UserRole.venueStaff));
      expect(redirect.selectedAssignment.organizationId, equals('org_venue_002'));
      expect(await storage.getPreferredAssignmentId('user_multi_venue_staff'), equals('assign_vs_metro_courts'));
    });

    test('Auto-continues to remembered roleAssignmentId on subsequent session', () async {
      await storage.setPreferredAssignmentId('user_multi_venue_staff', 'assign_vs_metro_courts');

      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi_venue_staff',
            displayName: 'Staff Member',
            phone: '+91 9876543210',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_vs_grand_slam',
                role: UserRole.venueStaff,
                organizationId: 'org_venue_001',
                organizationName: 'Grand Slam Arena',
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_vs_metro_courts',
                role: UserRole.venueStaff,
                organizationId: 'org_venue_002',
                organizationName: 'Metro Court Center',
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_multi_venue_staff');

      expect(cubit.state, isA<RoleSelectionRedirect>());
      final redirect = cubit.state as RoleSelectionRedirect;
      expect(redirect.selectedAssignment.roleAssignmentId, equals('assign_vs_metro_courts'));
      expect(redirect.selectedAssignment.organizationId, equals('org_venue_002'));
    });

    test('Cleanly falls back to selection screen if remembered roleAssignmentId is revoked', () async {
      // Remembered assignment revoked/removed from backend
      await storage.setPreferredAssignmentId('user_multi_venue_staff', 'assign_vs_revoked');

      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi_venue_staff',
            displayName: 'Staff Member',
            phone: '+91 9876543210',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_vs_grand_slam',
                role: UserRole.venueStaff,
                organizationId: 'org_venue_001',
                organizationName: 'Grand Slam Arena',
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      // Even with 1 active role remaining, loadRoleContext with invalid remembered assignment falls back safely
      await cubit.loadRoleContext(userId: 'user_multi_venue_staff', bypassAutoRedirect: true);

      expect(cubit.state, isA<RoleSelectionLoaded>());
      final loaded = cubit.state as RoleSelectionLoaded;
      expect(loaded.selectedAssignmentId, equals('assign_vs_grand_slam'));
    });
  });

  group('RoleDashboardRouter Canonical Routing (All 12 Roles)', () {
    test('maps all 12 platform roles to their designated dashboard route', () {
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.player), equals('/player/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.coach), equals('/coach/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.academy), equals('/academy/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.academyStaff), equals('/academy-staff/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.venuePartner), equals('/venue-partner/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.venueStaff), equals('/venue-staff/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.tournamentOrganizer), equals('/tournament-organizer/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.tournamentStaff), equals('/tournament-staff/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.referee), equals('/referee/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.marketplaceSeller), equals('/marketplace-seller/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.applicationStaff), equals('/application-staff/dashboard'));
      expect(RoleDashboardRouter.getDashboardRoute(UserRole.applicationAdmin), equals('/application-admin/dashboard'));
    });

    test('isDashboardRoute returns true for canonical dashboard paths only', () {
      expect(RoleDashboardRouter.isDashboardRoute('/player/dashboard'), isTrue);
      expect(RoleDashboardRouter.isDashboardRoute('/coach/dashboard'), isTrue);
      expect(RoleDashboardRouter.isDashboardRoute('/referee/dashboard'), isTrue);
      expect(RoleDashboardRouter.isDashboardRoute('/unknown/dashboard'), isFalse);
      expect(RoleDashboardRouter.isDashboardRoute('/player/courts'), isFalse);
    });
  });

  group('Mock and Remote RoleContextRepository Tests', () {
    late MockNetworkHarness harness;
    late MockRolePreferenceStorage storage;

    setUp(() {
      harness = MockNetworkHarness(config: MockConfig.instance);
      storage = MockRolePreferenceStorage();
    });

    test('MockRoleContextRepository resolves multi-role user with organization context', () async {
      final repo = MockRoleContextRepository(harness: harness, preferenceStorage: storage);
      final result = await repo.getRoleContext('user_multi_001');

      expect(result.isSuccess, isTrue);
      result.when(
        success: (context) {
          expect(context.userId, equals('user_multi_001'));
          expect(context.activeRoles, containsAll([UserRole.player, UserRole.coach, UserRole.referee]));
          expect(context.hasMultipleRoles, isTrue);
        },
        failure: (f) => fail('Should succeed'),
      );
    });

    test('MockRoleContextRepository supports multi-organization venue staff fixture', () async {
      final repo = MockRoleContextRepository(harness: harness, preferenceStorage: storage);
      final result = await repo.getRoleContext('user_multi_venue_staff');

      expect(result.isSuccess, isTrue);
      result.when(
        success: (context) {
          expect(context.userId, equals('user_multi_venue_staff'));
          expect(context.activeProfiles.length, equals(2));
          final ids = context.activeProfiles.map((p) => p.roleAssignmentId).toList();
          expect(ids, containsAll(['assign_vs_grand_slam', 'assign_vs_metro_courts']));
        },
        failure: (f) => fail('Should succeed'),
      );
    });

    test('MockRoleContextRepository resolves all 12 platform roles when queried with user_all_12_roles', () async {
      final repo = MockRoleContextRepository(harness: harness, preferenceStorage: storage);
      final result = await repo.getRoleContext('user_all_12_roles');

      expect(result.isSuccess, isTrue);
      result.when(
        success: (context) {
          expect(context.activeProfiles.length, equals(12));
          expect(context.activeRoles.length, equals(12));
          for (final role in UserRole.values) {
            expect(context.activeRoles.contains(role), isTrue,
                reason: 'All 12 platform roles must be present in demo fixture');
          }
        },
        failure: (f) => fail('Should resolve all 12 roles'),
      );
    });

    test('MockRoleContextRepository resolves multi-tournament staff assignments with tournament names', () async {
      final repo = MockRoleContextRepository(harness: harness, preferenceStorage: storage);
      final result = await repo.getRoleContext('user_multi_tournament_staff');

      expect(result.isSuccess, isTrue);
      result.when(
        success: (context) {
          expect(context.activeProfiles.length, equals(2));
          final profile1 = context.profileForAssignment('assign_ts_mumbai');
          final profile2 = context.profileForAssignment('assign_ts_national');

          expect(profile1?.tournamentName, equals('Mumbai Pickleball Championship 2026'));
          expect(profile1?.organizationName, equals('Pacific Pickleball Series'));
          expect(profile2?.tournamentName, equals('Monsoon Open 2026'));
          expect(profile2?.organizationName, equals('National Pickleball League'));
        },
        failure: (f) => fail('Should resolve multi-tournament assignments'),
      );
    });

    test('MockRoleContextRepository resolves zero active roles for user_zero', () async {
      final repo = MockRoleContextRepository(harness: harness, preferenceStorage: storage);
      final result = await repo.getRoleContext('user_zero');

      expect(result.isSuccess, isTrue);
      result.when(
        success: (context) {
          expect(context.activeProfiles, isEmpty);
          expect(context.hasNoRoles, isTrue);
        },
        failure: (f) => fail('Should return empty context'),
      );
    });

    test('MockRoleContextRepository saves and clears preferred role assignment', () async {
      final repo = MockRoleContextRepository(harness: harness, preferenceStorage: storage);

      await repo.selectPreferredRole(
        userId: 'u_1',
        roleAssignmentId: 'assign_coach_001',
        role: UserRole.coach,
      );
      expect(await storage.getPreferredRole('u_1'), equals(UserRole.coach));
      expect(await storage.getPreferredAssignmentId('u_1'), equals('assign_coach_001'));

      await repo.clearPreferredRole('u_1');
      expect(await storage.getPreferredRole('u_1'), isNull);
      expect(await storage.getPreferredAssignmentId('u_1'), isNull);
    });

    test('RemoteRoleContextRepository returns 503 Service Unavailable placeholder without throwing', () async {
      const repo = RemoteRoleContextRepository();

      final result = await repo.getRoleContext('u_any');
      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('Should be placeholder failure'),
        failure: (f) {
          expect(f.statusCode, equals(503));
          expect(f.message, contains('Role context service is currently unavailable'));
        },
      );

      final saveResult = await repo.selectPreferredRole(
        userId: 'u_1',
        roleAssignmentId: 'assign_player_001',
        role: UserRole.player,
      );
      expect(saveResult.isFailure, isTrue);

      final clearResult = await repo.clearPreferredRole('u_1');
      expect(clearResult.isFailure, isTrue);
    });
  });

  group('RoleSelectionCubit Business Logic & State Transitions', () {
    late MockRolePreferenceStorage storage;

    setUp(() {
      storage = MockRolePreferenceStorage();
    });

    test('0 active roles -> emits RoleSelectionEmpty (never grants Player or fallback role)', () async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_zero',
            displayName: 'Zero Role User',
            phone: '+91 9999900000',
            roleProfiles: const [],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_zero');

      expect(cubit.state, isA<RoleSelectionEmpty>());
      final emptyState = cubit.state as RoleSelectionEmpty;
      expect(emptyState.displayName, equals('Zero Role User'));
    });

    test('1 active role -> auto-continues to that role dashboard via RoleSelectionRedirect', () async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_single',
            displayName: 'Single Role User',
            phone: '+91 9999911111',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_single_player',
                role: UserRole.player,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_single');

      expect(cubit.state, isA<RoleSelectionRedirect>());
      final redirect = cubit.state as RoleSelectionRedirect;
      expect(redirect.targetRole, equals(UserRole.player));
      expect(redirect.destinationPath, equals('/player/dashboard'));
    });

    test('1 active role with bypassAutoRedirect=true -> renders selection UI instead of redirecting', () async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_single',
            displayName: 'Single Role User',
            phone: '+91 9999911111',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_single_coach',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_single', bypassAutoRedirect: true);

      expect(cubit.state, isA<RoleSelectionLoaded>());
      final loaded = cubit.state as RoleSelectionLoaded;
      expect(loaded.selectedRole, equals(UserRole.coach));
    });

    test('Multiple roles with valid remembered role -> auto-continues to remembered role', () async {
      await storage.setPreferredRole('user_multi', UserRole.coach);
      await storage.setPreferredAssignmentId('user_multi', 'assign_coach_001');

      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Multi User',
            phone: '+91 9999922222',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_multi');

      expect(cubit.state, isA<RoleSelectionRedirect>());
      final redirect = cubit.state as RoleSelectionRedirect;
      expect(redirect.targetRole, equals(UserRole.coach));
      expect(redirect.destinationPath, equals('/coach/dashboard'));
    });

    test('Multiple roles with revoked/invalid remembered role -> falls back cleanly to selection UI', () async {
      await storage.setPreferredRole('user_multi', UserRole.referee);
      await storage.setPreferredAssignmentId('user_multi', 'assign_referee_revoked');

      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Multi User',
            phone: '+91 9999922222',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_multi');

      expect(cubit.state, isA<RoleSelectionLoaded>());
      final loaded = cubit.state as RoleSelectionLoaded;
      expect(loaded.roleContext.activeRoles, equals([UserRole.player, UserRole.coach]));
    });

    test('selectRole and selectAssignment update selected role in RoleSelectionLoaded state', () async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Multi User',
            phone: '+91 9999922222',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_multi');

      cubit.selectRole(UserRole.coach);
      expect((cubit.state as RoleSelectionLoaded).selectedRole, equals(UserRole.coach));

      cubit.selectAssignment('assign_player_001');
      expect((cubit.state as RoleSelectionLoaded).selectedAssignmentId, equals('assign_player_001'));
      expect((cubit.state as RoleSelectionLoaded).selectedRole, equals(UserRole.player));
    });

    test('confirmRoleSelection with rememberChoice=true saves preference and emits RoleSelectionRedirect', () async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Multi User',
            phone: '+91 9999922222',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_multi');

      cubit.selectRole(UserRole.coach);
      cubit.toggleRememberChoice(true);

      await cubit.confirmRoleSelection();

      expect(cubit.state, isA<RoleSelectionRedirect>());
      final redirect = cubit.state as RoleSelectionRedirect;
      expect(redirect.targetRole, equals(UserRole.coach));
      expect(await storage.getPreferredRole('user_multi'), equals(UserRole.coach));
      expect(await storage.getPreferredAssignmentId('user_multi'), equals('assign_coach_001'));
    });

    test('confirmRoleSelection with rememberChoice=false clears preference and emits RoleSelectionRedirect', () async {
      await storage.setPreferredRole('user_multi', UserRole.player);
      await storage.setPreferredAssignmentId('user_multi', 'assign_player_001');

      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Multi User',
            phone: '+91 9999922222',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_multi', bypassAutoRedirect: true);

      cubit.selectRole(UserRole.player);
      cubit.toggleRememberChoice(false);

      await cubit.confirmRoleSelection();

      expect(cubit.state, isA<RoleSelectionRedirect>());
      expect(await storage.getPreferredRole('user_multi'), isNull);
      expect(await storage.getPreferredAssignmentId('user_multi'), isNull);
    });

    test('repository failure emits RoleSelectionFailure', () async {
      final repo = _FakeRoleContextRepository(
        const FailureResult(ServerFailure(message: 'Network connection failed')),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      await cubit.loadRoleContext(userId: 'user_fail');

      expect(cubit.state, isA<RoleSelectionFailure>());
      expect((cubit.state as RoleSelectionFailure).message, equals('Network connection failed'));
    });
  });

  group('RoleSelectionPage UI & Widget Tests', () {
    late MockRolePreferenceStorage storage;

    setUp(() {
      storage = MockRolePreferenceStorage();
    });

    Widget buildTestFrame({
      required Widget child,
      ThemeMode mode = ThemeMode.light,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: mode,
        home: child,
      );
    }

    testWidgets('renders empty state when user has zero active roles with register/signout actions', (tester) async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_zero',
            displayName: 'Ananya Roy',
            phone: '+91 9123456789',
            roleProfiles: const [],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      bool accountCreated = false;
      bool signedOut = false;

      await tester.pumpWidget(
        buildTestFrame(
          child: RoleSelectionPage(
            cubit: cubit,
            userId: 'user_zero',
            onCreateAccount: () => accountCreated = true,
            onSignOut: () => signedOut = true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No Active Roles Assigned'), findsOneWidget);
      expect(find.textContaining('Ananya Roy'), findsOneWidget);
      expect(find.text('Create Player Account'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      await tester.tap(find.text('Create Player Account'));
      await tester.pumpAndSettle();
      expect(accountCreated, isTrue);

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();
      expect(signedOut, isTrue);
    });

    testWidgets('renders multiple roles, displays organization badges, and selects role', (tester) async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Vikram Mehta',
            phone: '+91 9876500000',
            email: 'vikram@pickleball.com',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_acad_pinnacle',
                role: UserRole.academy,
                organizationName: 'Pinnacle Sports Academy',
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_referee_001',
                role: UserRole.referee,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      UserRole? selectedRole;

      await tester.pumpWidget(
        buildTestFrame(
          child: RoleSelectionPage(
            cubit: cubit,
            userId: 'user_multi',
            onRoleSelected: (role) => selectedRole = role,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Identity header verification
      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('+91 9876500000'), findsOneWidget);
      expect(find.text('3 Roles'), findsOneWidget);

      // Role names and organization badges
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('Academy Admin'), findsOneWidget);
      expect(find.text('Pinnacle Sports Academy'), findsOneWidget);
      expect(find.text('Referee'), findsOneWidget);

      // Tap on Academy role card (triggers immediate role activation)
      await tester.tap(find.text('Academy Admin'));
      await tester.pumpAndSettle();

      expect(selectedRole, equals(UserRole.academy));
    });

    testWidgets('toggles Remember my choice switch and confirms selection', (tester) async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Rohan Sharma',
            phone: '+91 9876511111',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      UserRole? redirectedRole;

      await tester.pumpWidget(
        buildTestFrame(
          child: RoleSelectionPage(
            cubit: cubit,
            userId: 'user_multi',
            onRoleSelected: (role) => redirectedRole = role,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Toggle switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect((cubit.state as RoleSelectionLoaded).rememberChoice, isTrue);

      // Select Coach and activate
      await tester.tap(find.text('Coach'));
      await tester.pumpAndSettle();

      expect(redirectedRole, equals(UserRole.coach));
      expect(await storage.getPreferredRole('user_multi'), equals(UserRole.coach));
      expect(await storage.getPreferredAssignmentId('user_multi'), equals('assign_coach_001'));
    });

    testWidgets('confirms currently selected role when tapping Continue to Dashboard', (tester) async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Rohan Sharma',
            phone: '+91 9876511111',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      UserRole? confirmedRole;

      await tester.pumpWidget(
        buildTestFrame(
          child: RoleSelectionPage(
            cubit: cubit,
            userId: 'user_multi',
            onRoleSelected: (role) => confirmedRole = role,
          ),
        ),
      );

      await tester.pumpAndSettle();

      final continueButton = find.text('Continue to Dashboard');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(confirmedRole, equals(UserRole.player));
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Dark Mode User',
            phone: '+91 9876522222',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);

      await tester.pumpWidget(
        buildTestFrame(
          mode: ThemeMode.dark,
          child: RoleSelectionPage(
            cubit: cubit,
            userId: 'user_multi',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dark Mode User'), findsOneWidget);
      expect(find.text('Available Roles'), findsOneWidget);
    });

    testWidgets('renders correctly on desktop viewport (>1024dp)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Desktop User',
            phone: '+91 9876533333',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);

      await tester.pumpWidget(
        buildTestFrame(
          child: RoleSelectionPage(
            cubit: cubit,
            userId: 'user_multi',
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Desktop User'), findsOneWidget);
      expect(find.text('Continue to Dashboard'), findsOneWidget);
    });

    testWidgets('displays active context summary banner and updates on selection', (tester) async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_multi',
            displayName: 'Rohan Sharma',
            phone: '+91 9876511111',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_coach_001',
                role: UserRole.coach,
                organizationName: 'Pinnacle Sports Academy',
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);

      await tester.pumpWidget(
        buildTestFrame(
          child: RoleSelectionPage(
            cubit: cubit,
            userId: 'user_multi',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially Player is selected
      expect(find.textContaining('Active Context:'), findsOneWidget);
      expect(find.textContaining('Player'), findsWidgets);

      // Tap radio button on Coach
      final coachRadioFinder = find.byTooltip('Select Coach');
      expect(coachRadioFinder, findsOneWidget);
      await tester.tap(coachRadioFinder);
      await tester.pumpAndSettle();

      // State is updated without navigating away
      expect(cubit.state, isA<RoleSelectionLoaded>());
      final loaded = cubit.state as RoleSelectionLoaded;
      expect(loaded.selectedAssignmentId, equals('assign_coach_001'));
      expect(find.textContaining('Pinnacle Sports Academy'), findsWidgets);
    });

    testWidgets('renders tournament name chip alongside organization name chip', (tester) async {
      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_tourn_multi',
            displayName: 'Sara Connor',
            phone: '+91 9876522222',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_ts_001',
                role: UserRole.tournamentStaff,
                organizationName: 'Pacific Pickleball Series',
                tournamentName: 'Mumbai Pickleball Championship 2026',
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);

      await tester.pumpWidget(
        buildTestFrame(
          child: RoleSelectionPage(
            cubit: cubit,
            userId: 'user_tourn_multi',
            bypassAutoRedirect: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Pacific Pickleball Series'), findsOneWidget);
      expect(find.text('Mumbai Pickleball Championship 2026'), findsWidgets);
      expect(find.text('Tournament Staff'), findsOneWidget);
    });

    testWidgets('passes complete selected assignment to SessionCubit before dashboard navigation', (tester) async {
      final sessionCubit = SessionCubit(preferenceStorage: storage);
      await sessionCubit.signIn(
        userId: 'user_tourn_multi',
        email: 'sara@test.com',
        roles: [UserRole.tournamentStaff, UserRole.player],
        activeRole: null,
      );

      final repo = _FakeRoleContextRepository(
        Success(
          RoleContext(
            userId: 'user_tourn_multi',
            displayName: 'Sara Connor',
            phone: '+91 9876522222',
            roleProfiles: const [
              RoleProfile(
                roleAssignmentId: 'assign_ts_001',
                role: UserRole.tournamentStaff,
                organizationId: 'org_pac_01',
                organizationName: 'Pacific Pickleball Series',
                tournamentId: 'tourn_01',
                tournamentName: 'Mumbai Pickleball Championship 2026',
                isActive: true,
              ),
              RoleProfile(
                roleAssignmentId: 'assign_player_001',
                role: UserRole.player,
                isActive: true,
              ),
            ],
          ),
        ),
      );

      final cubit = RoleSelectionCubit(repository: repo, preferenceStorage: storage);
      RoleProfile? navigatedAssignment;

      await tester.pumpWidget(
        BlocProvider<SessionCubit>.value(
          value: sessionCubit,
          child: buildTestFrame(
            child: RoleSelectionPage(
              cubit: cubit,
              userId: 'user_tourn_multi',
              bypassAutoRedirect: true,
              onAssignmentSelected: (profile) => navigatedAssignment = profile,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Continue to Dashboard
      await tester.tap(find.text('Continue to Dashboard'));
      await tester.pumpAndSettle();

      expect(navigatedAssignment?.roleAssignmentId, equals('assign_ts_001'));

      expect(sessionCubit.state.activeRole, equals(UserRole.tournamentStaff));
      expect(sessionCubit.state.activeRoleAssignmentId, equals('assign_ts_001'));
      expect(sessionCubit.state.activeOrganizationId, equals('org_pac_01'));
      expect(sessionCubit.state.activeOrganizationName, equals('Pacific Pickleball Series'));
      expect(sessionCubit.state.activeTournamentId, equals('tourn_01'));
      expect(sessionCubit.state.activeTournamentName, equals('Mumbai Pickleball Championship 2026'));
    });
  });

  group('Enhanced RoutePlaceholderView Tests', () {
    testWidgets('displays role badge and route path cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RoutePlaceholderView(
            title: 'Coach Dashboard',
            path: '/coach/dashboard',
            role: UserRole.coach,
          ),
        ),
      );

      expect(find.text('Coach Dashboard'), findsOneWidget);
      expect(find.text('Coach'), findsOneWidget);
      expect(find.text('Route Path: /coach/dashboard'), findsOneWidget);
    });
  });
}
