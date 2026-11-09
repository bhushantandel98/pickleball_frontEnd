import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';

sealed class AcademyDetailsState extends Equatable {
  const AcademyDetailsState();

  @override
  List<Object?> get props => [];
}

class AcademyDetailsInitial extends AcademyDetailsState {
  const AcademyDetailsInitial();
}

class AcademyDetailsLoading extends AcademyDetailsState {
  const AcademyDetailsLoading();
}

class AcademyDetailsLoaded extends AcademyDetailsState {
  final AcademyBranch branch;

  const AcademyDetailsLoaded(this.branch);

  @override
  List<Object?> get props => [branch];
}

class AcademyDetailsError extends AcademyDetailsState {
  final String message;

  const AcademyDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
