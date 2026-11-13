import 'package:equatable/equatable.dart';

/// The format/type of a community post.
enum PostType {
  image('Photo Update'),
  gamePoll('Game Request Poll');

  final String displayName;
  const PostType(this.displayName);

  bool get isImage => this == PostType.image;
  bool get isGamePoll => this == PostType.gamePoll;
}

/// An individual voting option in a game-request matchmaking poll.
class PollOption extends Equatable {
  final String id;
  final String text;
  final int voteCount;
  final List<String> voterUserIds;

  const PollOption({
    required this.id,
    required this.text,
    this.voteCount = 0,
    this.voterUserIds = const [],
  });

  bool hasVoted(String userId) => voterUserIds.contains(userId);

  PollOption copyWith({
    String? id,
    String? text,
    int? voteCount,
    List<String>? voterUserIds,
  }) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      voteCount: voteCount ?? this.voteCount,
      voterUserIds: voterUserIds ?? this.voterUserIds,
    );
  }

  @override
  List<Object?> get props => [id, text, voteCount, voterUserIds];
}

/// Structured game-request poll details referencing a validated venue.
class GamePollDetails extends Equatable {
  final String venueId;
  final String venueName;
  final String venueAddress;
  final DateTime playDate;
  final String timeSlot;
  final String gameFormat; // e.g. "Doubles", "Singles", "Mixed Doubles", "Drill Session"
  final String targetSkillLevel; // e.g. "DUPR 3.0 - 4.0", "Open"
  final List<PollOption> options;
  final String? myVotedOptionId;

  const GamePollDetails({
    required this.venueId,
    required this.venueName,
    required this.venueAddress,
    required this.playDate,
    required this.timeSlot,
    required this.gameFormat,
    required this.targetSkillLevel,
    required this.options,
    this.myVotedOptionId,
  });

  int get totalVotes =>
      options.fold<int>(0, (sum, opt) => sum + opt.voteCount);

  double getPercentage(PollOption option) {
    final total = totalVotes;
    if (total == 0) return 0.0;
    return (option.voteCount / total).clamp(0.0, 1.0);
  }

  GamePollDetails copyWith({
    String? venueId,
    String? venueName,
    String? venueAddress,
    DateTime? playDate,
    String? timeSlot,
    String? gameFormat,
    String? targetSkillLevel,
    List<PollOption>? options,
    String? myVotedOptionId,
    bool clearVote = false,
  }) {
    return GamePollDetails(
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      venueAddress: venueAddress ?? this.venueAddress,
      playDate: playDate ?? this.playDate,
      timeSlot: timeSlot ?? this.timeSlot,
      gameFormat: gameFormat ?? this.gameFormat,
      targetSkillLevel: targetSkillLevel ?? this.targetSkillLevel,
      options: options ?? this.options,
      myVotedOptionId: clearVote ? null : (myVotedOptionId ?? this.myVotedOptionId),
    );
  }

  @override
  List<Object?> get props => [
        venueId,
        venueName,
        venueAddress,
        playDate,
        timeSlot,
        gameFormat,
        targetSkillLevel,
        options,
        myVotedOptionId,
      ];
}

/// A comment on a community post.
class PostComment extends Equatable {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;

  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        postId,
        authorId,
        authorName,
        authorAvatarUrl,
        content,
        createdAt,
      ];
}

/// Predefined reasons for reporting community content.
enum CommunityReportReason {
  spam('Spam or Commercial Solicitation'),
  inappropriateMedia('Inappropriate Media or Language'),
  harassment('Harassment or Abusive Conduct'),
  falseInfo('Misleading Match Information'),
  other('Other Community Policy Violation');

  final String label;
  const CommunityReportReason(this.label);
}

/// Central domain entity representing a post in the Player Community Feed.
class CommunityPost extends Equatable {
  final String id;
  final PostType type;
  final String authorId;
  final String authorName;
  final String authorHandle;
  final String? authorAvatarUrl;
  final double? authorRating;
  final bool isAuthorFollowed;
  final String content;
  final String? mediaUrl;
  final String? mediaTag;
  final GamePollDetails? pollDetails;
  final int likesCount;
  final bool isLikedByMe;
  final int commentsCount;
  final List<PostComment> comments;
  final DateTime createdAt;
  final bool isEdited;
  final int reportCount;

  const CommunityPost({
    required this.id,
    required this.type,
    required this.authorId,
    required this.authorName,
    required this.authorHandle,
    this.authorAvatarUrl,
    this.authorRating,
    this.isAuthorFollowed = false,
    required this.content,
    this.mediaUrl,
    this.mediaTag,
    this.pollDetails,
    this.likesCount = 0,
    this.isLikedByMe = false,
    this.commentsCount = 0,
    this.comments = const [],
    required this.createdAt,
    this.isEdited = false,
    this.reportCount = 0,
  });

  bool isOwnedBy(String userId) => authorId == userId;

  CommunityPost copyWith({
    String? id,
    PostType? type,
    String? authorId,
    String? authorName,
    String? authorHandle,
    String? authorAvatarUrl,
    double? authorRating,
    bool? isAuthorFollowed,
    String? content,
    String? mediaUrl,
    String? mediaTag,
    GamePollDetails? pollDetails,
    int? likesCount,
    bool? isLikedByMe,
    int? commentsCount,
    List<PostComment>? comments,
    DateTime? createdAt,
    bool? isEdited,
    int? reportCount,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorHandle: authorHandle ?? this.authorHandle,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorRating: authorRating ?? this.authorRating,
      isAuthorFollowed: isAuthorFollowed ?? this.isAuthorFollowed,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaTag: mediaTag ?? this.mediaTag,
      pollDetails: pollDetails ?? this.pollDetails,
      likesCount: likesCount ?? this.likesCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      commentsCount: commentsCount ?? this.commentsCount,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      isEdited: isEdited ?? this.isEdited,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        authorId,
        authorName,
        authorHandle,
        authorAvatarUrl,
        authorRating,
        isAuthorFollowed,
        content,
        mediaUrl,
        mediaTag,
        pollDetails,
        likesCount,
        isLikedByMe,
        commentsCount,
        comments,
        createdAt,
        isEdited,
        reportCount,
      ];
}
