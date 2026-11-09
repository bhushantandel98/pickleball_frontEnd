import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

sealed class CoachInquiryState extends Equatable {
  const CoachInquiryState();

  @override
  List<Object?> get props => [];
}

class CoachInquiryInitial extends CoachInquiryState {
  const CoachInquiryInitial();
}

class CoachInquiryReady extends CoachInquiryState {
  final CoachItem coach;
  final String? selectedServiceId;
  final UserProfile? applicantProfile;
  final bool isSubmitting;
  final String? errorMessage;

  const CoachInquiryReady({
    required this.coach,
    this.selectedServiceId,
    this.applicantProfile,
    this.isSubmitting = false,
    this.errorMessage,
  });

  CoachInquiryReady copyWith({
    CoachItem? coach,
    String? selectedServiceId,
    UserProfile? applicantProfile,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return CoachInquiryReady(
      coach: coach ?? this.coach,
      selectedServiceId: selectedServiceId ?? this.selectedServiceId,
      applicantProfile: applicantProfile ?? this.applicantProfile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        coach,
        selectedServiceId,
        applicantProfile,
        isSubmitting,
        errorMessage,
      ];
}

class CoachInquirySuccess extends CoachInquiryState {
  final CoachInquiryRequest inquiry;

  const CoachInquirySuccess(this.inquiry);

  @override
  List<Object?> get props => [inquiry];
}

class CoachInquiryFailure extends CoachInquiryState {
  final String message;

  const CoachInquiryFailure(this.message);

  @override
  List<Object?> get props => [message];
}
