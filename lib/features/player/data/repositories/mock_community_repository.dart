import 'dart:math';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_venue_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';

/// Concrete in-memory mock implementation of [CommunityRepository].
class MockCommunityRepository implements CommunityRepository {
  final bool shouldFail;
  final bool isEmpty;

  List<CommunityPost>? _posts;
  final Set<String> _followedAuthorIds = {'author_priya_001'};
  final List<Map<String, dynamic>> _reports = [];
  final List<VenueItem> _venues;

  MockCommunityRepository({
    this.shouldFail = false,
    this.isEmpty = false,
    List<CommunityPost>? initialPosts,
    List<VenueItem>? venues,
  })  : _posts = initialPosts,
        _venues = venues ?? MockVenueRepository.defaultVenues;

  static List<CommunityPost> createDefaultPosts() {
    final now = DateTime.now();

    return [
      CommunityPost(
        id: 'post_001',
        type: PostType.gamePoll,
        authorId: 'author_karan_001',
        authorName: 'Karan Sharma',
        authorHandle: '@karan_s',
        authorRating: 3.8,
        isAuthorFollowed: false,
        content:
            'Looking for 2 players for competitive intermediate doubles match tomorrow evening! Balls provided. Who is ready?',
        mediaTag: 'Matchmaking',
        pollDetails: GamePollDetails(
          venueId: 'org_venue_001',
          venueName: 'Grand Slam Pickleball Arena',
          venueAddress: '742 Evergreen Terrace, Andheri West, Mumbai',
          playDate: now.add(const Duration(days: 1)),
          timeSlot: '7:00 PM - 9:00 PM',
          gameFormat: 'Doubles (DUPR 3.5+)',
          targetSkillLevel: 'DUPR 3.5 - 4.5',
          options: const [
            PollOption(
              id: 'opt_1',
              text: "I'm in! (Count me in)",
              voteCount: 3,
              voterUserIds: ['u_1', 'u_2', 'u_3'],
            ),
            PollOption(
              id: 'opt_2',
              text: 'Interested (if after 7:30 PM)',
              voteCount: 1,
              voterUserIds: ['u_4'],
            ),
            PollOption(
              id: 'opt_3',
              text: "Can't make this one",
              voteCount: 0,
              voterUserIds: [],
            ),
          ],
        ),
        likesCount: 12,
        isLikedByMe: false,
        commentsCount: 2,
        comments: [
          PostComment(
            id: 'c_001_1',
            postId: 'post_001',
            authorId: 'u_1',
            authorName: 'Rohan Deshmukh',
            content: 'Count me in! Bringing two fresh Franklin X-40 balls.',
            createdAt: now.subtract(const Duration(hours: 3)),
          ),
          PostComment(
            id: 'c_001_2',
            postId: 'post_001',
            authorId: 'u_2',
            authorName: 'Ananya Verma',
            content: 'Great venue choice. The court lighting is prime there.',
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 4)),
      ),
      CommunityPost(
        id: 'post_002',
        type: PostType.image,
        authorId: 'author_priya_001',
        authorName: 'Priya Patel',
        authorHandle: '@priya_dinks',
        authorRating: 4.2,
        isAuthorFollowed: true,
        content:
            'Testing out new paddle balance during morning kitchen drills! Hand speed and reset drops are feeling very dialed in.',
        mediaUrl: 'assets/images/venues/venue_grand_slam.png',
        mediaTag: 'Training Practice',
        likesCount: 24,
        isLikedByMe: true,
        commentsCount: 3,
        comments: [
          PostComment(
            id: 'c_002_1',
            postId: 'post_002',
            authorId: 'author_karan_001',
            authorName: 'Karan Sharma',
            content: 'That backhand roll drop was unstoppable yesterday!',
            createdAt: now.subtract(const Duration(hours: 6)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      CommunityPost(
        id: 'post_003',
        type: PostType.gamePoll,
        authorId: 'author_marcus_001',
        authorName: 'Marcus Vance',
        authorHandle: '@marcus_v',
        authorRating: 3.2,
        isAuthorFollowed: false,
        content:
            'Saturday morning casual drill session at Pinnacle Sports. Focusing on 3rd shot drops and kitchen patience. All levels welcome!',
        mediaTag: 'Community Clinic',
        pollDetails: GamePollDetails(
          venueId: 'org_venue_002',
          venueName: 'Pinnacle Sports Complex',
          venueAddress: 'Worli Sea Face, Mumbai',
          playDate: now.add(const Duration(days: 3)),
          timeSlot: '8:00 AM - 10:00 AM',
          gameFormat: 'Open Drill Session',
          targetSkillLevel: 'All Skill Levels',
          options: const [
            PollOption(
              id: 'opt_m1',
              text: 'Joining Morning Session',
              voteCount: 4,
              voterUserIds: ['u_10', 'u_11', 'u_12', 'u_13'],
            ),
            PollOption(
              id: 'opt_m2',
              text: 'Tentative (depending on schedule)',
              voteCount: 2,
              voterUserIds: ['u_14', 'u_15'],
            ),
            PollOption(
              id: 'opt_m3',
              text: 'Not Available',
              voteCount: 1,
              voterUserIds: ['u_16'],
            ),
          ],
        ),
        likesCount: 8,
        isLikedByMe: false,
        commentsCount: 1,
        comments: [
          PostComment(
            id: 'c_003_1',
            postId: 'post_003',
            authorId: 'user_player_001',
            authorName: 'Alex Rivera',
            content: 'Will be there! Perfect warmup before Sunday tournament.',
            createdAt: now.subtract(const Duration(hours: 10)),
          ),
        ],
        createdAt: now.subtract(const Duration(hours: 14)),
      ),
      CommunityPost(
        id: 'post_004',
        type: PostType.image,
        authorId: 'author_dev_001',
        authorName: 'Dev Malhotra',
        authorHandle: '@dev_pickle',
        authorRating: 4.6,
        isAuthorFollowed: false,
        content:
            'Nothing beats evening games under the lights. Intense 15-13 tiebreaker finish on Court 2 tonight!',
        mediaUrl: 'assets/images/venues/venue_pinnacle.png',
        mediaTag: 'Match Highlight',
        likesCount: 31,
        isLikedByMe: false,
        commentsCount: 0,
        comments: const [],
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      // Own post created by default logged-in player (Alex Rivera - user_player_001)
      CommunityPost(
        id: 'post_005_own',
        type: PostType.image,
        authorId: 'user_player_001',
        authorName: 'Alex Rivera',
        authorHandle: '@alex_r',
        authorRating: 3.8,
        isAuthorFollowed: false,
        content:
            'Unlocked new consistency on backhand roll dinks today. Getting prepared for next weekend city cup!',
        mediaUrl: 'assets/images/venues/venue_dink_smash.png',
        mediaTag: 'Personal Milestone',
        likesCount: 18,
        isLikedByMe: true,
        commentsCount: 2,
        comments: [
          PostComment(
            id: 'c_005_1',
            postId: 'post_005_own',
            authorId: 'author_priya_001',
            authorName: 'Priya Patel',
            content: 'Saw that session! The spin on the rolls looked deadly.',
            createdAt: now.subtract(const Duration(days: 1, hours: 2)),
          ),
        ],
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }

  void _ensureData() {
    _posts ??= createDefaultPosts();
  }

  @override
  Future<Result<List<CommunityPost>>> getFeed({
    String? categoryFilter,
    bool pollsOnly = false,
    bool photosOnly = false,
    bool myPostsOnly = false,
    String? currentUserId,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Unable to load community feed.'));
    }
    if (isEmpty) {
      return const Success([]);
    }

    _ensureData();

    var results = List<CommunityPost>.from(_posts!);

    if (pollsOnly) {
      results = results.where((p) => p.type.isGamePoll).toList();
    } else if (photosOnly) {
      results = results.where((p) => p.type.isImage).toList();
    } else if (myPostsOnly && currentUserId != null) {
      results = results.where((p) => p.authorId == currentUserId).toList();
    }

    if (categoryFilter != null && categoryFilter.isNotEmpty && categoryFilter != 'All') {
      final cat = categoryFilter.toLowerCase();
      results = results.where((p) => (p.mediaTag ?? '').toLowerCase() == cat).toList();
    }

    // Newest first
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Update follow statuses based on current set
    results = results.map((p) {
      return p.copyWith(isAuthorFollowed: _followedAuthorIds.contains(p.authorId));
    }).toList();

    return Success(results);
  }

  @override
  Future<Result<CommunityPost>> createImagePost({
    required String authorId,
    required String authorName,
    required String authorHandle,
    String? authorAvatarUrl,
    double? authorRating,
    required String content,
    String? mediaUrl,
    String? mediaTag,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Failed to publish post.'));
    }
    if (content.trim().isEmpty) {
      return const FailureResult(ValidationFailure(message: 'Caption cannot be empty.'));
    }

    _ensureData();

    final newPost = CommunityPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      type: PostType.image,
      authorId: authorId,
      authorName: authorName,
      authorHandle: authorHandle,
      authorAvatarUrl: authorAvatarUrl,
      authorRating: authorRating,
      isAuthorFollowed: false,
      content: content.trim(),
      mediaUrl: mediaUrl,
      mediaTag: mediaTag ?? 'Community',
      createdAt: DateTime.now(),
    );

    _posts!.insert(0, newPost);
    return Success(newPost);
  }

  @override
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
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Failed to create game request poll.'));
    }
    if (content.trim().isEmpty) {
      return const FailureResult(ValidationFailure(message: 'Please provide match details or caption.'));
    }
    if (venueId.trim().isEmpty) {
      return const FailureResult(ValidationFailure(message: 'Game request poll must reference a valid venue.'));
    }

    // Verify venueId references a valid venue
    final validVenue = _venues.any((v) => v.id == venueId);
    if (!validVenue) {
      return const FailureResult(
        ValidationFailure(message: 'Selected venue is not recognized. Please choose a valid venue.'),
      );
    }

    final filteredOptions = optionTexts.where((o) => o.trim().isNotEmpty).toList();
    if (filteredOptions.length < 2) {
      return const FailureResult(
        ValidationFailure(message: 'Poll must have at least 2 voting options.'),
      );
    }

    _ensureData();

    final pollOptions = filteredOptions.asMap().entries.map((entry) {
      return PollOption(
        id: 'opt_${entry.key + 1}_${DateTime.now().millisecondsSinceEpoch}',
        text: entry.value.trim(),
        voteCount: 0,
        voterUserIds: const [],
      );
    }).toList();

    final newPollPost = CommunityPost(
      id: 'poll_${DateTime.now().millisecondsSinceEpoch}',
      type: PostType.gamePoll,
      authorId: authorId,
      authorName: authorName,
      authorHandle: authorHandle,
      authorAvatarUrl: authorAvatarUrl,
      authorRating: authorRating,
      isAuthorFollowed: false,
      content: content.trim(),
      mediaTag: 'Matchmaking',
      pollDetails: GamePollDetails(
        venueId: venueId,
        venueName: venueName,
        venueAddress: venueAddress,
        playDate: playDate,
        timeSlot: timeSlot,
        gameFormat: gameFormat,
        targetSkillLevel: targetSkillLevel,
        options: pollOptions,
      ),
      createdAt: DateTime.now(),
    );

    _posts!.insert(0, newPollPost);
    return Success(newPollPost);
  }

  @override
  Future<Result<CommunityPost>> updatePost({
    required String postId,
    required String currentUserId,
    required String updatedContent,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Failed to update post.'));
    }
    if (updatedContent.trim().isEmpty) {
      return const FailureResult(ValidationFailure(message: 'Caption cannot be empty.'));
    }

    _ensureData();
    final index = _posts!.indexWhere((p) => p.id == postId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Post not found.'));
    }

    final post = _posts![index];
    if (post.authorId != currentUserId) {
      return const FailureResult(
        ForbiddenFailure(message: 'You can only edit your own posts.'),
      );
    }

    final updated = post.copyWith(
      content: updatedContent.trim(),
      isEdited: true,
    );

    _posts![index] = updated;
    return Success(updated);
  }

  @override
  Future<Result<void>> deletePost({
    required String postId,
    required String currentUserId,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Failed to delete post.'));
    }

    _ensureData();
    final index = _posts!.indexWhere((p) => p.id == postId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Post not found.'));
    }

    final post = _posts![index];
    if (post.authorId != currentUserId) {
      return const FailureResult(
        ForbiddenFailure(message: 'You can only delete your own posts.'),
      );
    }

    _posts!.removeAt(index);
    return const Success(null);
  }

  @override
  Future<Result<CommunityPost>> toggleLike({
    required String postId,
    required String currentUserId,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Unable to update like.'));
    }

    _ensureData();
    final index = _posts!.indexWhere((p) => p.id == postId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Post not found.'));
    }

    final post = _posts![index];
    final wasLiked = post.isLikedByMe;
    final newLikesCount = wasLiked ? max(0, post.likesCount - 1) : post.likesCount + 1;

    final updated = post.copyWith(
      isLikedByMe: !wasLiked,
      likesCount: newLikesCount,
    );

    _posts![index] = updated;
    return Success(updated);
  }

  @override
  Future<Result<PostComment>> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    String? authorAvatarUrl,
    required String content,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Failed to post comment.'));
    }
    if (content.trim().isEmpty) {
      return const FailureResult(ValidationFailure(message: 'Comment text cannot be empty.'));
    }

    _ensureData();
    final index = _posts!.indexWhere((p) => p.id == postId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Post not found.'));
    }

    final post = _posts![index];
    final newComment = PostComment(
      id: 'c_${DateTime.now().millisecondsSinceEpoch}',
      postId: postId,
      authorId: authorId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    final updatedComments = List<PostComment>.from(post.comments)..add(newComment);
    final updatedPost = post.copyWith(
      comments: updatedComments,
      commentsCount: updatedComments.length,
    );

    _posts![index] = updatedPost;
    return Success(newComment);
  }

  @override
  Future<Result<List<PostComment>>> getComments(String postId) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Failed to load comments.'));
    }

    _ensureData();
    final post = _posts!.firstWhere(
      (p) => p.id == postId,
      orElse: () => CommunityPost(
        id: '',
        type: PostType.image,
        authorId: '',
        authorName: '',
        authorHandle: '',
        content: '',
        createdAt: DateTime.now(),
      ),
    );

    if (post.id.isEmpty) {
      return const FailureResult(NotFoundFailure(message: 'Post not found.'));
    }

    return Success(post.comments);
  }

  @override
  Future<Result<bool>> toggleFollowAuthor({
    required String authorId,
    required String currentUserId,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Unable to update follow state.'));
    }
    if (authorId == currentUserId) {
      return const FailureResult(
        ValidationFailure(message: 'You cannot follow yourself.'),
      );
    }

    _ensureData();
    final isFollowing = _followedAuthorIds.contains(authorId);
    if (isFollowing) {
      _followedAuthorIds.remove(authorId);
    } else {
      _followedAuthorIds.add(authorId);
    }

    final nowFollowing = !isFollowing;

    // Update all posts in feed by this author
    _posts = _posts!.map((p) {
      if (p.authorId == authorId) {
        return p.copyWith(isAuthorFollowed: nowFollowing);
      }
      return p;
    }).toList();

    return Success(nowFollowing);
  }

  @override
  Future<Result<CommunityPost>> votePollOption({
    required String postId,
    required String optionId,
    required String currentUserId,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Failed to cast vote.'));
    }

    _ensureData();
    final index = _posts!.indexWhere((p) => p.id == postId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Post not found.'));
    }

    final post = _posts![index];
    if (post.pollDetails == null) {
      return const FailureResult(ValidationFailure(message: 'Post is not a game poll.'));
    }

    final poll = post.pollDetails!;
    final prevOptionId = poll.myVotedOptionId;

    // If user tapped same option, no-op
    if (prevOptionId == optionId) {
      return Success(post);
    }

    // Update poll options
    final updatedOptions = poll.options.map((opt) {
      var voters = List<String>.from(opt.voterUserIds);
      var count = opt.voteCount;

      if (opt.id == prevOptionId) {
        voters.remove(currentUserId);
        count = max(0, count - 1);
      }

      if (opt.id == optionId) {
        if (!voters.contains(currentUserId)) {
          voters.add(currentUserId);
          count++;
        }
      }

      return opt.copyWith(voteCount: count, voterUserIds: voters);
    }).toList();

    final updatedPoll = poll.copyWith(
      options: updatedOptions,
      myVotedOptionId: optionId,
    );

    final updatedPost = post.copyWith(pollDetails: updatedPoll);
    _posts![index] = updatedPost;

    return Success(updatedPost);
  }

  @override
  Future<Result<void>> reportPost({
    required String postId,
    required String reporterUserId,
    required CommunityReportReason reason,
    String? notes,
  }) async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Failed to submit report.'));
    }

    _ensureData();
    final index = _posts!.indexWhere((p) => p.id == postId);
    if (index == -1) {
      return const FailureResult(NotFoundFailure(message: 'Post not found.'));
    }

    _reports.add({
      'postId': postId,
      'reporterUserId': reporterUserId,
      'reason': reason.name,
      'notes': notes,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final post = _posts![index];
    _posts![index] = post.copyWith(reportCount: post.reportCount + 1);

    return const Success(null);
  }

  @override
  Future<Result<List<VenueItem>>> getAvailableVenues() async {
    if (shouldFail) {
      return const FailureResult(ServerFailure(message: 'Failed to load venues.'));
    }
    return Success(_venues);
  }
}
