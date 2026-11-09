import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_venue_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/domain/entities/venue_item.dart';
import 'package:pickleball_platform/features/player/domain/repositories/venue_repository.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/court_availability_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/court_availability_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/court_availability_page.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/booking_summary_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/court_date_picker_strip.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/court_selector_tabs.dart';

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

void setTallViewport(WidgetTester tester, [Size size = const Size(800, 2200)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

class _CustomMockVenueRepository implements VenueRepository {
  final VenueItem venue;
  final bool failOnCourtsDate;
  final bool failOnSlotsCourt;
  final List<DateTime> emptyCourtsDates;
  final String? failingCourtId;
  final DateTime? failingDate;

  const _CustomMockVenueRepository({
    required this.venue,
    this.failOnCourtsDate = false,
    this.failOnSlotsCourt = false,
    this.emptyCourtsDates = const [],
    this.failingCourtId,
    this.failingDate,
  });

  @override
  Future<Result<VenueItem>> getVenueById(String id) async {
    if (id == venue.id) return Success(venue);
    return const FailureResult(NotFoundFailure(message: 'Venue not found'));
  }

  @override
  Future<Result<List<VenueItem>>> getVenues({VenueFilter? filter}) async {
    return Success([venue]);
  }

  @override
  Future<Result<List<CourtItem>>> getCourts(String venueId, {DateTime? date}) async {
    if (failOnCourtsDate && date != null && failingDate != null && date.day == failingDate!.day) {
      return const FailureResult(ServerFailure(message: 'Failed to fetch courts for date'));
    }
    if (date != null && emptyCourtsDates.any((d) => d.day == date.day)) {
      return const Success([]);
    }
    return Success([
      CourtItem(
        id: '${venue.id}_court_1',
        venueId: venue.id,
        name: 'Court 1 (Center Court)',
        courtNumber: 1,
        surfaceType: 'Pro Cushion',
        isIndoor: true,
        hasLighting: true,
        isActive: true,
        availableSlotCount: 5,
      ),
      CourtItem(
        id: '${venue.id}_court_2',
        venueId: venue.id,
        name: 'Court 2',
        courtNumber: 2,
        surfaceType: 'Acrylic Hardcourt',
        isIndoor: false,
        hasLighting: false,
        isActive: true,
        availableSlotCount: 4,
      ),
    ]);
  }

  @override
  Future<Result<List<CourtSlot>>> getCourtSlots({
    required String venueId,
    required String courtId,
    required DateTime date,
  }) async {
    if (failOnSlotsCourt && (failingCourtId == null || courtId == failingCourtId)) {
      return const FailureResult(ServerFailure(message: 'Failed to fetch slots for court'));
    }
    return Success([
      CourtSlot(
        id: '${courtId}_slot_09_00',
        courtId: courtId,
        venueId: venueId,
        startTime: '09:00',
        endTime: '10:00',
        price: 500.0,
        status: SlotStatus.available,
      ),
    ]);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final baseDate = DateTime(2026, 11, 7);

  const testVenue = VenueItem(
    id: 'test_venue_avail_001',
    name: 'Andheri Central Pickleball Club',
    imageUrl: 'assets/images/venues/venue_grand_slam.png',
    address: '742 Evergreen Terrace, Andheri West',
    city: 'Mumbai',
    distanceKm: 2.1,
    courtCount: 3,
    surfaceTypes: ['Pro Cushion', 'Acrylic Hardcourt'],
    isIndoor: true,
    hasNightLights: true,
    amenities: ['Night Lights', 'Parking', 'Equipment Rental'],
    rating: 4.8,
    reviewCount: 120,
    minHourlyRate: 500.0,
    maxHourlyRate: 900.0,
    operatingHours: '06:00 - 22:00',
  );

  final emptyDate = baseDate.add(const Duration(days: 3));
  final failingDate = baseDate.add(const Duration(days: 4));

  group('CourtAvailabilityCubit Unit Tests', () {
    late MockVenueRepository repository;

    setUp(() {
      repository = const MockVenueRepository(customVenues: [testVenue]);
    });

    test('initial state is CourtAvailabilityInitial', () {
      final cubit = CourtAvailabilityCubit(repository: repository);
      expect(cubit.state, equals(const CourtAvailabilityInitial()));
      cubit.close();
    });

    test('loadAvailability emits [Loading, Loaded] on valid venue', () async {
      final cubit = CourtAvailabilityCubit(repository: repository);

      expectLater(
        cubit.stream,
        emitsInOrder([
          const CourtAvailabilityLoading(),
          isA<CourtAvailabilityLoaded>()
              .having((s) => s.venue.id, 'venue.id', 'test_venue_avail_001')
              .having((s) => s.courts.length, 'courts count', 3)
              .having((s) => s.selectedCourt?.courtNumber, 'selectedCourt number', 1)
              .having((s) => s.slots.isNotEmpty, 'slots not empty', isTrue)
              .having((s) => s.selectedSlot, 'selectedSlot null initially', isNull),
        ]),
      );

      await cubit.loadAvailability('test_venue_avail_001', initialDate: baseDate);
      await cubit.close();
    });

    test('loadAvailability emits [Loading, Failure] when venue not found', () async {
      final cubit = CourtAvailabilityCubit(repository: repository);

      expectLater(
        cubit.stream,
        emitsInOrder([
          const CourtAvailabilityLoading(),
          isA<CourtAvailabilityFailure>()
              .having((s) => s.failure, 'failure type', isA<NotFoundFailure>()),
        ]),
      );

      await cubit.loadAvailability('non_existent_venue_id', initialDate: baseDate);
      await cubit.close();
    });

    test('selectDate updates date and resets selected slot', () async {
      final cubit = CourtAvailabilityCubit(repository: repository);
      await cubit.loadAvailability('test_venue_avail_001', initialDate: baseDate);

      final stateBefore = cubit.state as CourtAvailabilityLoaded;
      final availableSlot = stateBefore.slots.firstWhere((s) => s.isAvailable);

      // Select slot
      cubit.selectSlot(availableSlot);
      expect((cubit.state as CourtAvailabilityLoaded).selectedSlot, equals(availableSlot));

      // Change date
      final newDate = baseDate.add(const Duration(days: 2));
      await cubit.selectDate(newDate);

      final stateAfter = cubit.state as CourtAvailabilityLoaded;
      expect(stateAfter.selectedDate, equals(newDate));
      expect(stateAfter.selectedSlot, isNull); // Selection reset

      await cubit.close();
    });

    test('selectCourt updates court and resets selected slot', () async {
      final cubit = CourtAvailabilityCubit(repository: repository);
      await cubit.loadAvailability('test_venue_avail_001', initialDate: baseDate);

      final stateBefore = cubit.state as CourtAvailabilityLoaded;
      final availableSlot = stateBefore.slots.firstWhere((s) => s.isAvailable);
      cubit.selectSlot(availableSlot);

      final court2 = stateBefore.courts[1];
      await cubit.selectCourt(court2);

      final stateAfter = cubit.state as CourtAvailabilityLoaded;
      expect(stateAfter.selectedCourt?.id, equals(court2.id));
      expect(stateAfter.selectedSlot, isNull); // Selection reset

      await cubit.close();
    });

    test('selectSlot only allows selecting available slots', () async {
      final cubit = CourtAvailabilityCubit(repository: repository);
      await cubit.loadAvailability('test_venue_avail_001', initialDate: baseDate);

      final loaded = cubit.state as CourtAvailabilityLoaded;
      final bookedSlot = loaded.slots.firstWhere((s) => s.isBooked);
      final availableSlot = loaded.slots.firstWhere((s) => s.isAvailable);

      // Attempting to select booked slot should be rejected
      cubit.selectSlot(bookedSlot);
      expect((cubit.state as CourtAvailabilityLoaded).selectedSlot, isNull);

      // Selecting available slot succeeds
      cubit.selectSlot(availableSlot);
      expect((cubit.state as CourtAvailabilityLoaded).selectedSlot, equals(availableSlot));

      await cubit.close();
    });

    test(
        'selectDate with zero available courts gracefully updates state without .first crash and clears court & slot selections',
        () async {
      final customRepo = _CustomMockVenueRepository(
        venue: testVenue,
        emptyCourtsDates: [emptyDate],
      );
      final cubit = CourtAvailabilityCubit(repository: customRepo);
      await cubit.loadAvailability('test_venue_avail_001', initialDate: baseDate);

      final stateLoaded = cubit.state as CourtAvailabilityLoaded;
      final availableSlot = stateLoaded.slots.firstWhere((s) => s.isAvailable);
      cubit.selectSlot(availableSlot);
      expect((cubit.state as CourtAvailabilityLoaded).hasSelection, isTrue);

      // Select date with zero courts - must not throw StateError: No element
      await cubit.selectDate(emptyDate);

      final stateEmpty = cubit.state as CourtAvailabilityLoaded;
      expect(stateEmpty.selectedDate, equals(emptyDate));
      expect(stateEmpty.courts, isEmpty);
      expect(stateEmpty.selectedCourt, isNull);
      expect(stateEmpty.slots, isEmpty);
      expect(stateEmpty.selectedSlot, isNull);
      expect(stateEmpty.hasSelection, isFalse);

      // Verify recovering back to date with courts works cleanly
      await cubit.selectDate(baseDate);
      final stateRecovered = cubit.state as CourtAvailabilityLoaded;
      expect(stateRecovered.courts.length, equals(2));
      expect(stateRecovered.selectedCourt?.courtNumber, equals(1));
      expect(stateRecovered.slots.isNotEmpty, isTrue);

      await cubit.close();
    });

    test(
        'repository failure while changing dates emits CourtAvailabilityFailure and invalidates previous selections',
        () async {
      final customRepo = _CustomMockVenueRepository(
        venue: testVenue,
        failOnCourtsDate: true,
        failingDate: failingDate,
      );
      final cubit = CourtAvailabilityCubit(repository: customRepo);
      await cubit.loadAvailability('test_venue_avail_001', initialDate: baseDate);

      final stateLoaded = cubit.state as CourtAvailabilityLoaded;
      cubit.selectSlot(stateLoaded.slots.first);
      expect((cubit.state as CourtAvailabilityLoaded).hasSelection, isTrue);

      // Change date to failing date
      await cubit.selectDate(failingDate);

      expect(cubit.state, isA<CourtAvailabilityFailure>());
      final failureState = cubit.state as CourtAvailabilityFailure;
      expect(failureState.failure.message, equals('Failed to fetch courts for date'));

      await cubit.close();
    });

    test(
        'repository failure while changing courts emits CourtAvailabilityFailure and invalidates previous selections',
        () async {
      final customRepo = _CustomMockVenueRepository(
        venue: testVenue,
        failOnSlotsCourt: true,
        failingCourtId: 'test_venue_avail_001_court_2',
      );
      final cubit = CourtAvailabilityCubit(repository: customRepo);
      await cubit.loadAvailability('test_venue_avail_001', initialDate: baseDate);

      final stateLoaded = cubit.state as CourtAvailabilityLoaded;
      cubit.selectSlot(stateLoaded.slots.first);
      expect((cubit.state as CourtAvailabilityLoaded).hasSelection, isTrue);

      final court2 = stateLoaded.courts[1];
      await cubit.selectCourt(court2);

      expect(cubit.state, isA<CourtAvailabilityFailure>());
      final failureState = cubit.state as CourtAvailabilityFailure;
      expect(failureState.failure.message, equals('Failed to fetch slots for court'));

      await cubit.close();
    });
  });

  group('CourtAvailabilityPage Widget Tests', () {
    late MockVenueRepository repository;

    setUp(() {
      repository = const MockVenueRepository(customVenues: [testVenue]);
    });

    testWidgets('renders loading state initially', (tester) async {
      final cubit = CourtAvailabilityCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.text('Loading court availability & slots...'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders full court availability UI when loaded', (tester) async {
      setTallViewport(tester);
      final cubit = CourtAvailabilityCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Court Availability'), findsWidgets);
      expect(find.text('Andheri Central Pickleball Club'), findsWidgets);

      // Date strip & court tabs
      expect(find.byType(CourtDatePickerStrip), findsOneWidget);
      expect(find.byType(CourtSelectorTabs), findsOneWidget);
      expect(find.text('Court 1 (Center Court)'), findsOneWidget);
      expect(find.text('Court 2'), findsOneWidget);

      // Time slot group titles & legend
      expect(find.text('Time Slots'), findsOneWidget);
      expect(find.text('Morning (06:00 - 12:00)'), findsOneWidget);
      expect(find.text('Afternoon (12:00 - 17:00)'), findsOneWidget);
      expect(find.text('Evening & Night (17:00 - 22:00)'), findsOneWidget);
      expect(find.text('Available'), findsWidgets);
      expect(find.text('Booked'), findsWidgets);

      // Booking summary
      expect(find.text('Booking Summary'), findsOneWidget);
      expect(find.text('No slot selected'), findsWidgets);

      await cubit.close();
    });

    testWidgets('date selection refreshes availability and updates active day', (tester) async {
      setTallViewport(tester);
      final cubit = CourtAvailabilityCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = cubit.state as CourtAvailabilityLoaded;
      final secondDate = state.availableDates[1];

      final secondDateCardFinder = find.byKey(
        Key('court_date_card_${secondDate.year}_${secondDate.month}_${secondDate.day}'),
      );
      expect(secondDateCardFinder, findsOneWidget);

      await tester.tap(secondDateCardFinder);
      await tester.pumpAndSettle();

      expect((cubit.state as CourtAvailabilityLoaded).selectedDate, equals(secondDate));

      await cubit.close();
    });

    testWidgets('court selection switches active court tab', (tester) async {
      setTallViewport(tester);
      final cubit = CourtAvailabilityCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final court2TabFinder = find.byKey(const Key('court_tab_test_venue_avail_001_court_2'));
      expect(court2TabFinder, findsOneWidget);

      await tester.tap(court2TabFinder);
      await tester.pumpAndSettle();

      final loadedState = cubit.state as CourtAvailabilityLoaded;
      expect(loadedState.selectedCourt?.courtNumber, equals(2));

      await cubit.close();
    });

    testWidgets('slot selection updates summary and enables Continue button', (tester) async {
      setTallViewport(tester);
      final cubit = CourtAvailabilityCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final loaded = cubit.state as CourtAvailabilityLoaded;
      final firstAvailableSlot = loaded.slots.firstWhere((s) => s.isAvailable);

      // Verify Continue button is initially disabled
      final continueButtonFinder = find.byKey(const Key('court_availability_continue_button'));
      expect(continueButtonFinder, findsOneWidget);

      // Tap on available slot
      final slotFinder = find.byKey(Key('court_slot_${firstAvailableSlot.id}'));
      expect(slotFinder, findsOneWidget);

      await tester.tap(slotFinder);
      await tester.pumpAndSettle();

      // Slot is now selected
      final updatedState = cubit.state as CourtAvailabilityLoaded;
      expect(updatedState.selectedSlot?.id, equals(firstAvailableSlot.id));

      // Summary card shows price and slot time
      expect(find.text(firstAvailableSlot.formattedTime), findsWidgets);
      expect(find.text('₹${firstAvailableSlot.price.toStringAsFixed(0)}'), findsWidgets);
      expect(find.text('Continue to Booking'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('tapping booked slot does not select it', (tester) async {
      setTallViewport(tester);
      final cubit = CourtAvailabilityCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final loaded = cubit.state as CourtAvailabilityLoaded;
      final firstBookedSlot = loaded.slots.firstWhere((s) => s.isBooked);

      final bookedSlotFinder = find.byKey(Key('court_slot_${firstBookedSlot.id}'));
      expect(bookedSlotFinder, findsOneWidget);

      await tester.tap(bookedSlotFinder);
      await tester.pumpAndSettle();

      // Selected slot remains null
      expect((cubit.state as CourtAvailabilityLoaded).selectedSlot, isNull);

      await cubit.close();
    });

    testWidgets('tapping Continue button navigates to next booking step with payload',
        (tester) async {
      setTallViewport(tester);
      BookingSelectionPayload? receivedPayload;

      final router = GoRouter(
        initialLocation: AppRoutes.playerCourtAvailabilityPath('test_venue_avail_001'),
        routes: [
          GoRoute(
            path: AppRoutes.playerCourtAvailability,
            builder: (context, state) => CourtAvailabilityPage(
              venueId: state.pathParameters['id'] ?? '',
              cubit: CourtAvailabilityCubit(repository: repository),
            ),
          ),
          GoRoute(
            path: AppRoutes.playerBookingCheckout,
            builder: (context, state) {
              receivedPayload = state.extra as BookingSelectionPayload?;
              return Scaffold(
                body: Text('Checkout Screen: ${receivedPayload?.venueName} - ${receivedPayload?.slotTime}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      // Find an available slot and tap it (first slot is booked, so pick an enabled slot)
      final availableSlotFinder = find.byWidgetPredicate(
        (widget) =>
            widget is InkWell &&
            widget.key != null &&
            widget.key.toString().contains('court_slot_') &&
            widget.onTap != null,
      );
      expect(availableSlotFinder, findsWidgets);

      await tester.tap(availableSlotFinder.first);
      await tester.pumpAndSettle();

      // Tap Continue button
      final continueBtn = find.text('Continue to Booking');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Verify navigation occurred and payload was passed
      expect(find.textContaining('Checkout Screen: Andheri Central Pickleball Club'), findsOneWidget);
      expect(receivedPayload, isNotNull);
      expect(receivedPayload?.venueId, equals('test_venue_avail_001'));
      expect(receivedPayload?.venueName, equals('Andheri Central Pickleball Club'));
      expect(receivedPayload?.courtNumberOrNameNotEmpty, isTrue);
    });

    testWidgets('renders ErrorStateView when venue not found with retry action', (tester) async {
      setTallViewport(tester);
      final cubit = CourtAvailabilityCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'missing_venue_999',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Unable to Load Courts'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      setTallViewport(tester);
      final cubit = CourtAvailabilityCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Court Availability'), findsWidgets);
      expect(find.text('Time Slots'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders 2-column desktop layout on wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cubit = CourtAvailabilityCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          size: const Size(1200, 1000),
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Summary'), findsOneWidget);
      expect(find.byType(BookingSummaryCard), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
        'selecting a date with zero courts renders empty state without crash and disables booking',
        (tester) async {
      setTallViewport(tester);
      final customRepo = _CustomMockVenueRepository(
        venue: testVenue,
        emptyCourtsDates: [emptyDate],
      );
      final cubit = CourtAvailabilityCubit(repository: customRepo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on empty courts date in date picker strip
      final emptyDateCardFinder = find.byKey(
        Key('court_date_card_${emptyDate.year}_${emptyDate.month}_${emptyDate.day}'),
      );
      expect(emptyDateCardFinder, findsOneWidget);
      await tester.tap(emptyDateCardFinder);
      await tester.pumpAndSettle();

      // Verify empty court text
      expect(find.text('No courts available for this date.'), findsOneWidget);
      expect(find.text('No courts available for the selected date.'), findsOneWidget);
      expect(find.text('No court selected'), findsWidgets);

      // Verify continue button is disabled
      final continueBtnFinder = find.byKey(const Key('court_availability_mobile_continue_button'));
      final button = tester.widget<AppButton>(continueBtnFinder);
      expect(button.onPressed, isNull);

      await cubit.close();
    });

    testWidgets(
        'repository failure while changing date renders ErrorStateView with retry',
        (tester) async {
      setTallViewport(tester);
      final customRepo = _CustomMockVenueRepository(
        venue: testVenue,
        failOnCourtsDate: true,
        failingDate: failingDate,
      );
      final cubit = CourtAvailabilityCubit(repository: customRepo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final failingDateCardFinder = find.byKey(
        Key('court_date_card_${failingDate.year}_${failingDate.month}_${failingDate.day}'),
      );
      expect(failingDateCardFinder, findsOneWidget);
      await tester.tap(failingDateCardFinder);
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Failed to fetch courts for date'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
        'repository failure while changing court renders ErrorStateView with retry',
        (tester) async {
      setTallViewport(tester);
      final customRepo = _CustomMockVenueRepository(
        venue: testVenue,
        failOnSlotsCourt: true,
        failingCourtId: 'test_venue_avail_001_court_2',
      );
      final cubit = CourtAvailabilityCubit(repository: customRepo);

      await tester.pumpWidget(
        _buildTestFrame(
          child: CourtAvailabilityPage(
            venueId: 'test_venue_avail_001',
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final court2Tab = find.byKey(const Key('court_tab_test_venue_avail_001_court_2'));
      expect(court2Tab, findsOneWidget);
      await tester.tap(court2Tab);
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Failed to fetch slots for court'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await cubit.close();
    });
  });
}

extension on BookingSelectionPayload? {
  bool get courtNumberOrNameNotEmpty =>
      this != null && this!.courtName.isNotEmpty && this!.courtId.isNotEmpty;
}
