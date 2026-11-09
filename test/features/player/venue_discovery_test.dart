import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_venue_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/venue_discovery_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/venue_discovery_page.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/venue_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/venue_search_bar.dart';

class _FailingVenueRepository implements VenueRepository {
  final Failure failure;
  const _FailingVenueRepository(this.failure);

  @override
  Future<Result<List<VenueItem>>> getVenues({VenueFilter? filter}) async {
    return FailureResult(failure);
  }

  @override
  Future<Result<VenueItem>> getVenueById(String id) async {
    return FailureResult(failure);
  }

  @override
  Future<Result<List<CourtItem>>> getCourts(String venueId, {DateTime? date}) async {
    return FailureResult(failure);
  }

  @override
  Future<Result<List<CourtSlot>>> getCourtSlots({
    required String venueId,
    required String courtId,
    required DateTime date,
  }) async {
    return FailureResult(failure);
  }
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const venue1 = VenueItem(
    id: 'v_1',
    name: 'Andheri Tennis & Pickleball Hub',
    address: 'Andheri West',
    city: 'Mumbai',
    distanceKm: 2.0,
    courtCount: 6,
    surfaceTypes: ['Pro Cushion'],
    isIndoor: true,
    hasNightLights: true,
    amenities: ['Night Lights', 'Equipment Rental', 'Parking'],
    rating: 4.8,
    reviewCount: 150,
    minHourlyRate: 500.0,
    maxHourlyRate: 800.0,
    operatingHours: '06:00 - 23:00',
  );

  const venue2 = VenueItem(
    id: 'v_2',
    name: 'Bandra Smash Courts',
    address: 'Bandra West',
    city: 'Mumbai',
    distanceKm: 7.5,
    courtCount: 4,
    surfaceTypes: ['Acrylic Hardcourt'],
    isIndoor: false,
    hasNightLights: false,
    amenities: ['Parking'],
    rating: 4.2,
    reviewCount: 60,
    minHourlyRate: 400.0,
    maxHourlyRate: 550.0,
    operatingHours: '06:00 - 19:00',
  );

  const venue3 = VenueItem(
    id: 'v_3',
    name: 'BKC Premium Arena',
    address: 'BKC',
    city: 'Mumbai',
    distanceKm: 12.0,
    courtCount: 10,
    surfaceTypes: ['Pro Cushion'],
    isIndoor: true,
    hasNightLights: true,
    amenities: ['Night Lights', 'Equipment Rental', 'Pro Shop', 'Parking', 'Showers'],
    rating: 4.95,
    reviewCount: 300,
    minHourlyRate: 1200.0,
    maxHourlyRate: 1800.0,
    operatingHours: '24 Hours',
  );

  final testVenues = [venue1, venue2, venue3];

  group('Venue Discovery Entities Unit Tests', () {
    test('VenueItem copyWith preserves unchanged attributes and supports equality', () {
      final copy = venue1.copyWith(rating: 4.9);
      expect(copy.id, venue1.id);
      expect(copy.rating, 4.9);
      expect(copy.courtCount, 6);
      expect(copy == venue1, isFalse);
    });

    test('VenueFilter calculates activeFilterCount accurately', () {
      const defaultFilter = VenueFilter.defaultFilter();
      expect(defaultFilter.activeFilterCount, 0);
      expect(defaultFilter.hasActiveFilters, isFalse);

      final filterWithCriteria = defaultFilter.copyWith(
        maxDistanceKm: 10.0,
        minRating: 4.5,
        priceTier: VenuePriceTier.budget,
        indoorOnly: true,
        requiredAmenities: {'Night Lights', 'Parking'},
      );

      // 1 (distance) + 1 (rating) + 1 (price) + 1 (indoor) + 2 (amenities) = 6
      expect(filterWithCriteria.activeFilterCount, 6);
      expect(filterWithCriteria.hasActiveFilters, isTrue);
    });
  });

