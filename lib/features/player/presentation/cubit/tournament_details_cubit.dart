import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/tournament_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/tournament_details_state.dart';

class TournamentDetailsCubit extends Cubit<TournamentDetailsState> {
  final TournamentRepository repository;
  final String tournamentId;

  TournamentDetailsCubit({
    required this.repository,
    required this.tournamentId,
  }) : super(const TournamentDetailsInitial());

  /// Loads tournament details and checks for player's active registration.
  Future<void> loadTournament({bool isRefresh = false}) async {
    if (!isRefresh && state is! TournamentDetailsLoaded) {
      emit(const TournamentDetailsLoading());
    }

    final result = await repository.getTournamentById(tournamentId);
    switch (result) {
      case Success<TournamentItem>(:final data):
        // Check player registrations
        final regsResult = await repository.getMyRegistrations();
        TournamentRegistration? matchingReg;
        if (regsResult is Success<List<TournamentRegistration>>) {
          final activeRegs = regsResult.data.where(
            (r) =>
                r.tournamentId == tournamentId &&
                r.status != TournamentRegistrationStatus.withdrawn,
          );
          if (activeRegs.isNotEmpty) {
            matchingReg = activeRegs.first;
          }
        }

        emit(TournamentDetailsLoaded(
          tournament: data,
          playerRegistration: matchingReg,
        ));
      case FailureResult(:final failure):
        emit(TournamentDetailsFailure(failure.message));
    }
  }

  /// Withdraws player from tournament.
  Future<bool> withdraw(String registrationId) async {
    if (state is! TournamentDetailsLoaded) return false;
    final current = state as TournamentDetailsLoaded;

    emit(current.copyWith(isWithdrawing: true));

    final result = await repository.withdrawFromTournament(registrationId);
    switch (result) {
      case Success<TournamentRegistration>():
        // Refresh tournament details to sync spot counts
        final tResult = await repository.getTournamentById(tournamentId);
        final updatedTournament =
            tResult is Success<TournamentItem> ? tResult.data : current.tournament;

        emit(current.copyWith(
          tournament: updatedTournament,
          isWithdrawing: false,
          clearRegistration: true,
          feedbackMessage: 'Successfully withdrawn from tournament entry.',
        ));
        return true;
      case FailureResult(:final failure):
        emit(current.copyWith(
          isWithdrawing: false,
          feedbackMessage: failure.message,
        ));
        return false;
    }
  }

  void clearFeedback() {
    if (state is TournamentDetailsLoaded) {
      emit((state as TournamentDetailsLoaded).copyWith(clearFeedback: true));
    }
  }
}
