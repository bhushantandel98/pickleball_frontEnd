import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_coaching_requests_state.dart';

class MyCoachingRequestsCubit extends Cubit<MyCoachingRequestsState> {
  final CoachingAcademyRepository _repository;

  MyCoachingRequestsCubit(this._repository) : super(const MyCoachingRequestsInitial());

  Future<void> loadRequests({bool showLoading = true}) async {
    if (showLoading) {
      emit(const MyCoachingRequestsLoading());
    }

    final enrollmentsResult = await _repository.getMyEnrollmentRequests();
    final inquiriesResult = await _repository.getMyCoachInquiries();

    if (enrollmentsResult is Success<List<AcademyEnrollmentRequest>> &&
        inquiriesResult is Success<List<CoachInquiryRequest>>) {
      emit(MyCoachingRequestsLoaded(
        enrollmentRequests: enrollmentsResult.data,
        coachInquiries: inquiriesResult.data,
      ));
    } else {
      emit(const MyCoachingRequestsError('Failed to load your coaching and academy requests.'));
    }
  }

  Future<void> cancelEnrollment(String requestId) async {
    final current = state;
    if (current is! MyCoachingRequestsLoaded) return;

    emit(current.copyWith(isCancelling: true));
    final result = await _repository.cancelEnrollmentRequest(requestId);
    switch (result) {
      case Success():
        await loadRequests(showLoading: false);
      case FailureResult(:final failure):
        emit(current.copyWith(isCancelling: false, actionNotice: failure.message));
    }
  }

  Future<void> cancelInquiry(String inquiryId) async {
    final current = state;
    if (current is! MyCoachingRequestsLoaded) return;

    emit(current.copyWith(isCancelling: true));
    final result = await _repository.cancelCoachInquiry(inquiryId);
    switch (result) {
      case Success():
        await loadRequests(showLoading: false);
      case FailureResult(:final failure):
        emit(current.copyWith(isCancelling: false, actionNotice: failure.message));
    }
  }
}
