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

  const player1 = 'user_player_001';
  const player2 = 'user_player_002';
  const player3 = 'user_player_003';
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

  group('MockCommunityRepository Basic Unit Tests', () {
    test('getFeed returns pre-seeded community posts', () async {
      final result = await repository.getFeed(currentUserId: player1);
      expect(result.isSuccess, isTrue);
      final posts = result.dataOrNull!;
      expect(posts.isNotEmpty, isTrue);
      expect(posts.any((p) => p.type == PostType.gamePoll), isTrue);
      expect(posts.any((p) => p.type == PostType.image), isTrue);
    });

    test('getFeed filters by pollsOnly and myPostsOnly', () async {
      final pollsResult = await repository.getFeed(pollsOnly: true, currentUserId: player1);
      expect(pollsResult.isSuccess, isTrue);
      expect(pollsResult.dataOrNull!.every((p) => p.type == PostType.gamePoll), isTrue);

      final myPostsResult = await repository.getFeed(
        myPostsOnly: true,
        currentUserId: player1,
      );
      expect(myPostsResult.isSuccess, isTrue);
      expect(myPostsResult.dataOrNull!.every((p) => p.authorId == player1), isTrue);
    });

    test('createImagePost appends a new photo post to feed', () async {
      final result = await repository.createImagePost(
        authorId: player1,
        authorName: 'Alex Rivera',
        authorHandle: '@alex_pb',
        content: 'Testing out my new carbon fiber paddle!',
        mediaUrl: 'assets/images/venues/venue_grand_slam.png',
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
        authorId: player1,
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
        authorId: player1,
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

    test('updatePost enforces strict ownership and rejects non-authors', () async {
      final feed = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final otherPlayerPost = feed.firstWhere((p) => p.authorId != player1);

      // Non-author attempt to edit should be rejected with ForbiddenFailure
      final unauthorizedEdit = await repository.updatePost(
        postId: otherPlayerPost.id,
        currentUserId: player1,
        updatedContent: 'Hacked caption',
      );
      expect(unauthorizedEdit.isFailure, isTrue);
      expect(unauthorizedEdit.failureOrNull, isA<ForbiddenFailure>());

      // Own post edit succeeds
      final ownPost = feed.firstWhere((p) => p.authorId == player1);
      final authorizedEdit = await repository.updatePost(
        postId: ownPost.id,
        currentUserId: player1,
        updatedContent: 'Updated my own post caption!',
      );
      expect(authorizedEdit.isSuccess, isTrue);
      expect(authorizedEdit.dataOrNull?.content, 'Updated my own post caption!');
      expect(authorizedEdit.dataOrNull?.isEdited, isTrue);
    });

    test('deletePost enforces strict ownership and rejects non-authors', () async {
      final feed = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final otherPlayerPost = feed.firstWhere((p) => p.authorId != player1);

      // Non-author attempt to delete should fail with ForbiddenFailure
      final unauthorizedDelete = await repository.deletePost(
        postId: otherPlayerPost.id,
        currentUserId: player1,
      );
      expect(unauthorizedDelete.isFailure, isTrue);
      expect(unauthorizedDelete.failureOrNull, isA<ForbiddenFailure>());

      // Own post deletion succeeds
      final ownPost = feed.firstWhere((p) => p.authorId == player1);
      final authorizedDelete = await repository.deletePost(
        postId: ownPost.id,
        currentUserId: player1,
      );
      expect(authorizedDelete.isSuccess, isTrue);

      final updatedFeed = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      expect(updatedFeed.any((p) => p.id == ownPost.id), isFalse);
    });

    test('reportPost accepts report with reason and optional notes', () async {
      final feed = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final targetPost = feed.first;

      final reportResult = await repository.reportPost(
        postId: targetPost.id,
        reporterUserId: player1,
        reason: CommunityReportReason.spam,
        notes: 'Commercial sales spam',
      );

      expect(reportResult.isSuccess, isTrue);
    });
  });

  group('User-Specific Likes Unit Tests (Issue 2)', () {
    test('like and unlike are tracked independently per player ID', () async {
      // 1. Initial state check on post_001 (12 initial community likes)
      final p1FeedInitial = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final p2FeedInitial = (await repository.getFeed(currentUserId: player2)).dataOrNull!;

      final postP1 = p1FeedInitial.firstWhere((p) => p.id == 'post_001');
      final postP2 = p2FeedInitial.firstWhere((p) => p.id == 'post_001');

      expect(postP1.isLikedByMe, isFalse);
      expect(postP2.isLikedByMe, isFalse);
      expect(postP1.likesCount, 12);
      expect(postP2.likesCount, 12);

      // 2. Player 1 likes post_001
      final p1LikeResult = await repository.toggleLike(postId: 'post_001', currentUserId: player1);
      expect(p1LikeResult.isSuccess, isTrue);
      expect(p1LikeResult.dataOrNull!.isLikedByMe, isTrue);
      expect(p1LikeResult.dataOrNull!.likesCount, 13);

      // 3. Player 2 retrieves feed: Player 2 must NOT see post_001 as liked, but aggregate count must be 13
      final p2FeedAfterP1 = (await repository.getFeed(currentUserId: player2)).dataOrNull!;
      final postP2AfterP1 = p2FeedAfterP1.firstWhere((p) => p.id == 'post_001');
      expect(postP2AfterP1.isLikedByMe, isFalse, reason: "Player 1's like must not leak to Player 2");
      expect(postP2AfterP1.likesCount, 13, reason: 'Aggregate like count must be preserved');

      // 4. Player 2 now also likes post_001
      final p2LikeResult = await repository.toggleLike(postId: 'post_001', currentUserId: player2);
      expect(p2LikeResult.isSuccess, isTrue);
      expect(p2LikeResult.dataOrNull!.isLikedByMe, isTrue);
      expect(p2LikeResult.dataOrNull!.likesCount, 14);

      // 5. Player 1 retrieves feed: Player 1 still has isLikedByMe = true, aggregate count = 14
      final p1FeedAfterP2 = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final postP1AfterP2 = p1FeedAfterP2.firstWhere((p) => p.id == 'post_001');
      expect(postP1AfterP2.isLikedByMe, isTrue);
      expect(postP1AfterP2.likesCount, 14);

      // 6. Player 1 unlikes post_001
      final p1UnlikeResult = await repository.toggleLike(postId: 'post_001', currentUserId: player1);
      expect(p1UnlikeResult.isSuccess, isTrue);
      expect(p1UnlikeResult.dataOrNull!.isLikedByMe, isFalse);
      expect(p1UnlikeResult.dataOrNull!.likesCount, 13);

      // 7. Player 2 retrieves feed: Player 2 still has isLikedByMe = true, aggregate count = 13
      final p2FeedAfterP1Unlike = (await repository.getFeed(currentUserId: player2)).dataOrNull!;
      final postP2AfterP1Unlike = p2FeedAfterP1Unlike.firstWhere((p) => p.id == 'post_001');
      expect(postP2AfterP1Unlike.isLikedByMe, isTrue, reason: "Player 2's like must remain unaffected");
      expect(postP2AfterP1Unlike.likesCount, 13);
    });
  });

  group('User-Specific Poll Voting Unit Tests (Issue 3)', () {
    test('poll voting derives myVotedOptionId independently and preserves vote switching', () async {
      // 1. Initial state: on post_001, neither Player 1 nor Player 2 has voted
      final p1FeedInitial = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final p2FeedInitial = (await repository.getFeed(currentUserId: player2)).dataOrNull!;

      final pollP1 = p1FeedInitial.firstWhere((p) => p.id == 'post_001').pollDetails!;
      final pollP2 = p2FeedInitial.firstWhere((p) => p.id == 'post_001').pollDetails!;

      expect(pollP1.myVotedOptionId, isNull);
      expect(pollP2.myVotedOptionId, isNull);
      expect(pollP1.options.firstWhere((o) => o.id == 'opt_1').voteCount, 3);
      expect(pollP1.options.firstWhere((o) => o.id == 'opt_2').voteCount, 1);
      expect(pollP1.totalVotes, 4);

      // 2. Player 1 votes for option 1 ('opt_1')
      final p1VoteResult = await repository.votePollOption(
        postId: 'post_001',
        optionId: 'opt_1',
        currentUserId: player1,
      );
      expect(p1VoteResult.isSuccess, isTrue);
      final p1UpdatedPoll = p1VoteResult.dataOrNull!.pollDetails!;
      expect(p1UpdatedPoll.myVotedOptionId, 'opt_1');
      expect(p1UpdatedPoll.options.firstWhere((o) => o.id == 'opt_1').voteCount, 4);
      expect(p1UpdatedPoll.totalVotes, 5);

      // 3. Player 2 retrieves feed: Player 2 must NOT have voted, but opt_1 count must be 4
      final p2FeedAfterP1 = (await repository.getFeed(currentUserId: player2)).dataOrNull!;
      final p2PollAfterP1 = p2FeedAfterP1.firstWhere((p) => p.id == 'post_001').pollDetails!;
      expect(p2PollAfterP1.myVotedOptionId, isNull, reason: "Player 1's vote must not be shared with Player 2");
      expect(p2PollAfterP1.options.firstWhere((o) => o.id == 'opt_1').voteCount, 4);
      expect(p2PollAfterP1.totalVotes, 5);

      // 4. Player 2 votes for option 2 ('opt_2')
      final p2VoteResult = await repository.votePollOption(
        postId: 'post_001',
        optionId: 'opt_2',
        currentUserId: player2,
      );
      expect(p2VoteResult.isSuccess, isTrue);
      final p2UpdatedPoll = p2VoteResult.dataOrNull!.pollDetails!;
      expect(p2UpdatedPoll.myVotedOptionId, 'opt_2');
      expect(p2UpdatedPoll.options.firstWhere((o) => o.id == 'opt_1').voteCount, 4);
      expect(p2UpdatedPoll.options.firstWhere((o) => o.id == 'opt_2').voteCount, 2);
      expect(p2UpdatedPoll.totalVotes, 6);

      // 5. Player 1 checks feed: Player 1 still has myVotedOptionId = 'opt_1', total votes = 6
      final p1FeedAfterP2 = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final p1PollAfterP2 = p1FeedAfterP2.firstWhere((p) => p.id == 'post_001').pollDetails!;
      expect(p1PollAfterP2.myVotedOptionId, 'opt_1');
      expect(p1PollAfterP2.options.firstWhere((o) => o.id == 'opt_1').voteCount, 4);
      expect(p1PollAfterP2.options.firstWhere((o) => o.id == 'opt_2').voteCount, 2);
      expect(p1PollAfterP2.totalVotes, 6);

      // 6. Player 1 switches vote from 'opt_1' to 'opt_2'
      final p1SwitchResult = await repository.votePollOption(
        postId: 'post_001',
        optionId: 'opt_2',
        currentUserId: player1,
      );
      expect(p1SwitchResult.isSuccess, isTrue);
      final p1SwitchedPoll = p1SwitchResult.dataOrNull!.pollDetails!;
      expect(p1SwitchedPoll.myVotedOptionId, 'opt_2');
      // opt_1 drops from 4 to 3
      expect(p1SwitchedPoll.options.firstWhere((o) => o.id == 'opt_1').voteCount, 3);
      // opt_2 increases from 2 to 3 (contains both player1 and player2)
      expect(p1SwitchedPoll.options.firstWhere((o) => o.id == 'opt_2').voteCount, 3);
      expect(p1SwitchedPoll.totalVotes, 6);

      // 7. Player 2 retrieves feed: Player 2 still has myVotedOptionId = 'opt_2'
      final p2FeedAfterSwitch = (await repository.getFeed(currentUserId: player2)).dataOrNull!;
      final p2PollAfterSwitch = p2FeedAfterSwitch.firstWhere((p) => p.id == 'post_001').pollDetails!;
      expect(p2PollAfterSwitch.myVotedOptionId, 'opt_2');
      expect(p2PollAfterSwitch.options.firstWhere((o) => o.id == 'opt_1').voteCount, 3);
      expect(p2PollAfterSwitch.options.firstWhere((o) => o.id == 'opt_2').voteCount, 3);
      expect(p2PollAfterSwitch.totalVotes, 6);
    });
  });

  group('Community Cubits Unit Tests with Multi-User Isolation', () {
    test('CommunityFeedCubit maintains independent states for different player IDs', () async {
      final cubit1 = CommunityFeedCubit(repository: repository, currentUserId: player1);
      final cubit2 = CommunityFeedCubit(repository: repository, currentUserId: player2);

      await cubit1.loadFeed();
      await cubit2.loadFeed();

      final state1 = cubit1.state as CommunityFeedLoaded;
      final state2 = cubit2.state as CommunityFeedLoaded;

      // post_001 unliked by both initially
      expect(state1.posts.firstWhere((p) => p.id == 'post_001').isLikedByMe, isFalse);
      expect(state2.posts.firstWhere((p) => p.id == 'post_001').isLikedByMe, isFalse);

      // Player 1 likes post_001
      await cubit1.toggleLike('post_001');
      final state1After = cubit1.state as CommunityFeedLoaded;
      expect(state1After.posts.firstWhere((p) => p.id == 'post_001').isLikedByMe, isTrue);

      // Player 2 loads feed and verifies isolation
      await cubit2.loadFeed();
      final state2After = cubit2.state as CommunityFeedLoaded;
      expect(state2After.posts.firstWhere((p) => p.id == 'post_001').isLikedByMe, isFalse);
      expect(state2After.posts.firstWhere((p) => p.id == 'post_001').likesCount, 13);

      await cubit1.close();
      await cubit2.close();
    });

    test('CreatePostCubit validates empty caption', () async {
      final cubit = CreatePostCubit(repository: repository);
      await cubit.submitPost(
        authorId: player1,
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
        authorId: player1,
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
      final feed = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final post = feed.first;

      await cubit.loadComments(post.id);
      expect(cubit.state, isA<PostCommentsLoaded>());

      final initialCount = (cubit.state as PostCommentsLoaded).comments.length;
      final added = await cubit.addComment(
        postId: post.id,
        authorId: player1,
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

  group('CommunityPostCard Widget Tests (Photo Rendering & Interactions)', () {
    testWidgets('renders local asset photo correctly when mediaUrl is an asset path', (tester) async {
      final postWithAsset = CommunityPost(
        id: 'post_asset_test',
        type: PostType.image,
        authorId: player3,
        authorName: 'Test Player',
        authorHandle: '@test_player',
        content: 'Playing at Grand Slam court!',
        mediaUrl: 'assets/images/venues/venue_grand_slam.png',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: postWithAsset,
                currentUserId: player1,
                onToggleLike: () {},
                onOpenComments: () {},
              ),
            ),
          ),
        ),
      );

      // Verify Image widget is rendered with AssetImage provider
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final Image imageWidget = tester.widget(imageFinder);
      expect(imageWidget.image, isA<AssetImage>());
      expect((imageWidget.image as AssetImage).assetName, 'assets/images/venues/venue_grand_slam.png');
    });

    testWidgets('renders network photo when mediaUrl is a http URL', (tester) async {
      final postWithNetwork = CommunityPost(
        id: 'post_network_test',
        type: PostType.image,
        authorId: player3,
        authorName: 'Network Player',
        authorHandle: '@net_player',
        content: 'Playing under the sun!',
        mediaUrl: 'https://images.unsplash.com/photo-1599586120429-48281b6f0ece',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: postWithNetwork,
                currentUserId: player1,
                onToggleLike: () {},
                onOpenComments: () {},
              ),
            ),
          ),
        ),
      );

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);
      final Image imageWidget = tester.widget(imageFinder);
      expect(imageWidget.image, isA<NetworkImage>());
    });

    testWidgets('renders fallback icon on broken image', (tester) async {
      final postWithBroken = CommunityPost(
        id: 'post_broken_test',
        type: PostType.image,
        authorId: player3,
        authorName: 'Broken Player',
        authorHandle: '@broken',
        content: 'Broken image post',
        mediaUrl: 'assets/images/non_existent_image.png',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: postWithBroken,
                currentUserId: player1,
                onToggleLike: () {},
                onOpenComments: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('own post shows Edit & Delete in popup menu, hides Report', (tester) async {
      final feed = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final ownPost = feed.firstWhere((p) => p.authorId == player1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: ownPost,
                currentUserId: player1,
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
      final feed = (await repository.getFeed(currentUserId: player1)).dataOrNull!;
      final otherPost = feed.firstWhere((p) => p.authorId != player1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommunityPostCard(
                post: otherPost,
                currentUserId: player1,
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
