import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/access/role_preference_storage.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/router/role_dashboard_router.dart';
import 'package:pickleball_platform/features/role_selection/domain/entities/role_context.dart';
import 'package:pickleball_platform/features/role_selection/domain/repositories/role_context_repository.dart';

/// Presentation state hierarchy for the Role Selection flow.
sealed class RoleSelectionState extends Equatable {
  const RoleSelectionState();

  @override
  List<Object?> get props => [];
}

/// Initial uninitialized state.
final class RoleSelectionInitial extends RoleSelectionState {
  const RoleSelectionInitial();
}

/// Loading role assignments and preferences.
final class RoleSelectionLoading extends RoleSelectionState {
  const RoleSelectionLoading();
}

/// User has no active roles assigned (empty state).
final class RoleSelectionEmpty extends RoleSelectionState {
  final String userId;
  final String displayName;
  final String phone;
  final String message;

  const RoleSelectionEmpty({
    required this.userId,
    required this.displayName,
    required this.phone,
    this.message =
        'Your account currently has no active platform roles assigned. '
        'Please contact platform support or an organization administrator.',
  });

  @override
  List<Object?> get props => [userId, displayName, phone, message];
}

/// Multi-role selection view ready for user interaction.
final class RoleSelectionLoaded extends RoleSelectionState {
  final RoleContext roleContext;
  final String? selectedAssignmentId;
  final bool rememberChoice;
  final bool isSubmitting;
  final String? errorMessage;

