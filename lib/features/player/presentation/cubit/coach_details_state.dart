import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';

sealed class CoachDetailsState extends Equatable {
  const CoachDetailsState();

  @override
  List<Object?> get props => [];
}

class CoachDetailsInitial extends CoachDetailsState {
  const CoachDetailsInitial();
}

class CoachDetailsLoading extends CoachDetailsState {
  const CoachDetailsLoading();
}

class CoachDetailsLoaded extends CoachDetailsState {
  final CoachItem coach;

  const CoachDetailsLoaded(this.coach);

  @override
  List<Object?> get props => [coach];
}

class CoachDetailsError extends CoachDetailsState {
  final String message;

  const CoachDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
