import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_game_poll_state.dart';

class CreateGamePollCubit extends Cubit<CreateGamePollState> {
  final CommunityRepository communityRepository;
  final VenueRepository venueRepository;

  List<VenueItem> _venues = [];

  CreateGamePollCubit({
    required this.communityRepository,
    required this.venueRepository,
  }) : super(const CreateGamePollInitial());

  /// Loads available venues to populate the venue dropdown selector.
  Future<void> loadVenues() async {
    final result = await venueRepository.getVenues();
    if (result is Success<List<VenueItem>>) {
      _venues = result.data;
      emit(CreateGamePollInitial(availableVenues: _venues));
    }
  }

  /// Submits a venue-referenced game-request poll.
  Future<void> submitPoll({
    required String authorId,
    required String authorName,
    required String authorHandle,
    String? authorAvatarUrl,
    double? authorRating,
    required String content,
    required VenueItem venue,
    required DateTime playDate,
    required String timeSlot,
    required String gameFormat,
    required String targetSkillLevel,
    required List<String> optionTexts,
  }) async {
    if (content.trim().isEmpty) {
      emit(CreateGamePollFailure(
        'Please enter a description or call-out for the game request.',
        availableVenues: _venues,
      ));
      return;
    }

    final filteredOptions = optionTexts
        .map((o) => o.trim())
        .where((o) => o.isNotEmpty)
        .toList();

    if (filteredOptions.length < 2) {
      emit(CreateGamePollFailure(
        'Please provide at least 2 poll options for players to vote on.',
        availableVenues: _venues,
      ));
      return;
    }

    emit(const CreateGamePollSubmitting());

    final result = await communityRepository.createGameRequestPoll(
      authorId: authorId,
      authorName: authorName,
      authorHandle: authorHandle,
      authorAvatarUrl: authorAvatarUrl,
      authorRating: authorRating,
      content: content.trim(),
      venueId: venue.id,
      venueName: venue.name,
      venueAddress: venue.address,
      playDate: playDate,
      timeSlot: timeSlot,
      gameFormat: gameFormat,
      targetSkillLevel: targetSkillLevel,
      optionTexts: filteredOptions,
    );

    switch (result) {
      case Success(:final data):
        emit(CreateGamePollSuccess(data));
      case FailureResult(:final failure):
        emit(CreateGamePollFailure(
          failure.message,
          availableVenues: _venues,
        ));
    }
  }

  void reset() {
    emit(CreateGamePollInitial(availableVenues: _venues));
  }
}
