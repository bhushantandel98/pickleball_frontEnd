import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/referee/domain/entities/referee_entities.dart';
import 'package:pickleball_platform/features/referee/domain/repositories/referee_repository.dart';
import 'package:pickleball_platform/features/referee/presentation/bloc/referee_state.dart';

class RefereeCubit extends Cubit<RefereeState> {
  final RefereeRepository _repository;

  RefereeCubit({required RefereeRepository repository})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(const RefereeInitial());

  String? _activeTournamentId;
  String? _activeRefereeId;

  Future<void> loadWorkspace({
    required String tournamentId,
    required String refereeId,
  }) async {
    _activeTournamentId = tournamentId;
    _activeRefereeId = refereeId;
    emit(const RefereeLoading());

    final result = await _repository.getWorkspace(
      tournamentId: tournamentId,
      refereeId: refereeId,
    );

    result.when(
      success: (data) => emit(RefereeLoaded(data: data)),
      failure: (failure) => emit(RefereeFailure(failure.message)),
    );
  }

  Future<void> refreshWorkspace() async {
    final tournamentId = _activeTournamentId;
    final refereeId = _activeRefereeId;
    if (tournamentId == null || refereeId == null) return;
    await loadWorkspace(tournamentId: tournamentId, refereeId: refereeId);
  }

  void clearFeedback() {
    final current = state;
    if (current is RefereeLoaded) {
      emit(current.copyWith(clearFeedback: true, clearError: true));
    }
  }

  Future<void> startMatch(String matchId) async {
    await _runMutation(
      () => _repository.startMatch(
        tournamentId: _activeTournamentId!,
        refereeId: _activeRefereeId!,
        matchId: matchId,
      ),
      successMessage: 'Match started.',
    );
  }

  Future<void> awardPoint(String matchId, String side) async {
    await _runMutation(
      () => _repository.awardPoint(
        tournamentId: _activeTournamentId!,
        refereeId: _activeRefereeId!,
        matchId: matchId,
        side: side,
      ),
    );
  }

  Future<void> switchServe(String matchId) async {
    await _runMutation(
      () => _repository.switchServe(
        tournamentId: _activeTournamentId!,
        refereeId: _activeRefereeId!,
        matchId: matchId,
      ),
    );
  }

  Future<void> submitMatchResult(
    String matchId, {
    String? finalScoreOverride,
    String? winnerOverride,
  }) async {
    await _runMutation(
      () => _repository.submitMatchResult(
        tournamentId: _activeTournamentId!,
        refereeId: _activeRefereeId!,
        matchId: matchId,
        finalScoreOverride: finalScoreOverride,
        winnerOverride: winnerOverride,
      ),
      successMessage: 'Match result submitted and locked.',
    );
  }

  Future<void> _runMutation(
    Future<Result<RefereeWorkspaceData>> Function() action, {
    String? successMessage,
  }) async {
    final current = state;
    final tournamentId = _activeTournamentId;
    final refereeId = _activeRefereeId;
    if (current is! RefereeLoaded ||
        tournamentId == null ||
        refereeId == null) {
      return;
    }

    emit(current.copyWith(isMutating: true, clearFeedback: true, clearError: true));

    final result = await action();
    result.when(
      success: (data) => emit(
        RefereeLoaded(
          data: data,
          isMutating: false,
          feedbackMessage: successMessage,
        ),
      ),
      failure: (failure) => emit(
        current.copyWith(
          isMutating: false,
          errorMessage: failure.message,
        ),
      ),
    );
  }
}
