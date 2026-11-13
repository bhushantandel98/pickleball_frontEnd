import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/post_comments_state.dart';

class PostCommentsCubit extends Cubit<PostCommentsState> {
  final CommunityRepository repository;

  PostCommentsCubit({required this.repository})
      : super(const PostCommentsInitial());

  Future<void> loadComments(String postId) async {
    emit(const PostCommentsLoading());
    final result = await repository.getComments(postId);
    switch (result) {
      case Success(:final data):
        emit(PostCommentsLoaded(comments: data));
      case FailureResult(:final failure):
        emit(PostCommentsError(failure.message));
    }
  }

  Future<bool> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required String content,
  }) async {
    final currentState = state;
    if (currentState is! PostCommentsLoaded) return false;

    if (content.trim().isEmpty) {
      emit(currentState.copyWith(submissionError: 'Comment cannot be empty.'));
      return false;
    }

    emit(currentState.copyWith(isSubmitting: true, submissionError: null));

    final result = await repository.addComment(
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      content: content.trim(),
    );

    switch (result) {
      case Success(:final data):
        emit(currentState.copyWith(
          comments: [...currentState.comments, data],
          isSubmitting: false,
        ));
        return true;
      case FailureResult(:final failure):
        emit(currentState.copyWith(
          isSubmitting: false,
          submissionError: failure.message,
        ));
        return false;
    }
  }
}