  const RoleSelectionLoaded({
    required this.roleContext,
    this.selectedAssignmentId,
    this.rememberChoice = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  /// Currently selected assignment profile.
  RoleProfile? get selectedAssignment => selectedAssignmentId != null
      ? roleContext.profileForAssignment(selectedAssignmentId!)
      : null;

  /// Selected role enum for backwards compatibility.
  UserRole? get selectedRole => selectedAssignment?.role;

  RoleSelectionLoaded copyWith({
    RoleContext? roleContext,
    String? selectedAssignmentId,
    UserRole? selectedRole,
    bool? rememberChoice,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    String? resolvedAssignmentId =
        selectedAssignmentId ?? this.selectedAssignmentId;
    if (selectedRole != null && selectedAssignmentId == null) {
      final match = roleContext?.profileFor(selectedRole) ??
          this.roleContext.profileFor(selectedRole);
      if (match != null) {
        resolvedAssignmentId = match.roleAssignmentId;
      }
    }

    return RoleSelectionLoaded(
      roleContext: roleContext ?? this.roleContext,
      selectedAssignmentId: resolvedAssignmentId,
      rememberChoice: rememberChoice ?? this.rememberChoice,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        roleContext,
        selectedAssignmentId,
        rememberChoice,
        isSubmitting,
        errorMessage,
      ];
}

/// Decision made: automatically redirect to the designated role dashboard.
final class RoleSelectionRedirect extends RoleSelectionState {
  final RoleProfile selectedAssignment;
  final String destinationPath;
  final RoleContext roleContext;

  const RoleSelectionRedirect({
    required this.selectedAssignment,
    required this.destinationPath,
    required this.roleContext,
  });

  UserRole get targetRole => selectedAssignment.role;
  String? get organizationId => selectedAssignment.organizationId;
  String get roleAssignmentId => selectedAssignment.roleAssignmentId;

  @override
  List<Object?> get props => [
        selectedAssignment,
        destinationPath,
        roleContext,
      ];
}

/// Failure fetching role context.
final class RoleSelectionFailure extends RoleSelectionState {
  final String message;

  const RoleSelectionFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Cubit managing role assignment resolution, preferred assignment evaluation,
/// and dashboard dispatching.
class RoleSelectionCubit extends Cubit<RoleSelectionState> {
  final RoleContextRepository repository;
  final RolePreferenceStorage? preferenceStorage;

  RoleSelectionCubit({
    required this.repository,
    this.preferenceStorage,
  }) : super(const RoleSelectionInitial());

  /// Loads role context for [userId] and resolves the appropriate navigation state:
  /// - If 0 active assignments -> emits [RoleSelectionEmpty].
  /// - If exactly 1 active assignment -> auto-continues to its dashboard via [RoleSelectionRedirect].
  /// - If multiple active assignments and valid remembered assignment exists -> auto-continues to that assignment.
  /// - If multiple active assignments and no remembered choice (or remembered assignment revoked) -> emits [RoleSelectionLoaded].
  /// - Pass [bypassAutoRedirect] = true when user explicitly navigated back to switch roles.
  Future<void> loadRoleContext({
    required String userId,
    bool bypassAutoRedirect = false,
  }) async {
    emit(const RoleSelectionLoading());

    final result = await repository.getRoleContext(userId);

    await result.when(
      success: (context) async {
        final activeProfiles = context.activeProfiles;

        // 1. No active roles assigned
        if (activeProfiles.isEmpty) {
          emit(
            RoleSelectionEmpty(
              userId: context.userId,
              displayName: context.displayName,
              phone: context.phone,
            ),
          );
          return;
        }

        // 2. Exactly one active role assignment -> Auto continue
        if (activeProfiles.length == 1 && !bypassAutoRedirect) {
          final singleProfile = activeProfiles.first;
          emit(
            RoleSelectionRedirect(
              selectedAssignment: singleProfile,
              destinationPath:
                  RoleDashboardRouter.getDashboardRoute(singleProfile.role),
              roleContext: context,
            ),
          );
          return;
        }

        // 3. Multiple active assignments -> Check remembered preference
        if (!bypassAutoRedirect) {
          String? preferredAssignmentId = context.preferredRoleAssignmentId;
          if (preferredAssignmentId == null && preferenceStorage != null) {
            preferredAssignmentId =
                await preferenceStorage!.getPreferredAssignmentId(userId);
          }

          RoleProfile? matchingProfile;
          if (preferredAssignmentId != null) {
            matchingProfile =
                context.profileForAssignment(preferredAssignmentId);
            if (matchingProfile != null && !matchingProfile.isActive) {
              matchingProfile = null;
            }
          }

          // Fallback check to role-level preference if specific assignment was not remembered
          if (matchingProfile == null) {
            UserRole? preferredRole = context.preferredRole;
            if (preferredRole == null && preferenceStorage != null) {
              preferredRole =
                  await preferenceStorage!.getPreferredRole(userId);
            }
            if (preferredRole != null) {
              final candidates = activeProfiles
                  .where((p) => p.role == preferredRole)
                  .toList();
              if (candidates.length == 1) {
                matchingProfile = candidates.first;
              }
            }
          }

          // Auto-continue ONLY if remembered assignment is still valid & active
          if (matchingProfile != null) {
            emit(
              RoleSelectionRedirect(
                selectedAssignment: matchingProfile,
                destinationPath:
                    RoleDashboardRouter.getDashboardRoute(matchingProfile.role),
                roleContext: context,
              ),
            );
            return;
          }
        }

        // 4. Multiple active assignments without valid remembered choice -> Display selection UI
        emit(
          RoleSelectionLoaded(
            roleContext: context,
            selectedAssignmentId: activeProfiles.first.roleAssignmentId,
            rememberChoice: false,
          ),
        );
      },
      failure: (failure) async {
        emit(RoleSelectionFailure(message: failure.message));
      },
    );
  }

  /// Selects a specific role assignment in the UI.
  void selectAssignment(String assignmentId) {
    final current = state;
    if (current is! RoleSelectionLoaded) return;
    final profile = current.roleContext.profileForAssignment(assignmentId);
    if (profile == null || !profile.isActive) return;

    emit(current.copyWith(
      selectedAssignmentId: assignmentId,
      clearError: true,
    ));
  }

  /// Selects a candidate role enum in the UI (backwards-compatible convenience).
  void selectRole(UserRole role) {
    final current = state;
    if (current is! RoleSelectionLoaded) return;
    final matching =
        current.roleContext.activeProfiles.where((p) => p.role == role).firstOrNull;
    if (matching != null) {
      selectAssignment(matching.roleAssignmentId);
    }
  }

  /// Toggles the "Remember my choice" preference switch.
  void toggleRememberChoice(bool value) {
    final current = state;
    if (current is! RoleSelectionLoaded) return;

    emit(current.copyWith(rememberChoice: value));
  }

  /// Confirms the active role assignment choice and triggers navigation redirect.
  Future<void> confirmRoleSelection() async {
    final current = state;
    if (current is! RoleSelectionLoaded) return;

    final assignment = current.selectedAssignment;
    if (assignment == null || !assignment.isActive) {
      emit(current.copyWith(
          errorMessage: 'Please select an operating role assignment'));
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearError: true));

    if (current.rememberChoice) {
      await repository.selectPreferredRole(
        userId: current.roleContext.userId,
        roleAssignmentId: assignment.roleAssignmentId,
        role: assignment.role,
      );
      if (preferenceStorage != null) {
        await preferenceStorage!.setPreferredAssignmentId(
          current.roleContext.userId,
          assignment.roleAssignmentId,
        );
        await preferenceStorage!.setPreferredRole(
          current.roleContext.userId,
          assignment.role,
        );
      }
    } else {
      await repository.clearPreferredRole(current.roleContext.userId);
      if (preferenceStorage != null) {
        await preferenceStorage!
            .clearPreferredAssignmentId(current.roleContext.userId);
        await preferenceStorage!
            .clearPreferredRole(current.roleContext.userId);
      }
    }

    emit(
      RoleSelectionRedirect(
        selectedAssignment: assignment,
        destinationPath:
            RoleDashboardRouter.getDashboardRoute(assignment.role),
        roleContext: current.roleContext,
      ),
    );
  }
}
