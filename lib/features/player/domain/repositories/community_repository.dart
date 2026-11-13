import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';

/// Contract interface for Player Community and Matchmaking operations.
abstract interface class CommunityRepository {
  /// Fetches community feed posts according to optional filters.
  Future<Result<List<CommunityPost>>> getFeed({
    String? categoryFilter,
    bool pollsOnly = false,
    bool photosOnly = false,
    bool myPostsOnly = false,
    String? currentUserId,
  });

  /// Creates a standard photo / caption community post.
  Future<Result<CommunityPost>> createImagePost({
    required String authorId,
    required String authorName,
    required String authorHandle,
    String? authorAvatarUrl,
    double? authorRating,
    required String content,
    String? mediaUrl,
    String? mediaTag,
  });

  /// Creates a venue-based game-request poll post.
  ///
  /// Enforces that [venueId] must reference a valid recognized venue.
  Future<Result<CommunityPost>> createGameRequestPoll({
    required String authorId,
    required String authorName,
    required String authorHandle,
    String? authorAvatarUrl,
    double? authorRating,
    required String content,
    required String venueId,
    required String venueName,
    required String venueAddress,
    required DateTime playDate,
    required String timeSlot,
    required String gameFormat,
    required String targetSkillLevel,
    required List<String> optionTexts,
  });

  /// Updates an existing post's text content.
  ///
  /// Enforces strict ownership: rejected if [currentUserId] != post author.
  Future<Result<CommunityPost>> updatePost({
    required String postId,
    required String currentUserId,
    required String updatedContent,
  });

  /// Deletes an existing post from the feed.
  ///
  /// Enforces strict ownership: rejected if [currentUserId] != post author.
  Future<Result<void>> deletePost({
    required String postId,
    required String currentUserId,
  });

  /// Toggles like status on a post for [currentUserId].
  Future<Result<CommunityPost>> toggleLike({
    required String postId,
    required String currentUserId,
  });

  /// Submits a comment on [postId].
  Future<Result<PostComment>> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required String content,
  });

  /// Retrieves list of comments for [postId].
  Future<Result<List<PostComment>>> getComments(String postId);

  /// Toggles follow status for [authorId] by [currentUserId].
  Future<Result<bool>> toggleFollowAuthor({
    required String authorId,
    required String currentUserId,
  });

  /// Casts or changes a vote on a game-request poll option.
  Future<Result<CommunityPost>> votePollOption({
    required String postId,
    required String optionId,
    required String currentUserId,
  });

  /// Submits a user report against an inappropriate post.
  Future<Result<void>> reportPost({
    required String postId,
    required String reporterUserId,
    required CommunityReportReason reason,
    String? notes,
  });

  /// Retrieves available valid venues for game-request creation.
  Future<Result<List<VenueItem>>> getAvailableVenues();
}
