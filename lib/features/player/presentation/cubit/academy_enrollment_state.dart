import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';
import 'package:pickleball_platform/shared/entities/user_profile.dart';

sealed class AcademyEnrollmentState extends Equatable {
  const AcademyEnrollmentState();

  @override
  List<Object?> get props => [];
}

class AcademyEnrollmentInitial extends AcademyEnrollmentState {
  const AcademyEnrollmentInitial();
}

class AcademyEnrollmentReady extends AcademyEnrollmentState {
  final AcademyBranch branch;
  final AcademyProgram program;
  final AcademyBatch batch;
  final UserProfile? applicantProfile;
  final bool isSubmitting;
  final String? errorMessage;

  const AcademyEnrollmentReady({
    required this.branch,
    required this.program,
    required this.batch,
    this.applicantProfile,
    this.isSubmitting = false,
    this.errorMessage,
  });

  AcademyEnrollmentReady copyWith({
    AcademyBranch? branch,
    AcademyProgram? program,
    AcademyBatch? batch,
    UserProfile? applicantProfile,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AcademyEnrollmentReady(
      branch: branch ?? this.branch,
      program: program ?? this.program,
      batch: batch ?? this.batch,
      applicantProfile: applicantProfile ?? this.applicantProfile,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        branch,
        program,
        batch,
        applicantProfile,
        isSubmitting,
        errorMessage,
      ];
}

class AcademyEnrollmentSuccess extends AcademyEnrollmentState {
  final AcademyEnrollmentRequest request;

  const AcademyEnrollmentSuccess(this.request);

  @override
  List<Object?> get props => [request];
}

class AcademyEnrollmentFailure extends AcademyEnrollmentState {
  final String message;

  const AcademyEnrollmentFailure(this.message);

  @override
  List<Object?> get props => [message];
}
