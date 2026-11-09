import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_details_state.dart';

class AcademyDetailsCubit extends Cubit<AcademyDetailsState> {
  final CoachingAcademyRepository _repository;
  final String branchId;

  AcademyDetailsCubit(
    this._repository, {
    required this.branchId,
  }) : super(const AcademyDetailsInitial());

  Future<void> loadBranchDetails() async {
    emit(const AcademyDetailsLoading());
    final result = await _repository.getAcademyBranchById(branchId);
    switch (result) {
      case Success(:final data):
        emit(AcademyDetailsLoaded(data));
      case FailureResult(:final failure):
        emit(AcademyDetailsError(failure.message));
    }
  }
}
