import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/match_day_data.dart';

/// Available tabs on the Match Day hub screen.
enum MatchDayTab {
  mySchedule('My Schedule'),
  liveScores('Live Courts'),
  bracketStandings('Bracket & Pools');

  final String label;
  const MatchDayTab(this.label);
}

/// Sealed state hierarchy for the Match Day screen.
sealed class MatchDayState extends Equatable {
  const MatchDayState();

  @override
  List<Object?> get props => [];
}

class MatchDayInitial extends MatchDayState {
  const MatchDayInitial();
}

class MatchDayLoading extends MatchDayState {
  const MatchDayLoading();
}

class MatchDayLoaded extends MatchDayState {
  final PlayerMatchDayData data;
  final MatchDayTab activeTab;
  final String? checkingInMatchId;
  final String? feedbackMessage;

  const MatchDayLoaded({
    required this.data,
    this.activeTab = MatchDayTab.mySchedule,
    this.checkingInMatchId,
    this.feedbackMessage,
  });

  bool get isEmpty => data.myMatches.isEmpty && data.courtMatches.isEmpty;

  MatchDayLoaded copyWith({
    PlayerMatchDayData? data,
    MatchDayTab? activeTab,
    String? checkingInMatchId,
    String? feedbackMessage,
    bool clearCheckingIn = false,
    bool clearFeedback = false,
  }) {
    return MatchDayLoaded(
      data: data ?? this.data,
      activeTab: activeTab ?? this.activeTab,
      checkingInMatchId:
          clearCheckingIn ? null : (checkingInMatchId ?? this.checkingInMatchId),
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
    );
  }

  @override
  List<Object?> get props => [
        data,
        activeTab,
        checkingInMatchId,
        feedbackMessage,
      ];
}

class MatchDayFailure extends MatchDayState {
  final String message;

  const MatchDayFailure(this.message);

  @override
  List<Object?> get props => [message];
}
