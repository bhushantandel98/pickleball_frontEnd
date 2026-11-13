import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/tournament_staff/domain/entities/tournament_staff_entities.dart';

/// Base state hierarchy for Feature 5.2 — Tournament Staff Module.
sealed class TournamentStaffState extends Equatable {
  const TournamentStaffState();

  @override
  List<Object?> get props => [];
}

class TournamentStaffInitial extends TournamentStaffState {
  const TournamentStaffInitial();
}

class TournamentStaffLoading extends TournamentStaffState {
  const TournamentStaffLoading();
}

class TournamentStaffLoaded extends TournamentStaffState {
  final TournamentStaffWorkspaceData data;
  final String? feedbackMessage;
  final bool isErrorFeedback;

  const TournamentStaffLoaded({
    required this.data,
    this.feedbackMessage,
    this.isErrorFeedback = false,
  });

  TournamentStaffProfile get staffProfile => data.staffProfile;

  bool hasPermission(TournamentStaffPermission permission) =>
      data.staffProfile.hasPermission(permission);

  int get checkedInCount => data.checkIns.where((c) => c.isCheckedIn).length;

  int get activeRefereesCount => data.referees.where((r) => r.isActive).length;

  TournamentStaffLoaded copyWith({
    TournamentStaffWorkspaceData? data,
    String? feedbackMessage,
    bool? isErrorFeedback,
    bool clearFeedback = false,
  }) {
    return TournamentStaffLoaded(
      data: data ?? this.data,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      isErrorFeedback:
          clearFeedback ? false : (isErrorFeedback ?? this.isErrorFeedback),
    );
  }

  @override
  List<Object?> get props => [data, feedbackMessage, isErrorFeedback];
}

class TournamentStaffFailure extends TournamentStaffState {
  final Failure failure;

  const TournamentStaffFailure(this.failure);

  @override
  List<Object?> get props => [failure];
}