  group('VenueDiscoveryCubit Unit Tests', () {
    test('initial state is VenueDiscoveryInitial', () {
      final cubit = VenueDiscoveryCubit(
        repository: const MockVenueRepository(),
      );
      expect(cubit.state, const VenueDiscoveryInitial());
      cubit.close();
    });

    test('loadVenues emits [Loading, Loaded] with default mock venues', () async {
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const VenueDiscoveryLoading(),
          isA<VenueDiscoveryLoaded>(),
        ]),
      );

      await cubit.loadVenues();
      expect(cubit.state, isA<VenueDiscoveryLoaded>());

      final loaded = cubit.state as VenueDiscoveryLoaded;
      expect(loaded.venues.length, 3);
      expect(loaded.totalCount, 3);

      await cubit.close();
    });

    test('updateSearchQuery filters venues by name or location', () async {
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );
      await cubit.loadVenues();

      await cubit.updateSearchQuery('Bandra');
      final loaded = cubit.state as VenueDiscoveryLoaded;
      expect(loaded.venues.length, 1);
      expect(loaded.venues.first.name, 'Bandra Smash Courts');

      await cubit.close();
    });

    test('updateFilter applies combined criteria (distance, price, indoor)', () async {
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );
      await cubit.loadVenues();

      // Only venue1 is within 5km and indoor
      await cubit.updateFilter(
        const VenueFilter(
          maxDistanceKm: 5.0,
          indoorOnly: true,
        ),
      );

      final loaded = cubit.state as VenueDiscoveryLoaded;
      expect(loaded.venues.length, 1);
      expect(loaded.venues.first.id, 'v_1');

      await cubit.close();
    });

    test('updateSortOption sorts listings properly', () async {
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );
      await cubit.loadVenues();

      // Sort by rating descending: venue3 (4.95) -> venue1 (4.8) -> venue2 (4.2)
      await cubit.updateSortOption(VenueSortOption.ratingDesc);
      final loadedDesc = cubit.state as VenueDiscoveryLoaded;
      expect(loadedDesc.venues.first.id, 'v_3');
      expect(loadedDesc.venues.last.id, 'v_2');

      // Sort by price ascending: venue2 (min 400) -> venue1 (min 500) -> venue3 (min 1200)
      await cubit.updateSortOption(VenueSortOption.priceAsc);
      final loadedPrice = cubit.state as VenueDiscoveryLoaded;
      expect(loadedPrice.venues.first.id, 'v_2');
      expect(loadedPrice.venues.last.id, 'v_3');

      await cubit.close();
    });

    test('clearFilters resets filter parameters and restores complete list', () async {
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );
      await cubit.loadVenues();

      await cubit.updateSearchQuery('NonExistentPlace');
      expect((cubit.state as VenueDiscoveryLoaded).venues.isEmpty, isTrue);

      await cubit.clearFilters();
      final loaded = cubit.state as VenueDiscoveryLoaded;
      expect(loaded.venues.length, 3);
      expect(loaded.filter.searchQuery.isEmpty, isTrue);

      await cubit.close();
    });

    test('loadVenues emits [Loading, Failure] when repository fails', () async {
      const failure = ServerFailure(message: 'Database unavailable');
      final cubit = VenueDiscoveryCubit(
        repository: const _FailingVenueRepository(failure),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const VenueDiscoveryLoading(),
          const VenueDiscoveryFailure(failure),
        ]),
      );

      await cubit.loadVenues();
      expect(cubit.state, const VenueDiscoveryFailure(failure));

      await cubit.close();
    });
  });

  group('VenueDiscoveryPage Widget Tests', () {
    void setTallViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
    }

    testWidgets('renders loading state initially', (tester) async {
      setTallViewport(tester);
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDiscoveryPage(cubit: cubit),
        ),
      );

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('Searching available venues...'), findsOneWidget);

      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets('renders venue list, search bar, and cards on load', (tester) async {
      setTallViewport(tester);
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDiscoveryPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discover Courts & Venues'), findsOneWidget);
      expect(find.byType(VenueSearchBar), findsOneWidget);
      expect(find.byType(VenueCard), findsNWidgets(3));
      expect(find.text('Andheri Tennis & Pickleball Hub'), findsOneWidget);
      expect(find.text('Bandra Smash Courts'), findsOneWidget);
      expect(find.text('BKC Premium Arena'), findsOneWidget);
      expect(find.text('Showing 3 venues'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('typing in search bar filters venues dynamically', (tester) async {
      setTallViewport(tester);
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDiscoveryPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Andheri');
      await tester.pumpAndSettle();

      expect(find.text('Andheri Tennis & Pickleball Hub'), findsOneWidget);
      expect(find.text('Bandra Smash Courts'), findsNothing);
      expect(find.text('Showing 1 venue'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('empty search results displays empty state with clear filters CTA', (tester) async {
      setTallViewport(tester);
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDiscoveryPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      // Search for non-existent venue
      await tester.enterText(find.byType(TextField), 'UnknownCityLocation999');
      await tester.pumpAndSettle();

      expect(find.text('No Venues Found'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);

      // Tap "Clear Filters"
      await tester.tap(find.text('Clear Filters'));
      await tester.pumpAndSettle();

      expect(find.byType(VenueCard), findsNWidgets(3));
      expect(find.text('Showing 3 venues'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('tapping a venue card navigates to venue details placeholder route', (tester) async {
      setTallViewport(tester);
      String? lastPushedPath;
      String? lastPushedTitle;

      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );
      await cubit.loadVenues();

      final router = GoRouter(
        initialLocation: AppRoutes.playerVenues,
        routes: [
          GoRoute(
            path: AppRoutes.playerVenues,
            builder: (context, state) => VenueDiscoveryPage(cubit: cubit),
          ),
          GoRoute(
            path: AppRoutes.playerVenueDetails,
            builder: (context, state) {
              lastPushedPath = state.uri.path;
              lastPushedTitle = state.extra as String?;
              return const Scaffold(body: Text('Venue Details Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      final firstCard = find.text('Andheri Tennis & Pickleball Hub');
      expect(firstCard, findsOneWidget);
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      expect(lastPushedPath, AppRoutes.playerVenueDetailsPath('v_1'));
      expect(lastPushedTitle, 'Andheri Tennis & Pickleball Hub');

      await cubit.close();
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      setTallViewport(tester);
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          child: VenueDiscoveryPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Discover Courts & Venues'), findsOneWidget);
      expect(find.byType(VenueCard), findsNWidgets(3));

      await cubit.close();
    });

    testWidgets('renders responsive grid layout on wide viewport', (tester) async {
      final cubit = VenueDiscoveryCubit(
        repository: MockVenueRepository(customVenues: testVenues),
      );

      // Desktop viewport size 1200x900
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _buildTestFrame(
          size: const Size(1200, 900),
          child: VenueDiscoveryPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VenueCard), findsNWidgets(3));
      expect(find.byType(SliverGrid), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders error view with retry callback on repository failure', (tester) async {
      setTallViewport(tester);
      const failure = NetworkFailure(message: 'Connection failed');
      final cubit = VenueDiscoveryCubit(
        repository: const _FailingVenueRepository(failure),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: VenueDiscoveryPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Unable to Load Venues'), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
      'search field maintains focus and cursor position while typing multiple characters and updating results',
      (tester) async {
        setTallViewport(tester);
        final cubit = VenueDiscoveryCubit(
          repository: MockVenueRepository(customVenues: testVenues),
        );

        await tester.pumpWidget(
          _buildTestFrame(
            child: VenueDiscoveryPage(cubit: cubit),
          ),
        );
        await tester.pumpAndSettle();

        final searchTextFieldFinder = find.byType(TextField);
        expect(searchTextFieldFinder, findsOneWidget);

        // Tap search field to request focus
        await tester.tap(searchTextFieldFinder);
        await tester.pump();

        // Verify focus is acquired
        expect(tester.widget<TextField>(searchTextFieldFinder).focusNode?.hasFocus, isTrue);

        // Sequentially type multiple characters simulating user keystrokes
        for (final query in ['A', 'An', 'And', 'Andh']) {
          await tester.enterText(searchTextFieldFinder, query);
          await tester.pump();

          // Verify focus remains held and search field is not unmounted or replaced
          expect(tester.widget<TextField>(searchTextFieldFinder).focusNode?.hasFocus, isTrue);

          // Verify cursor position is maintained at the end of the input
          final textField = tester.widget<TextField>(searchTextFieldFinder);
          expect(textField.controller?.selection.baseOffset, equals(query.length));
        }

        await tester.pumpAndSettle();

        // Verify results updated properly matching the final search term
        expect(find.text('Andheri Tennis & Pickleball Hub'), findsOneWidget);
        expect(find.text('Bandra Smash Courts'), findsNothing);
        expect(find.text('Showing 1 venue'), findsOneWidget);

        await cubit.close();
      },
    );

    testWidgets(
      'displays venue photographs in cards with graceful fallback placeholder when image unavailable',
      (tester) async {
        setTallViewport(tester);
        final customVenues = [
          venue1.copyWith(imageUrl: 'assets/images/venues/venue_grand_slam.png'),
          venue2.copyWith(imageUrl: null),
        ];
        final cubit = VenueDiscoveryCubit(
          repository: MockVenueRepository(customVenues: customVenues),
        );

        await tester.pumpWidget(
          _buildTestFrame(
            child: VenueDiscoveryPage(cubit: cubit),
          ),
        );
        await tester.pumpAndSettle();

        // Venue 1 displays photograph image widget
        expect(find.byType(Image), findsWidgets);

        // Venue 2 (null imageUrl) displays fallback tennis icon placeholder
        expect(find.byIcon(Icons.sports_tennis), findsWidgets);

        await cubit.close();
      },
    );
  });
}
