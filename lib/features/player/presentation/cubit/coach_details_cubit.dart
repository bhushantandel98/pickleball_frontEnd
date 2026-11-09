import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_details_state.dart';

class CoachDetailsCubit extends Cubit<CoachDetailsState> {
  final CoachingAcademyRepository _repository;
  final String coachId;

  CoachDetailsCubit(
    this._repository, {
    required this.coachId,
  }) : super(const CoachDetailsInitial());

  Future<void> loadCoachDetails() async {
    emit(const CoachDetailsLoading());
    final result = await _repository.getCoachById(coachId);
    switch (result) {
      case Success(:final data):
        emit(CoachDetailsLoaded(data));
      case FailureResult(:final failure):
        emit(CoachDetailsError(failure.message));
    }
  }
}
