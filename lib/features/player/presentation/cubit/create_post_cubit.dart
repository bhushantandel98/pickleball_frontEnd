import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_post_state.dart';

class CreatePostCubit extends Cubit<CreatePostState> {
  final CommunityRepository repository;

  CreatePostCubit({required this.repository})
      : super(const CreatePostInitial());

  Future<void> submitPost({
    required String authorId,
    required String authorName,
    required String authorHandle,
    String? authorAvatarUrl,
    double? authorRating,
    required String content,
    String? mediaUrl,
    String? mediaTag,
  }) async {
    if (content.trim().isEmpty) {
      emit(const CreatePostFailure('Post caption cannot be empty.'));
      return;
    }

    emit(const CreatePostSubmitting());

    final result = await repository.createImagePost(
      authorId: authorId,
      authorName: authorName,
      authorHandle: authorHandle,
      authorAvatarUrl: authorAvatarUrl,
      authorRating: authorRating,
      content: content.trim(),
      mediaUrl: mediaUrl,
      mediaTag: mediaTag,
    );

    switch (result) {
      case Success(:final data):
        emit(CreatePostSuccess(data));
      case FailureResult(:final failure):
        emit(CreatePostFailure(failure.message));
    }
  }

  void reset() {
    emit(const CreatePostInitial());
  }
}
