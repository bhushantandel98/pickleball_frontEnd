import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';

sealed class CreateGamePollState extends Equatable {
  const CreateGamePollState();

  @override
  List<Object?> get props => [];
}

class CreateGamePollInitial extends CreateGamePollState {
  final List<VenueItem> availableVenues;

  const CreateGamePollInitial({this.availableVenues = const []});

  @override
  List<Object?> get props => [availableVenues];
}

class CreateGamePollSubmitting extends CreateGamePollState {
  const CreateGamePollSubmitting();
}

class CreateGamePollSuccess extends CreateGamePollState {
  final CommunityPost post;

  const CreateGamePollSuccess(this.post);

  @override
  List<Object?> get props => [post];
}

class CreateGamePollFailure extends CreateGamePollState {
  final String error;
  final List<VenueItem> availableVenues;

  const CreateGamePollFailure(this.error, {this.availableVenues = const []});

  @override
  List<Object?> get props => [error, availableVenues];
}
