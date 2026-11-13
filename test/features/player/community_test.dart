import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_community_repository.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_venue_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/community_post.dart';
import 'package:pickleball_platform/features/player/domain/repositories/community_repository.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/community_feed_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/community_feed_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_game_poll_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_game_poll_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_post_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/create_post_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/post_comments_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/post_comments_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/player_community_page.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/community_post_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const currentUserId = 'user_player_001';
  late MockCommunityRepository repository;

  setUp(() {
    repository = MockCommunityRepository();
    if (!sl.isRegistered<CommunityRepository>()) {
      sl.registerLazySingleton<CommunityRepository>(() => repository);
    }
    if (!sl.isRegistered<VenueRepository>()) {
      sl.registerLazySingleton<VenueRepository>(() => const MockVenueRepository());
    }
  });

  tearDown(() {
    sl.reset();
  });

  group('MockCommunityRepository Unit Tests', () {
    test('getFeed returns pre-seeded community posts', () async {
      final result = await repository.getFeed();
      expect(result.isSuccess, isTrue);
      final posts = result.dataOrNull!;
      expect(posts.isNotEmpty, isTrue);
      expect(posts.any((p) => p.type == PostType.gamePoll), isTrue);
      expect(posts.any((p) => p.type == PostType.image), isTrue);
    });

    test('getFeed filters by pollsOnly and myPostsOnly', () async {
      final pollsResult = await repository.getFeed(pollsOnly: true);
      expect(pollsResult.isSuccess, isTrue);
      expect(pollsResult.dataOrNull!.every((p) => p.type == PostType.gamePoll), isTrue);

      final myPostsResult = await repository.getFeed(
        myPostsOnly: true,
        currentUserId: currentUserId,
      );
      expect(myPostsResult.isSuccess, isTrue);
      expect(myPostsResult.dataOrNull!.every((p) => p.authorId == currentUserId), isTrue);
    });

    test('createImagePost appends a new photo post to feed', () async {
      final result = await repository.createImagePost(
        authorId: currentUserId,
        authorName: 'Alex Rivera',
        authorHandle: '@alex_pb',
        content: 'Testing out my new carbon fiber paddle!',
        mediaUrl: 'https://example.com/paddle.jpg',
        mediaTag: 'GearTalk',
      );

      expect(result.isSuccess, isTrue);
      final post = result.dataOrNull!;
      expect(post.content, contains('carbon fiber'));
      expect(post.mediaTag, 'GearTalk');
      expect(post.type, PostType.image);
    });

    test('createGameRequestPoll requires a valid recognized venue', () async {
      final validVenue = MockVenueRepository.defaultVenues.first;

      final successResult = await repository.createGameRequestPoll(
        authorId: currentUserId,
        authorName: 'Alex Rivera',
        authorHandle: '@alex_pb',
        content: 'Need 2 players for Doubles',
        venueId: validVenue.id,
        venueName: validVenue.name,
        venueAddress: validVenue.address,
        playDate: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '06:00 PM - 08:00 PM',
        gameFormat: 'Doubles (2v2)',
        targetSkillLevel: 'Intermediate (3.0 - 4.0)',
        optionTexts: ['Count me in!', 'Maybe next time'],
      );

      expect(successResult.isSuccess, isTrue);
      final pollPost = successResult.dataOrNull!;
      expect(pollPost.type, PostType.gamePoll);
      expect(pollPost.pollDetails?.venueName, validVenue.name);

      // Testing unrecognized venue fails validation
      final failResult = await repository.createGameRequestPoll(
        authorId: currentUserId,
        authorName: 'Alex Rivera',
        authorHandle: '@alex_pb',
        content: 'Invalid venue poll',
        venueId: 'unrecognized_venue_xyz',
        venueName: 'Fake Venue',
        venueAddress: 'Unknown',
        playDate: DateTime.now(),
        timeSlot: '08:00 AM',
        gameFormat: 'Singles',
        targetSkillLevel: 'Open',
        optionTexts: ['Yes', 'No'],
      );

      expect(failResult.isFailure, isTrue);
      expect(failResult.failureOrNull, isA<ValidationFailure>());
    });

    test('votePollOption casts vote, updates counts and allows switching', () async {
      final feed = (await repository.getFeed()).dataOrNull!;
      final pollPost = feed.firstWhere((p) => p.type == PostType.gamePoll);
      final optionId = pollPost.pollDetails!.options.first.id;

      final voteResult = await repository.votePollOption(
        postId: pollPost.id,
        optionId: optionId,
        currentUserId: currentUserId,
      );

      expect(voteResult.isSuccess, isTrue);
      final updatedPost = voteResult.dataOrNull!;
      expect(updatedPost.pollDetails?.myVotedOptionId, optionId);

      // Switch vote to second option
      final secondOptionId = pollPost.pollDetails!.options[1].id;
      final switchVoteResult = await repository.votePollOption(
        postId: pollPost.id,
        optionId: secondOptionId,
        currentUserId: currentUserId,
      );

      expect(switchVoteResult.isSuccess, isTrue);
      final switchedPost = switchVoteResult.dataOrNull!;
      expect(switchedPost.pollDetails?.myVotedOptionId, secondOptionId);
    });

    test('toggleLike increments and decrements like count', () async {
      final feed = (await repository.getFeed()).dataOrNull!;
      final post = feed.first;
      final initialLikes = post.likesCount;
      final initiallyLiked = post.isLikedByMe;

      final likeResult = await repository.toggleLike(
        postId: post.id,
        currentUserId: currentUserId,
      );
      expect(likeResult.isSuccess, isTrue);
      final likedPost = likeResult.dataOrNull!;
      expect(likedPost.isLikedByMe, !initiallyLiked);
      expect(likedPost.likesCount, initiallyLiked ? initialLikes - 1 : initialLikes + 1);
    });

    test('updatePost enforces strict ownership and rejects non-authors', () async {
      final feed = (await repository.getFeed()).dataOrNull!;
      final otherPlayerPost = feed.firstWhere((p) => p.authorId != currentUserId);

      // Non-author attempt to edit should be rejected with ForbiddenFailure
      final unauthorizedEdit = await repository.updatePost(
        postId: otherPlayerPost.id,
        currentUserId: currentUserId,
        updatedContent: 'Hacked caption',
      );
      expect(unauthorizedEdit.isFailure, isTrue);
      expect(unauthorizedEdit.failureOrNull, isA<ForbiddenFailure>());

      // Own post edit succeeds
      final ownPost = feed.firstWhere((p) => p.authorId == currentUserId);
      final authorizedEdit = await repository.updatePost(
        postId: ownPost.id,
        currentUserId: currentUserId,
        updatedContent: 'Updated my own post caption!',
      );
      expect(authorizedEdit.isSuccess, isTrue);
      expect(authorizedEdit.dataOrNull?.content, 'Updated my own post caption!');
      expect(authorizedEdit.dataOrNull?.isEdited, isTrue);
    });

    test('deletePost enforces strict ownership and rejects non-authors', () async {
      final feed = (await repository.getFeed()).dataOrNull!;
      final otherPlayerPost = feed.firstWhere((p) => p.authorId != currentUserId);

      // Non-author attempt to delete should fail with ForbiddenFailure
      final unauthorizedDelete = await repository.deletePost(
        postId: otherPlayerPost.id,
        currentUserId: currentUserId,
      );
      expect(unauthorizedDelete.isFailure, isTrue);
      expect(unauthorizedDelete.failureOrNull, isA<ForbiddenFailure>());

      // Own post deletion succeeds
      final ownPost = feed.firstWhere((p) => p.authorId == currentUserId);
      final authorizedDelete = await repository.deletePost(
        postId: ownPost.id,
        currentUserId: currentUserId,
      );
      expect(authorizedDelete.isSuccess, isTrue);

      final updatedFeed = (await repository.getFeed()).dataOrNull!;
      expect(updatedFeed.any((p) => p.id == ownPost.id), isFalse);
    });

    test('reportPost accepts report with reason and optional notes', () async {
      final feed = (await repository.getFeed()).dataOrNull!;
      final targetPost = feed.first;

      final reportResult = await repository.reportPost(
        postId: targetPost.id,
        reporterUserId: currentUserId,
        reason: CommunityReportReason.spam,
        notes: 'Commercial sales spam',
      );

      expect(reportResult.isSuccess, isTrue);
    });
  });

  group('Community Cubits Unit Tests', () {
    test('CommunityFeedCubit loads feed and switches filter tabs', () async {
      final cubit = CommunityFeedCubit(
        repository: repository,
        currentUserId: currentUserId,
      );

      expect(cubit.state, isA<CommunityFeedInitial>());
      await cubit.loadFeed();
      expect(cubit.state, isA<CommunityFeedLoaded>());

      cubit.setFilterTab(CommunityFilterTab.polls);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final loaded = cubit.state as CommunityFeedLoaded;
      expect(loaded.activeTab, CommunityFilterTab.polls);
      expect(loaded.posts.every((p) => p.type == PostType.gamePoll), isTrue);

      await cubit.close();
    });

    test('CreatePostCubit validates empty caption', () async {
      final cubit = CreatePostCubit(repository: repository);
      await cubit.submitPost(
        authorId: currentUserId,
        authorName: 'Alex',
        authorHandle: '@alex',
        content: '   ',
      );

      expect(cubit.state, isA<CreatePostFailure>());
      expect((cubit.state as CreatePostFailure).error, contains('cannot be empty'));
      await cubit.close();
    });

    test('CreateGamePollCubit validates option count', () async {
      final cubit = CreateGamePollCubit(
        communityRepository: repository,
        venueRepository: const MockVenueRepository(),
      );

      final validVenue = MockVenueRepository.defaultVenues.first;
      await cubit.submitPoll(
        authorId: currentUserId,
        authorName: 'Alex',
        authorHandle: '@alex',
        content: 'Match request',
        venue: validVenue,
        playDate: DateTime.now(),
        timeSlot: '06:00 PM',
        gameFormat: 'Doubles',
        targetSkillLevel: 'Open',
        optionTexts: ['Single option only'],
      );

      expect(cubit.state, isA<CreateGamePollFailure>());
      expect((cubit.state as CreateGamePollFailure).error, contains('at least 2 poll options'));
      await cubit.close();
    });

    test('PostCommentsCubit loads and adds comments', () async {
      final cubit = PostCommentsCubit(repository: repository);
      final feed = (await repository.getFeed()).dataOrNull!;
      final post = feed.first;

      await cubit.loadComments(post.id);
      expect(cubit.state, isA<PostCommentsLoaded>());

      final initialCount = (cubit.state as PostCommentsLoaded).comments.length;
      final added = await cubit.addComment(
        postId: post.id,
        authorId: currentUserId,
        authorName: 'Alex Rivera',
        content: 'Great match today!',
      );

      expect(added, isTrue);
      final updatedState = cubit.state as PostCommentsLoaded;
      expect(updatedState.comments.length, initialCount + 1);
      expect(updatedState.comments.last.content, 'Great match today!');
      await cubit.close();
    });
  });

  group('CommunityPostCard Widget Tests', () {
    testWidgets('renders author info, caption and post details', (tester) async {
      final feed = (await repository.getFeed()).dataOrNull!;
      final post = feed.firstWhere((p) => p.type == PostType.gamePoll);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: post,
                currentUserId: currentUserId,
                onToggleLike: () {},
                onOpenComments: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text(post.authorName), findsOneWidget);
      expect(find.text(post.authorHandle), findsOneWidget);
      expect(find.text(post.content), findsOneWidget);
      expect(find.text('Game Poll'), findsOneWidget);
    });

    testWidgets('own post shows Edit & Delete in popup menu, hides Report', (tester) async {
      final feed = (await repository.getFeed()).dataOrNull!;
      final ownPost = feed.firstWhere((p) => p.authorId == currentUserId);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: ownPost,
                currentUserId: currentUserId,
                onToggleLike: () {},
                onOpenComments: () {},
                onEditPost: () {},
                onDeletePost: () {},
              ),
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Edit Post'), findsOneWidget);
      expect(find.text('Delete Post'), findsOneWidget);
      expect(find.text('Report Post'), findsNothing);
    });

    testWidgets('other user post shows Report Post in popup menu, hides Edit & Delete', (tester) async {
      final feed = (await repository.getFeed()).dataOrNull!;
      final otherPost = feed.firstWhere((p) => p.authorId != currentUserId);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: otherPost,
                currentUserId: currentUserId,
                onToggleLike: () {},
                onOpenComments: () {},
                onReportPost: () {},
              ),
            ),
          ),
        ),
      );

      // Open menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Report Post'), findsOneWidget);
      expect(find.text('Edit Post'), findsNothing);
      expect(find.text('Delete Post'), findsNothing);
    });
  });

  group('PlayerCommunityPage Widget & Navigation Tests', () {
    testWidgets('renders community page with filter tabs and action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlayerCommunityPage(),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Community & Matchmaking'), findsOneWidget);
      expect(find.text('All Posts'), findsOneWidget);
      expect(find.text('Game Polls'), findsOneWidget);
      expect(find.text('Photos'), findsOneWidget);
      expect(find.text('My Posts'), findsOneWidget);
      expect(find.text('Request Game'), findsOneWidget);
      expect(find.text('New Post'), findsOneWidget);

      // Tap on Game Polls filter chip
      await tester.tap(find.text('Game Polls'));
      await tester.pumpAndSettle();

      // Only game polls should be displayed
      expect(find.text('Game Poll'), findsWidgets);
    });
  });
}
