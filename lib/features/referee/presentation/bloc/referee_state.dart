import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/referee/domain/entities/referee_entities.dart';

abstract class RefereeState extends Equatable {
  const RefereeState();

  @override
  List<Object?> get props => [];
}

class RefereeInitial extends RefereeState {
  const RefereeInitial();
}

class RefereeLoading extends RefereeState {
  const RefereeLoading();
}

class RefereeLoaded extends RefereeState {
  final RefereeWorkspaceData data;
  final bool isMutating;
  final String? feedbackMessage;
  final String? errorMessage;

  const RefereeLoaded({
    required this.data,
    this.isMutating = false,
    this.feedbackMessage,
    this.errorMessage,
  });

  RefereeLoaded copyWith({
    RefereeWorkspaceData? data,
    bool? isMutating,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
    bool clearError = false,
  }) {
    return RefereeLoaded(
      data: data ?? this.data,
      isMutating: isMutating ?? this.isMutating,
      feedbackMessage:
          clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [data, isMutating, feedbackMessage, errorMessage];
}

class RefereeFailure extends RefereeState {
  final String message;

  const RefereeFailure(this.message);

  @override
  List<Object?> get props => [message];
}
