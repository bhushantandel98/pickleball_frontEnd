import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/tournament_staff/domain/repositories/tournament_staff_repository.dart';
import 'package:pickleball_platform/features/tournament_staff/presentation/cubit/tournament_staff_state.dart';

/// Cubit managing delegated Tournament Staff operations (Phase 5 — Feature 5.2).
class TournamentStaffCubit extends Cubit<TournamentStaffState> {
  final TournamentStaffRepository repository;

  TournamentStaffCubit({required this.repository})
      : super(const TournamentStaffInitial());

  Future<void> loadWorkspace({
    required String tournamentId,
    required String staffId,
  }) async {
    emit(const TournamentStaffLoading());
    final res = await repository.getWorkspace(
      tournamentId: tournamentId,
      staffId: staffId,
    );
    switch (res) {
      case Success(:final data):
        emit(TournamentStaffLoaded(data: data));
      case FailureResult(:final failure):
        emit(TournamentStaffFailure(failure));
    }
  }

  Future<void> refreshWorkspace({
    String? tournamentId,
    String? staffId,
  }) async {
    final current = state;
    final resolvedTournamentId = tournamentId ??
        (current is TournamentStaffLoaded
            ? current.staffProfile.tournamentId
            : null);
    final resolvedStaffId = staffId ??
        (current is TournamentStaffLoaded
            ? current.staffProfile.staffId
            : null);

    if (resolvedTournamentId == null ||
        resolvedTournamentId.trim().isEmpty ||
        resolvedStaffId == null ||
        resolvedStaffId.trim().isEmpty) {
      emit(
        const TournamentStaffFailure(
          ForbiddenFailure(
            message: 'Missing authenticated tournament staff context.',
          ),
        ),
      );
      return;
    }

    final res = await repository.getWorkspace(
      tournamentId: resolvedTournamentId,
      staffId: resolvedStaffId,
    );
    switch (res) {
      case Success(:final data):
        if (current is TournamentStaffLoaded) {
          emit(current.copyWith(data: data, clearFeedback: true));
        } else {
          emit(TournamentStaffLoaded(data: data));
        }
      case FailureResult(:final failure):
        emit(TournamentStaffFailure(failure));
    }
  }

  void clearFeedback() {
    final current = state;
    if (current is TournamentStaffLoaded && current.feedbackMessage != null) {
      emit(current.copyWith(clearFeedback: true));
    }
  }

  Future<bool> toggleCheckIn({
    required String checkInId,
    required bool isCheckedIn,
  }) async {
    final current = state;
    if (current is! TournamentStaffLoaded) return false;
    final res = await repository.toggleCheckIn(
      tournamentId: current.staffProfile.tournamentId,
      staffId: current.staffProfile.staffId,
      checkInId: checkInId,
      isCheckedIn: isCheckedIn,
    );
    return _apply(
      res,
      isCheckedIn ? 'Participant checked in.' : 'Check-in reverted.',
    );
  }

  Future<bool> assignMatchReferee({
    required String matchId,
    required String refereeAssignmentId,
  }) async {
    final current = state;
    if (current is! TournamentStaffLoaded) return false;
    final res = await repository.assignMatchReferee(
      tournamentId: current.staffProfile.tournamentId,
      staffId: current.staffProfile.staffId,
      matchId: matchId,
      refereeAssignmentId: refereeAssignmentId,
    );
    return _apply(res, 'Match referee assignment updated.');
  }

  Future<bool> correctMatchScore({
    required String matchId,
    required String scoreSummary,
    required String winnerLabel,
    required String correctionReason,
  }) async {
    final current = state;
    if (current is! TournamentStaffLoaded) return false;
    final res = await repository.correctMatchScore(
      tournamentId: current.staffProfile.tournamentId,
      staffId: current.staffProfile.staffId,
      matchId: matchId,
      scoreSummary: scoreSummary,
      winnerLabel: winnerLabel,
      correctionReason: correctionReason,
    );
    return _apply(res, 'Match score corrected.');
  }

  bool _apply(Result<dynamic> res, String successMsg) {
    final current = state;
    if (current is! TournamentStaffLoaded) return false;
    switch (res) {
      case Success(:final data):
        emit(
          current.copyWith(
            data: data,
            feedbackMessage: successMsg,
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
