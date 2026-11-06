import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/session_context.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/features/role_selection/domain/entities/role_context.dart';

class _SessionNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Cubit managing session authentication state, active role, and multi-role switching.
///
/// Exposes a [refreshListenable] compatible with GoRouter's reactive route evaluation.
class SessionCubit extends Cubit<SessionContext> {
  final RolePreferenceStorage? preferenceStorage;
  final _SessionNotifier _notifier = _SessionNotifier();

  SessionCubit({
    this.preferenceStorage,
    SessionContext initialState = const SessionContext.unauthenticated(),
  }) : super(initialState);

  /// Reactive [Listenable] that triggers GoRouter route re-evaluation on state change.
  Listenable get refreshListenable => _notifier;

  @override
  void emit(SessionContext state) {
    super.emit(state);
    _notifier.notify();
  }

  /// Authenticates a session with assigned roles and optional initial active role.
  Future<void> signIn({
    required String userId,
    required String email,
    String? displayName,
    required List<UserRole> roles,
    UserRole? activeRole,
    String? roleAssignmentId,
    String? organizationId,
    String? organizationName,
    String? tournamentId,
    String? tournamentName,
    bool isSuspended = false,
    bool rememberPreferredRole = false,
  }) async {
    UserRole? effectiveRole = activeRole;
    String? effectiveAssignmentId = roleAssignmentId;

    if (effectiveRole == null && preferenceStorage != null && !isSuspended) {
      final savedAssignmentId =
          await preferenceStorage!.getPreferredAssignmentId(userId);
      if (savedAssignmentId != null) {
        effectiveAssignmentId = savedAssignmentId;
      }
      final savedRole = await preferenceStorage!.getPreferredRole(userId);
      if (savedRole != null && roles.contains(savedRole)) {
        effectiveRole = savedRole;
      }
    }

    if (isSuspended) {
      emit(SessionContext.suspended(
        userId: userId,
        email: email,
        displayName: displayName,
        availableRoles: roles,
        activeRole: effectiveRole,
        activeRoleAssignmentId: effectiveAssignmentId,
        activeOrganizationId: organizationId,
        activeOrganizationName: organizationName,
        activeTournamentId: tournamentId,
        activeTournamentName: tournamentName,
      ));
    } else {
      emit(SessionContext.authenticated(
        userId: userId,
        email: email,
        displayName: displayName,
        availableRoles: roles,
        activeRole: effectiveRole,
        activeRoleAssignmentId: effectiveAssignmentId,
        activeOrganizationId: organizationId,
        activeOrganizationName: organizationName,
        activeTournamentId: tournamentId,
        activeTournamentName: tournamentName,
        rememberPreferredRole: rememberPreferredRole,
      ));
    }
  }

  /// Sets the complete active role context from a selected [RoleProfile].
  ///
  /// Preserves role, assignment ID, organization scoping, and tournament scoping.
  /// Automatically clears old tournament/organization contexts if the newly selected
  /// role is not scoped to a tournament or organization.
  Future<void> setActiveRoleProfile(RoleProfile profile) async {
    if (!state.isAuthenticated) return;
    if (!state.availableRoles.contains(profile.role)) return;

    emit(state.copyWith(
      activeRole: profile.role,
      activeRoleAssignmentId: profile.roleAssignmentId,
      activeOrganizationId: profile.organizationId,
      clearActiveOrganizationId: profile.organizationId == null,
      activeOrganizationName: profile.organizationName,
      clearActiveOrganizationName: profile.organizationName == null,
      activeTournamentId: profile.tournamentId,
      clearActiveTournamentId: profile.tournamentId == null,
      activeTournamentName: profile.tournamentName,
      clearActiveTournamentName: profile.tournamentName == null,
    ));

    if (state.rememberPreferredRole &&
        state.userId != null &&
        preferenceStorage != null) {
      await preferenceStorage!.setPreferredAssignmentId(
        state.userId!,
        profile.roleAssignmentId,
      );
      await preferenceStorage!.setPreferredRole(state.userId!, profile.role);
    }
  }

  /// Switches the active role to [newRole].
  ///
  /// Only switches if [newRole] is present in [state.availableRoles].
  Future<void> switchRole(UserRole newRole) async {
    if (!state.isAuthenticated) return;
    if (!state.availableRoles.contains(newRole)) return;

    emit(state.copyWith(activeRole: newRole));

    if (state.rememberPreferredRole &&
        state.userId != null &&
        preferenceStorage != null) {
      await preferenceStorage!.setPreferredRole(state.userId!, newRole);
    }
  }

  /// Sets whether the preferred role should be remembered.
  Future<void> setRememberPreferredRole(bool remember) async {
    emit(state.copyWith(rememberPreferredRole: remember));

    if (preferenceStorage == null || state.userId == null) return;

    if (remember && state.activeRole != null) {
      await preferenceStorage!.setPreferredRole(
        state.userId!,
        state.activeRole!,
      );
    } else if (!remember) {
      await preferenceStorage!.clearPreferredRole(state.userId!);
    }
  }

  /// Clears active role to require explicit role selection.
  void clearActiveRole() {
    emit(state.copyWith(clearActiveRole: true));
  }

  /// Toggles or updates suspension status.
  void setSuspended(bool isSuspended) {
    emit(state.copyWith(isSuspended: isSuspended));
  }

  /// Sets active organization scope and optional organization name.
  void setOrganization(String? organizationId, [String? organizationName]) {
    emit(state.copyWith(
      activeOrganizationId: organizationId,
      clearActiveOrganizationId: organizationId == null,
      activeOrganizationName: organizationName,
      clearActiveOrganizationName: organizationName == null,
    ));
  }

  /// Signs out of the current session and resets state to unauthenticated.
  void signOut() {
    emit(const SessionContext.unauthenticated());
  }

  @override
  Future<void> close() {
    _notifier.dispose();
    return super.close();
  }
}
