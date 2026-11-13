import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';

sealed class PostCommentsState extends Equatable {
  const PostCommentsState();

  @override
  List<Object?> get props => [];
}

class PostCommentsInitial extends PostCommentsState {
  const PostCommentsInitial();
}

class PostCommentsLoading extends PostCommentsState {
  const PostCommentsLoading();
}

class PostCommentsLoaded extends PostCommentsState {
  final List<PostComment> comments;
  final bool isSubmitting;
  final String? submissionError;

  const PostCommentsLoaded({
    required this.comments,
    this.isSubmitting = false,
    this.submissionError,
  });

  PostCommentsLoaded copyWith({
    List<PostComment>? comments,
    bool? isSubmitting,
    String? submissionError,
  }) {
    return PostCommentsLoaded(
      comments: comments ?? this.comments,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionError: submissionError,
    );
  }

  @override
  List<Object?> get props => [comments, isSubmitting, submissionError];
}

class PostCommentsError extends PostCommentsState {
  final String message;

  const PostCommentsError(this.message);

  @override
  List<Object?> get props => [message];
}
