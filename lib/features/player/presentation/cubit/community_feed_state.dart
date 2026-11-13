import 'package:equatable/equatable.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';

enum CommunityFilterTab {
  all('All Posts'),
  polls('Game Polls'),
  photos('Photos'),
  myPosts('My Posts');

  final String label;
  const CommunityFilterTab(this.label);
}

sealed class CommunityFeedState extends Equatable {
  const CommunityFeedState();

  @override
  List<Object?> get props => [];
}

class CommunityFeedInitial extends CommunityFeedState {
  const CommunityFeedInitial();
}

class CommunityFeedLoading extends CommunityFeedState {
  const CommunityFeedLoading();
}

class CommunityFeedLoaded extends CommunityFeedState {
  final List<CommunityPost> posts;
  final CommunityFilterTab activeTab;
  final String currentUserId;
  final String? feedbackMessage;
  final String? errorMessage;

  const CommunityFeedLoaded({
    required this.posts,
    this.activeTab = CommunityFilterTab.all,
    required this.currentUserId,
    this.feedbackMessage,
    this.errorMessage,
  });

  CommunityFeedLoaded copyWith({
    List<CommunityPost>? posts,
    CommunityFilterTab? activeTab,
    String? currentUserId,
    String? feedbackMessage,
    String? errorMessage,
    bool clearFeedback = false,
  }) {
    return CommunityFeedLoaded(
      posts: posts ?? this.posts,
      activeTab: activeTab ?? this.activeTab,
      currentUserId: currentUserId ?? this.currentUserId,
      feedbackMessage: clearFeedback ? null : (feedbackMessage ?? this.feedbackMessage),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        activeTab,
        currentUserId,
        feedbackMessage,
        errorMessage,
      ];
}

class CommunityFeedError extends CommunityFeedState {
  final String message;

  const CommunityFeedError(this.message);

  @override
  List<Object?> get props => [message];
}
