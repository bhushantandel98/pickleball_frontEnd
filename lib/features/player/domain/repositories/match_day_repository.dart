import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/match_day_data.dart';

/// Contract for retrieving player tournament match day schedules, live court scores, and check-ins.
abstract class MatchDayRepository {
  /// Fetches aggregate match day data including the player's personal fixtures,
  /// live court scores, pool standings, and elimination bracket.
  Future<Result<PlayerMatchDayData>> getMatchDayData({String? playerId});

  /// Checks the player in for a designated match fixture.
  Future<Result<PlayerMatch>> checkInToMatch(String matchId);
}
