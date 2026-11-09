import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/match_day_data.dart';
import 'package:pickleball_platform/features/player/domain/repositories/match_day_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/match_day_state.dart';

/// Cubit coordinating tournament Match Day operations, live score streaming simulation, and check-in.
class MatchDayCubit extends Cubit<MatchDayState> {
  final MatchDayRepository repository;

  MatchDayCubit({required this.repository}) : super(const MatchDayInitial());

  /// Loads match day fixtures, court live statuses, standings, and brackets.
  Future<void> loadMatchDay({bool isRefresh = false, String? playerId}) async {
    if (!isRefresh && state is! MatchDayLoaded) {
      emit(const MatchDayLoading());
    }

    final result = await repository.getMatchDayData(playerId: playerId);
    switch (result) {
      case Success<PlayerMatchDayData>(:final data):
        final activeTab = state is MatchDayLoaded
            ? (state as MatchDayLoaded).activeTab
            : MatchDayTab.mySchedule;
        emit(MatchDayLoaded(
          data: data,
          activeTab: activeTab,
        ));
      case FailureResult(:final failure):
        emit(MatchDayFailure(failure.message));
    }
  }

  /// Sets active view tab (My Schedule, Live Courts, Bracket & Pools).
  void setTab(MatchDayTab tab) {
    if (state is MatchDayLoaded) {
      emit((state as MatchDayLoaded).copyWith(
        activeTab: tab,
        clearFeedback: true,
      ));
    }
  }

  /// Checks the player in for a specific match fixture.
  Future<bool> checkIn(String matchId) async {
    if (state is! MatchDayLoaded) return false;
    final current = state as MatchDayLoaded;

    emit(current.copyWith(checkingInMatchId: matchId));

    final result = await repository.checkInToMatch(matchId);
    switch (result) {
      case Success<PlayerMatch>(:final data):
        final updatedMatches = current.data.myMatches.map((m) {
          return m.id == data.id ? data : m;
        }).toList();

        final updatedData = PlayerMatchDayData(
          tournamentId: current.data.tournamentId,
          tournamentName: current.data.tournamentName,
          tournamentVenue: current.data.tournamentVenue,
          date: current.data.date,
          myMatches: updatedMatches,
          courtMatches: current.data.courtMatches,
          standings: current.data.standings,
          bracket: current.data.bracket,
        );

        emit(current.copyWith(
          data: updatedData,
          clearCheckingIn: true,
          feedbackMessage: 'Checked in successfully for ${data.round}!',
        ));
        return true;
      case FailureResult(:final failure):
        emit(current.copyWith(
          clearCheckingIn: true,
          feedbackMessage: failure.message,
        ));
        return false;
    }
  }

  /// Clears transient feedback messages.
  void clearFeedback() {
    if (state is MatchDayLoaded) {
      emit((state as MatchDayLoaded).copyWith(clearFeedback: true));
    }
  }
}
