import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/tournament_item.dart';

sealed class TournamentDetailsState extends Equatable {
  const TournamentDetailsState();

  @override
  List<Object?> get props => [];
}

class TournamentDetailsInitial extends TournamentDetailsState {
  const TournamentDetailsInitial();
}

class TournamentDetailsLoading extends TournamentDetailsState {
  const TournamentDetailsLoading();
}

class TournamentDetailsLoaded extends TournamentDetailsState {
  final TournamentItem tournament;
  final double playerRating;
  final int playerAge;
  final TournamentRegistration? playerRegistration;
  final bool isWithdrawing;
  final String? feedbackMessage;

  const TournamentDetailsLoaded({
    required this.tournament,
    this.playerRating = 3.85,
    this.playerAge = 28,
    this.playerRegistration,
    this.isWithdrawing = false,
    this.feedbackMessage,
  });

  /// Evaluates whether the player is eligible to enter the given category.
  bool isCategoryEligible(TournamentCategory category) {
    return category.isRatingEligible(playerRating) &&
        category.isAgeEligible(playerAge);
  }

  TournamentDetailsLoaded copyWith({
    TournamentItem? tournament,
    double? playerRating,
    int? playerAge,
    TournamentRegistration? playerRegistration,
    bool? isWithdrawing,
    String? feedbackMessage,
    bool clearRegistration = false,
    bool clearFeedback = false,
  }) {
    return TournamentDetailsLoaded(
      tournament: tournament ?? this.tournament,
      playerRating: playerRating ?? this.playerRating,
      playerAge: playerAge ?? this.playerAge,
      playerRegistration: clearRegistration
          ? null
          : (playerRegistration ?? this.playerRegistration),
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        tournament,
        playerRating,
        playerAge,
        playerRegistration,
        isWithdrawing,
        feedbackMessage,
      ];
}

class TournamentDetailsFailure extends TournamentDetailsState {
  final String message;

  const TournamentDetailsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
