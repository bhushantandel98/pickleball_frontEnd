import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/entities/tournament_organizer_entities.dart';
import 'package:pickleball_platform/features/tournament_organizer/domain/repositories/tournament_organizer_repository.dart';
import 'package:pickleball_platform/features/tournament_organizer/presentation/bloc/tournament_organizer_state.dart';

/// Cubit managing Tournament Organizer workflows (Phase 5 — Feature 5.1).
class TournamentOrganizerCubit extends Cubit<TournamentOrganizerState> {
  final TournamentOrganizerRepository repository;

  TournamentOrganizerCubit({required this.repository})
      : super(const TournamentOrganizerInitial());

  Future<void> loadWorkspace({
    required String organizerId,
    String? initialTournamentId,
  }) async {
    emit(const TournamentOrganizerLoading());
    final res = await repository.getWorkspace(organizerId: organizerId);
    switch (res) {
      case Success(:final data):
        emit(
          TournamentOrganizerLoaded(
            data: data,
            selectedTournamentId: initialTournamentId ??
                (data.tournaments.isNotEmpty ? data.tournaments.first.id : null),
          ),
        );
      case FailureResult(:final failure):
        emit(TournamentOrganizerFailure(failure));
    }
  }

  Future<void> refreshWorkspace({String? organizerId}) async {
    final current = state;
    final resolvedId = organizerId ??
        (current is TournamentOrganizerLoaded
            ? current.data.organizerId
            : 'org_tourn_001');
    final res = await repository.getWorkspace(organizerId: resolvedId);
    switch (res) {
      case Success(:final data):
        if (current is TournamentOrganizerLoaded) {
          emit(current.copyWith(data: data, clearFeedback: true));
        } else {
          emit(TournamentOrganizerLoaded(data: data));
        }
      case FailureResult(:final failure):
        emit(TournamentOrganizerFailure(failure));
    }
  }

  void selectTournament(String tournamentId) {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return;
    final selected =
        current.data.tournaments.where((t) => t.id == tournamentId).firstOrNull;
    emit(
      current.copyWith(
        selectedTournamentId: tournamentId,
        selectedCategoryId: selected != null && selected.categories.isNotEmpty
            ? selected.categories.first.id
            : null,
        clearFeedback: true,
      ),
    );
  }

  void selectCategory(String categoryId) {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return;
    emit(current.copyWith(selectedCategoryId: categoryId, clearFeedback: true));
  }

  void clearFeedback() {
    final current = state;
    if (current is TournamentOrganizerLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<bool> createTournament(OrganizerTournament tournament) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.createTournament(
      organizerId: current.data.organizerId,
      tournament: tournament,
    );
    return _apply(res, 'Tournament "${tournament.name}" created.');
  }

  Future<bool> updateTournamentStatus({
    required String tournamentId,
    required OrganizerTournamentStatus status,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.updateTournamentStatus(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      status: status,
    );
    return _apply(res, 'Tournament status updated to ${status.label}.');
  }

  Future<bool> addCategory({
    required String tournamentId,
    required OrganizerCategoryConfig category,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.addCategory(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      category: category,
    );
    return _apply(res, 'Category "${category.name}" added.');
  }

  Future<bool> submitAutoRegistration({
    required String tournamentId,
    required String categoryId,
    required String playerName,
    String? partnerOrTeamName,
    required String playerEmail,
    required String playerPhone,
    required double playerRating,
    required int playerAge,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.submitAutoRegistration(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      categoryId: categoryId,
      playerName: playerName,
      partnerOrTeamName: partnerOrTeamName,
      playerEmail: playerEmail,
      playerPhone: playerPhone,
      playerRating: playerRating,
      playerAge: playerAge,
    );
    return _apply(res, 'Registration processed and confirmed.');
  }

  Future<bool> generateDraw({
    required String tournamentId,
    required String categoryId,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.generateDraw(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      categoryId: categoryId,
    );
    return _apply(res, 'Draw generated and matches scheduled.');
  }

  Future<bool> swapSeedOrder({
    required String tournamentId,
    required String categoryId,
    required int indexA,
    required int indexB,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.swapSeedOrder(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      categoryId: categoryId,
      indexA: indexA,
      indexB: indexB,
    );
    return _apply(res, 'Seeding order updated.');
  }

  Future<bool> assignMatchScheduleAndReferee({
    required String tournamentId,
    required String matchId,
    required String courtName,
    required DateTime scheduledTime,
    String? refereeAssignmentId,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.assignMatchScheduleAndReferee(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      matchId: matchId,
      courtName: courtName,
      scheduledTime: scheduledTime,
      refereeAssignmentId: refereeAssignmentId,
    );
    return _apply(res, 'Court schedule and referee updated.');
  }

  Future<bool> updateMatchScore({
    required String tournamentId,
    required String matchId,
    required String scoreSummary,
    required String winnerLabel,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.updateMatchScore(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      matchId: matchId,
      scoreSummary: scoreSummary,
      winnerLabel: winnerLabel,
    );
    return _apply(res, 'Match score recorded.');
  }

  Future<bool> addStaffOrReferee({
    required String tournamentId,
    required String name,
    required String email,
    required OrganizerStaffRole role,
    required Set<String> delegatedPermissions,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.addStaffOrReferee(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      name: name,
      email: email,
      role: role,
      delegatedPermissions: delegatedPermissions,
    );
    return _apply(res, '${role.label} "$name" assigned.');
  }

  Future<bool> toggleStaffActive({
    required String tournamentId,
    required String assignmentId,
    required bool isActive,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.toggleStaffActive(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      assignmentId: assignmentId,
      isActive: isActive,
    );
    return _apply(
      res,
      isActive ? 'Personnel activated.' : 'Personnel deactivated.',
    );
  }

  Future<bool> updateStaffPermissions({
    required String tournamentId,
    required String assignmentId,
    required Set<String> delegatedPermissions,
  }) async {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    final res = await repository.updateStaffPermissions(
      organizerId: current.data.organizerId,
      tournamentId: tournamentId,
      assignmentId: assignmentId,
      delegatedPermissions: delegatedPermissions,
    );
    return _apply(res, 'Delegated permissions updated.');
  }

  bool _apply(
    Result<TournamentOrganizerWorkspaceData> res,
    String successMessage,
  ) {
    final current = state;
    if (current is! TournamentOrganizerLoaded) return false;
    switch (res) {
      case Success(:final data):
        emit(
          current.copyWith(
            data: data,
            feedbackMessage: successMessage,
            isErrorFeedback: false,
          ),
        );
        return true;
      case FailureResult(:final failure):
        emit(
          current.copyWith(
            feedbackMessage: failure.message,
            isErrorFeedback: true,
          ),
        );
        return false;
    }
  }
}
