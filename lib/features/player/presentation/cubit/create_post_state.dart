import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';

sealed class CreatePostState extends Equatable {
  const CreatePostState();

  @override
  List<Object?> get props => [];
}

class CreatePostInitial extends CreatePostState {
  const CreatePostInitial();
}

class CreatePostSubmitting extends CreatePostState {
  const CreatePostSubmitting();
}

class CreatePostSuccess extends CreatePostState {
  final CommunityPost post;

  const CreatePostSuccess(this.post);

  @override
  List<Object?> get props => [post];
}

class CreatePostFailure extends CreatePostState {
  final String error;

  const CreatePostFailure(this.error);

  @override
  List<Object?> get props => [error];
}
