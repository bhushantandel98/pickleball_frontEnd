import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';

sealed class MyCoachingRequestsState extends Equatable {
  const MyCoachingRequestsState();

  @override
  List<Object?> get props => [];
}

class MyCoachingRequestsInitial extends MyCoachingRequestsState {
  const MyCoachingRequestsInitial();
}

class MyCoachingRequestsLoading extends MyCoachingRequestsState {
  const MyCoachingRequestsLoading();
}

class MyCoachingRequestsLoaded extends MyCoachingRequestsState {
  final List<AcademyEnrollmentRequest> enrollmentRequests;
  final List<CoachInquiryRequest> coachInquiries;
  final String? actionNotice;
  final bool isCancelling;

  const MyCoachingRequestsLoaded({
    required this.enrollmentRequests,
    required this.coachInquiries,
    this.actionNotice,
    this.isCancelling = false,
  });

  bool get isEmpty => enrollmentRequests.isEmpty && coachInquiries.isEmpty;

  MyCoachingRequestsLoaded copyWith({
    List<AcademyEnrollmentRequest>? enrollmentRequests,
    List<CoachInquiryRequest>? coachInquiries,
    String? actionNotice,
    bool? isCancelling,
  }) {
    return MyCoachingRequestsLoaded(
      enrollmentRequests: enrollmentRequests ?? this.enrollmentRequests,
      coachInquiries: coachInquiries ?? this.coachInquiries,
      actionNotice: actionNotice,
      isCancelling: isCancelling ?? this.isCancelling,
    );
  }

  @override
  List<Object?> get props => [
        enrollmentRequests,
        coachInquiries,
        actionNotice,
        isCancelling,
      ];
}

class MyCoachingRequestsError extends MyCoachingRequestsState {
  final String message;

  const MyCoachingRequestsError(this.message);

  @override
  List<Object?> get props => [message];
}
