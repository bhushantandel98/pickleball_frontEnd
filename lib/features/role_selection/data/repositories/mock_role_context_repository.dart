import 'package:flutter/foundation.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/mock/data/mock_data.dart';
import 'package:pickleball_platform/core/mock/mock_network_harness.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/role_selection/domain/entities/role_context.dart';
import 'package:pickleball_platform/features/role_selection/domain/repositories/role_context_repository.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

/// Mock implementation of [RoleContextRepository] for local UI development and testing.
///
/// Implements ADR-011 and ADR-015: Strictly isolated from production builds.
class MockRoleContextRepository implements RoleContextRepository {
  final MockNetworkHarness _harness;
  final RolePreferenceStorage? preferenceStorage;

  MockRoleContextRepository({
    MockNetworkHarness? harness,
    this.preferenceStorage,
  }) : _harness = harness ?? MockNetworkHarness() {
    assert(
      !kReleaseMode,
      'MockRoleContextRepository must NEVER be initialized in release builds (ADR-015)',
    );
  }

  @override
  Future<Result<RoleContext>> getRoleContext(String userId) async {
    return _harness.requestResult<RoleContext>(() async {
      // 0. Zero-role mock user fixture for empty state testing
      if (userId == 'user_zero' || userId == 'user_no_roles') {
        return RoleContext(
          userId: userId,
          displayName: 'Ananya Roy',
          phone: '+91 9123456789',
          email: 'ananya.roy@example.com',
          roleProfiles: const [],
        );
      }

      // 1. Special fixture for multi-org venue staff
      if (userId == 'user_multi_venue_staff') {
        final profiles = [
          const RoleProfile(
            roleAssignmentId: 'assign_vs_grand_slam',
            role: UserRole.venueStaff,
            organizationId: 'org_venue_001',
            organizationName: 'Grand Slam Arena',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_vs_metro_courts',
            role: UserRole.venueStaff,
            organizationId: 'org_venue_002',
            organizationName: 'Metro Court Center',
            isActive: true,
          ),
        ];

        final preferredAssignmentId =
            await preferenceStorage?.getPreferredAssignmentId(userId);

        return RoleContext(
          userId: userId,
          displayName: 'Alex Rivera (Venue Staff)',
          phone: '+91 9876543210',
          email: 'alex.staff@example.com',
          roleProfiles: profiles,
          preferredRoleAssignmentId: preferredAssignmentId,
        );
      }

      // 2. Special fixture for multi-tournament staff
      if (userId == 'user_multi_tournament_staff') {
        final profiles = [
          const RoleProfile(
            roleAssignmentId: 'assign_ts_mumbai',
            role: UserRole.tournamentStaff,
            organizationId: 'org_tourn_001',
            organizationName: 'Pacific Pickleball Series',
            tournamentId: 'tourn_001',
            tournamentName: 'Mumbai Pickleball Championship 2026',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_ts_national',
            role: UserRole.tournamentStaff,
            organizationId: 'org_tourn_002',
            organizationName: 'National Pickleball League',
            tournamentId: 'tourn_002',
            tournamentName: 'Monsoon Open 2026',
            isActive: true,
          ),
        ];

        final preferredAssignmentId =
            await preferenceStorage?.getPreferredAssignmentId(userId);

        return RoleContext(
          userId: userId,
          displayName: 'Sara Connor (Tournament Staff)',
          phone: '+91 9876543211',
          email: 'sara.tourn@example.com',
          roleProfiles: profiles,
          preferredRoleAssignmentId: preferredAssignmentId,
        );
      }

      // 3. Special fixture for multi-tournament organizer
      if (userId == 'user_multi_tournament_org') {
        final profiles = [
          const RoleProfile(
            roleAssignmentId: 'assign_to_mumbai',
            role: UserRole.tournamentOrganizer,
            organizationId: 'org_tourn_001',
            organizationName: 'Pacific Pickleball Series',
            tournamentId: 'tourn_001',
            tournamentName: 'Mumbai Pickleball Championship 2026',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_to_national',
            role: UserRole.tournamentOrganizer,
            organizationId: 'org_tourn_002',
            organizationName: 'National Pickleball League',
            tournamentId: 'tourn_002',
            tournamentName: 'National Pickleball Cup 2026',
            isActive: true,
          ),
        ];

        final preferredAssignmentId =
            await preferenceStorage?.getPreferredAssignmentId(userId);

        return RoleContext(
          userId: userId,
          displayName: 'Samira Khan (Organizer)',
          phone: '+91 9876543212',
          email: 'samira.organizer@example.com',
          roleProfiles: profiles,
          preferredRoleAssignmentId: preferredAssignmentId,
        );
      }

      // 4. Special fixture for multi-academy coach
      if (userId == 'user_multi_academy_coach') {
        final profiles = [
          const RoleProfile(
            roleAssignmentId: 'assign_coach_pinnacle',
            role: UserRole.coach,
            organizationId: 'org_acad_001',
            organizationName: 'Pinnacle Sports Academy',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_coach_smash_point',
            role: UserRole.coach,
            organizationId: 'org_acad_002',
            organizationName: 'Smash Point Academy',
            isActive: true,
          ),
        ];

        final preferredAssignmentId =
            await preferenceStorage?.getPreferredAssignmentId(userId);

        return RoleContext(
          userId: userId,
          displayName: 'Coach David Miller',
          phone: '+91 9876543213',
          email: 'david.coach@example.com',
          roleProfiles: profiles,
          preferredRoleAssignmentId: preferredAssignmentId,
        );
      }

      // 5. Special fixture for comprehensive all 12 platform roles demonstration
      if (userId == 'user_all_12_roles') {
        final profiles = [
          const RoleProfile(
            roleAssignmentId: 'assign_all_player',
            role: UserRole.player,
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_coach',
            role: UserRole.coach,
            organizationId: 'org_acad_001',
            organizationName: 'Pinnacle Sports Academy',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_academy',
            role: UserRole.academy,
            organizationId: 'org_acad_001',
            organizationName: 'Pinnacle Sports Academy',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_academy_staff',
            role: UserRole.academyStaff,
            organizationId: 'org_acad_001',
            organizationName: 'Pinnacle Sports Academy',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_venue_partner',
            role: UserRole.venuePartner,
            organizationId: 'org_venue_001',
            organizationName: 'Grand Slam Arena',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_venue_staff',
            role: UserRole.venueStaff,
            organizationId: 'org_venue_001',
            organizationName: 'Grand Slam Arena',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_tourn_org',
            role: UserRole.tournamentOrganizer,
            organizationId: 'org_tourn_001',
            organizationName: 'Pacific Pickleball Series',
            tournamentId: 'tourn_001',
            tournamentName: 'Mumbai Championship 2026',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_tourn_staff',
            role: UserRole.tournamentStaff,
            organizationId: 'org_tourn_001',
            organizationName: 'Pacific Pickleball Series',
            tournamentId: 'tourn_001',
            tournamentName: 'Mumbai Championship 2026',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_referee',
            role: UserRole.referee,
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_seller',
            role: UserRole.marketplaceSeller,
            organizationId: 'org_seller_001',
            organizationName: 'Apex Paddle & Gear Co.',
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_app_staff',
            role: UserRole.applicationStaff,
            isActive: true,
          ),
          const RoleProfile(
            roleAssignmentId: 'assign_all_app_admin',
            role: UserRole.applicationAdmin,
            isActive: true,
          ),
        ];

        final preferredAssignmentId =
            await preferenceStorage?.getPreferredAssignmentId(userId);

        return RoleContext(
          userId: userId,
          displayName: 'Platform Super User',
          phone: '+91 9876599999',
          email: 'superuser@platform.internal',
          roleProfiles: profiles,
          preferredRoleAssignmentId: preferredAssignmentId,
        );
      }

      // Find matching mock user
      UserProfile? user;
      for (final u in MockData.allUsers) {
        if (u.id == userId) {
          user = u;
          break;
        }
      }

      // Default fallback mock user for unregistered/generic testing
      user ??= MockData.multiRoleUser;

      // Resolve organization and tournament names for organization-scoped roles
      final profiles = <RoleProfile>[];
      for (final role in user.availableRoles) {
        String? orgName;
        String? orgId = user.organizationId;
        String? tournName;
        String? tournId;

        if (role == UserRole.academy || role == UserRole.academyStaff) {
          orgName = 'Pinnacle Sports Academy';
          orgId ??= 'org_acad_001';
        } else if (role == UserRole.coach) {
          orgName = 'Pinnacle Sports Academy';
          orgId ??= 'org_acad_001';
        } else if (role == UserRole.venuePartner ||
            role == UserRole.venueStaff) {
          orgName = 'Grand Slam Arena';
          orgId ??= 'org_venue_001';
        } else if (role == UserRole.tournamentOrganizer ||
            role == UserRole.tournamentStaff) {
          orgName = 'Pacific Pickleball Series';
          orgId ??= 'org_tourn_001';
          tournName = 'Mumbai Pickleball Championship';
          tournId = 'tourn_001';
        } else if (role == UserRole.marketplaceSeller) {
          orgName = 'Apex Paddle & Gear Co.';
          orgId ??= 'org_seller_001';
        }

        final assignmentId = 'assign_${role.id}_${orgId ?? "default"}';

        profiles.add(
          RoleProfile(
            roleAssignmentId: assignmentId,
            role: role,
            organizationId: orgId,
            organizationName: orgName,
            tournamentId: tournId,
            tournamentName: tournName,
            isActive: !user.isSuspended,
          ),
        );
      }

      // Check saved preferred role and assignment
      String? preferredAssignmentId;
      UserRole? preferredRole;
      if (preferenceStorage != null) {
        preferredAssignmentId =
            await preferenceStorage!.getPreferredAssignmentId(userId);
        preferredRole = await preferenceStorage!.getPreferredRole(userId);
      }

      return RoleContext(
        userId: user.id,
        displayName: user.name,
        phone: user.phone,
        email: user.email,
        roleProfiles: profiles,
        preferredRoleAssignmentId: preferredAssignmentId,
        preferredRole: preferredRole,
      );
    });
  }

  @override
  Future<Result<void>> selectPreferredRole({
    required String userId,
    required String roleAssignmentId,
    UserRole? role,
  }) async {
    return _harness.requestResult<void>(() async {
      if (preferenceStorage != null) {
        await preferenceStorage!.setPreferredAssignmentId(
            userId, roleAssignmentId);
        if (role != null) {
          await preferenceStorage!.setPreferredRole(userId, role);
        }
      }
    });
  }

  @override
  Future<Result<void>> clearPreferredRole(String userId) async {
    return _harness.requestResult<void>(() async {
      if (preferenceStorage != null) {
        await preferenceStorage!.clearPreferredAssignmentId(userId);
        await preferenceStorage!.clearPreferredRole(userId);
      }
    });
  }
}
