import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/community_feed_state.dart';

/// Cubit managing the Player Community feed, tab filtering, post interactions,
/// ownership updates, and moderation actions.
class CommunityFeedCubit extends Cubit<CommunityFeedState> {
  final CommunityRepository repository;
  final String currentUserId;

  CommunityFeedCubit({
    required this.repository,
    required this.currentUserId,
  }) : super(const CommunityFeedInitial());

  /// Loads feed posts based on the specified or current filter tab.
  Future<void> loadFeed({CommunityFilterTab? tab}) async {
    final activeTab = tab ??
        (state is CommunityFeedLoaded
            ? (state as CommunityFeedLoaded).activeTab
            : CommunityFilterTab.all);

    emit(const CommunityFeedLoading());

    final result = await repository.getFeed(
      pollsOnly: activeTab == CommunityFilterTab.polls,
      photosOnly: activeTab == CommunityFilterTab.photos,
      myPostsOnly: activeTab == CommunityFilterTab.myPosts,
      currentUserId: currentUserId,
    );

    switch (result) {
      case Success(:final data):
        emit(CommunityFeedLoaded(
          posts: data,
          activeTab: activeTab,
          currentUserId: currentUserId,
        ));
      case FailureResult(:final failure):
        emit(CommunityFeedError(failure.message));
    }
  }

  /// Changes the active feed filter tab.
  void setFilterTab(CommunityFilterTab tab) {
    loadFeed(tab: tab);
  }

  /// Toggles like status on a post for the current user.
  Future<void> toggleLike(String postId) async {
    final currentState = state;
    if (currentState is! CommunityFeedLoaded) return;

    final result = await repository.toggleLike(
      postId: postId,
      currentUserId: currentUserId,
    );

    if (result is Success<CommunityPost>) {
      final updatedPost = result.data;
      final updatedList = currentState.posts.map((p) {
        return p.id == updatedPost.id ? updatedPost : p;
      }).toList();

      emit(currentState.copyWith(posts: updatedList, clearFeedback: true));
    }
  }

  /// Votes for an option in a game-request poll.
  Future<void> votePoll(String postId, String optionId) async {
    final currentState = state;
    if (currentState is! CommunityFeedLoaded) return;

    final result = await repository.votePollOption(
      postId: postId,
      optionId: optionId,
      currentUserId: currentUserId,
    );

    if (result is Success<CommunityPost>) {
      final updatedPost = result.data;
      final updatedList = currentState.posts.map((p) {
        return p.id == updatedPost.id ? updatedPost : p;
      }).toList();

      emit(currentState.copyWith(
        posts: updatedList,
        feedbackMessage: 'Vote recorded!',
      ));
    } else if (result is FailureResult<CommunityPost>) {
      emit(currentState.copyWith(
        errorMessage: result.failure.message,
      ));
    }
  }

  /// Toggles following status for a post author.
  Future<void> toggleFollow(String authorId) async {
    final currentState = state;
    if (currentState is! CommunityFeedLoaded) return;

    final result = await repository.toggleFollowAuthor(
      authorId: authorId,
      currentUserId: currentUserId,
    );

    if (result is Success<bool>) {
      final isNowFollowing = result.data;
      final updatedList = currentState.posts.map((p) {
        if (p.authorId == authorId) {
          return p.copyWith(isAuthorFollowed: isNowFollowing);
        }
        return p;
      }).toList();

      emit(currentState.copyWith(
        posts: updatedList,
        feedbackMessage:
            isNowFollowing ? 'Player followed' : 'Player unfollowed',
      ));
    }
  }

  /// Deletes an owned post. Enforced on repository by authorId check.
  Future<void> deletePost(String postId) async {
    final currentState = state;
    if (currentState is! CommunityFeedLoaded) return;

    final result = await repository.deletePost(
      postId: postId,
      currentUserId: currentUserId,
    );

    if (result is Success<void>) {
      final updatedList =
          currentState.posts.where((p) => p.id != postId).toList();
      emit(currentState.copyWith(
        posts: updatedList,
        feedbackMessage: 'Post deleted successfully',
      ));
    } else if (result is FailureResult<void>) {
      emit(currentState.copyWith(
        errorMessage: result.failure.message,
      ));
    }
  }

  /// Updates an owned post caption.
  Future<void> updatePost(String postId, String updatedContent) async {
    final currentState = state;
    if (currentState is! CommunityFeedLoaded) return;

    final result = await repository.updatePost(
      postId: postId,
      currentUserId: currentUserId,
      updatedContent: updatedContent,
    );

    if (result is Success<CommunityPost>) {
      final updatedPost = result.data;
      final updatedList = currentState.posts.map((p) {
        return p.id == updatedPost.id ? updatedPost : p;
      }).toList();

      emit(currentState.copyWith(
        posts: updatedList,
        feedbackMessage: 'Post updated successfully',
      ));
    } else if (result is FailureResult<CommunityPost>) {
      emit(currentState.copyWith(
        errorMessage: result.failure.message,
      ));
    }
  }

  /// Submits an inappropriate content report for moderation.
  Future<void> reportPost({
    required String postId,
    required CommunityReportReason reason,
    String? notes,
  }) async {
    final currentState = state;
    if (currentState is! CommunityFeedLoaded) return;

    final result = await repository.reportPost(
      postId: postId,
      reporterUserId: currentUserId,
      reason: reason,
      notes: notes,
    );

    if (result is Success<void>) {
      emit(currentState.copyWith(
        feedbackMessage:
            'Report submitted. Our team will review this content.',
      ));
    } else if (result is FailureResult<void>) {
      emit(currentState.copyWith(
        errorMessage: result.failure.message,
      ));
    }
  }

  /// Clears any transient feedback or error messages.
  void clearFeedback() {
    final currentState = state;
    if (currentState is CommunityFeedLoaded) {
      emit(currentState.copyWith(
        clearFeedback: true,
        errorMessage: null,
      ));
    }
  }
}
