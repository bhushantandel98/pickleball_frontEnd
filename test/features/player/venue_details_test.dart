import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_venue_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_details_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/venue_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/venue_gallery_view.dart';

Widget _buildTestFrame({
  required Widget child,
  ThemeMode mode = ThemeMode.light,
  Size size = const Size(800, 1600),
}) {
  return MaterialApp(
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: mode,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: child,
    ),
  );
}

void setTallViewport(WidgetTester tester, [Size size = const Size(800, 2000)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleReviews = [
    VenueReview(
      id: 'rev_1',
      reviewerName: 'Vikram Mehta',
      rating: 5.0,
      date: '02 Nov 2026',
      comment: 'Top quality courts and great lighting!',
    ),
    VenueReview(
      id: 'rev_2',
      reviewerName: 'Ananya Sharma',
      rating: 4.8,
      date: '28 Oct 2026',
      comment: 'Clean amenities and helpful staff.',
    ),
  ];

  const testVenue = VenueItem(
    id: 'test_venue_001',
    name: 'Champion Court Arena',
    imageUrl: 'assets/images/venues/venue_grand_slam.png',
    galleryImages: [
      'assets/images/venues/venue_grand_slam.png',
      'assets/images/venues/venue_pinnacle.png',
      'assets/images/venues/venue_dink_smash.png',
    ],
    description:
        'A state-of-the-art facility featuring 8 tournament-standard courts with optimal lighting and premium cushioning.',
    address: '100 Marine Drive, Nariman Point',
    city: 'Mumbai',
    distanceKm: 2.5,
    courtCount: 8,
    surfaceTypes: ['Pro Cushion', 'Acrylic Hardcourt'],
    isIndoor: true,
    hasNightLights: true,
    amenities: [
      'Night Lights',
      'Equipment Rental',
      'Pro Shop',
      'Locker Rooms',
      'Parking',
      'Cafeteria',
      'Showers',
    ],
    rating: 4.85,
    reviewCount: 214,
    minHourlyRate: 500.0,
    maxHourlyRate: 900.0,
    operatingHours: '06:00 - 23:00',
    cancellationPolicy: 'Free cancellation up to 4 hours before slot time.',
    supportedSports: ['Pickleball', 'Tennis'],
    reviews: sampleReviews,
  );

  group('VenueDetailsCubit Unit Tests', () {
    late MockVenueRepository repository;

    setUp(() {
      repository = const MockVenueRepository(customVenues: [testVenue]);
    });

    test('initial state is VenueDetailsInitial', () {
      final cubit = VenueDetailsCubit(repository: repository);
      expect(cubit.state, equals(const VenueDetailsInitial()));
      cubit.close();
    });

    test('loadVenueDetails emits [Loading, Loaded] when venue is found', () async {
      final cubit = VenueDetailsCubit(repository: repository);

      final expected = [
        const VenueDetailsLoading(),
        const VenueDetailsLoaded(venue: testVenue),
      ];

      expectLater(cubit.stream, emitsInOrder(expected));
      await cubit.loadVenueDetails('test_venue_001');

      await cubit.close();
    });

    test('loadVenueDetails emits [Loading, Failure] when venue not found', () async {
      final cubit = VenueDetailsCubit(repository: repository);

      final expected = [
        const VenueDetailsLoading(),
        const VenueDetailsFailure(NotFoundFailure(message: 'Venue not found')),
      ];

      expectLater(cubit.stream, emitsInOrder(expected));
      await cubit.loadVenueDetails('non_existent_id');

      await cubit.close();
    });

    test('selectGalleryImage updates selectedImageIndex in loaded state', () async {
      final cubit = VenueDetailsCubit(repository: repository);
      await cubit.loadVenueDetails('test_venue_001');

      expect((cubit.state as VenueDetailsLoaded).selectedImageIndex, equals(0));

      cubit.selectGalleryImage(2);
      expect((cubit.state as VenueDetailsLoaded).selectedImageIndex, equals(2));

      // Out of bounds selection does not alter index
      cubit.selectGalleryImage(99);
      expect((cubit.state as VenueDetailsLoaded).selectedImageIndex, equals(2));

      await cubit.close();
    });
  });

  group('VenueDetailsPage Widget Tests', () {
    late MockVenueRepository repository;

    setUp(() {
      repository = const MockVenueRepository(customVenues: [testVenue]);
    });

    testWidgets('renders loading state initially', (tester) async {
      final cubit = VenueDetailsCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDetailsPage(
            venueId: 'test_venue_001',
            cubit: cubit,
          ),
        ),
      );

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('Loading venue details...'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders full venue details when loaded', (tester) async {
      setTallViewport(tester);
      final cubit = VenueDetailsCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDetailsPage(
            venueId: 'test_venue_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Venue overview verification
      expect(find.text('Champion Court Arena'), findsWidgets);
      expect(find.text('4.8'), findsWidgets);
      expect(find.text('(214 reviews)'), findsWidgets);
      expect(find.text('2.5 km away'), findsOneWidget);
      expect(find.text('100 Marine Drive, Nariman Point, Mumbai'), findsOneWidget);
      expect(find.text('About This Venue'), findsOneWidget);
      expect(find.text(testVenue.description), findsOneWidget);

      // Courts & facilities verification
      expect(find.text('Courts & Facilities'), findsOneWidget);
      expect(find.text('8 Courts'), findsWidgets);
      expect(find.text('Indoor Arena'), findsOneWidget);
      expect(find.text('Night Floodlights'), findsOneWidget);
      expect(find.text('Pro Cushion'), findsOneWidget);

      // Amenities verification
      expect(find.text('Amenities & Services'), findsOneWidget);
      expect(find.text('Equipment Rental'), findsOneWidget);
      expect(find.text('Pro Shop'), findsOneWidget);
      expect(find.text('Locker Rooms'), findsOneWidget);
      expect(find.text('Parking'), findsOneWidget);

      // Pricing and policies verification
      expect(find.text('Pricing & Operational Policies'), findsOneWidget);
      expect(find.text('₹500 - ₹900 / hr'), findsOneWidget);
      expect(find.text('06:00 - 23:00'), findsOneWidget);
      expect(find.text('Cancellation Policy'), findsOneWidget);

      // Reviews verification
      expect(find.text('Player Reviews'), findsOneWidget);
      expect(find.text('Vikram Mehta'), findsOneWidget);
      expect(find.text('Ananya Sharma'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('gallery thumbnail tap switches active photo index', (tester) async {
      setTallViewport(tester);
      final cubit = VenueDetailsCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDetailsPage(
            venueId: 'test_venue_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VenueGalleryView), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);

      // Tap on second thumbnail
      final thumbFinder = find.byKey(const Key('venue_gallery_thumb_1'));
      expect(thumbFinder, findsOneWidget);

      await tester.tap(thumbFinder);
      await tester.pumpAndSettle();

      // Counter updates to 2 / 3
      expect(find.text('2 / 3'), findsOneWidget);
      expect((cubit.state as VenueDetailsLoaded).selectedImageIndex, equals(1));

      await cubit.close();
    });

    testWidgets('tapping View All Reviews displays all reviews dialog', (tester) async {
      setTallViewport(tester);
      final cubit = VenueDetailsCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDetailsPage(
            venueId: 'test_venue_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to reviews section if needed
      await tester.ensureVisible(find.text('View All Reviews'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View All Reviews'));
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('All Player Reviews (214)'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Tap close button
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);

      await cubit.close();
    });

    testWidgets('tapping Check Availability navigates to Court Availability placeholder',
        (tester) async {
      setTallViewport(tester);

      final router = GoRouter(
        initialLocation: AppRoutes.playerVenueDetailsPath('test_venue_001'),
        routes: [
          GoRoute(
            path: AppRoutes.playerVenueDetails,
            builder: (context, state) => VenueDetailsPage(
              venueId: state.pathParameters['id'] ?? '',
              cubit: VenueDetailsCubit(repository: repository),
            ),
          ),
          GoRoute(
            path: AppRoutes.playerCourtAvailability,
            builder: (context, state) => Scaffold(
              body: Text('Court Availability Placeholder for ${state.extra}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Find primary CTA
      final ctaFinder = find.text('Check Availability');
      expect(ctaFinder, findsOneWidget);

      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();

      expect(find.text('Court Availability Placeholder for Champion Court Arena'), findsOneWidget);
    });

    testWidgets('renders ErrorStateView when venue is not found with back action',
        (tester) async {
      setTallViewport(tester);
      final cubit = VenueDetailsCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDetailsPage(
            venueId: 'unknown_id_404',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Venue Not Found'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      setTallViewport(tester);
      final cubit = VenueDetailsCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          child: VenueDetailsPage(
            venueId: 'test_venue_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Champion Court Arena'), findsWidgets);
      expect(find.text('Courts & Facilities'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders responsive 2-column desktop layout on wide viewport',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cubit = VenueDetailsCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          size: const Size(1200, 1000),
          child: VenueDetailsPage(
            venueId: 'test_venue_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Champion Court Arena'), findsWidgets);
      expect(find.text('Check Availability'), findsOneWidget);

      await cubit.close();
    });
  });
}
