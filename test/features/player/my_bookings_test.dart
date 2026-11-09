import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_booking_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/court_booking.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_details_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_bookings_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_bookings_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/booking_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/my_bookings_page.dart';

void setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void setWideViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 7, 0);
  final inThreeDays = DateTime(now.year, now.month, now.day + 3, 18, 0);
  final fiveDaysAgo = DateTime(now.year, now.month, now.day - 5, 19, 0);
  final twoWeeksAgo = DateTime(now.year, now.month, now.day - 14, 10, 0);

  final sampleUpcomingConfirmed = CourtBooking(
    id: 'bkg_test_001',
    bookingReference: 'PKL-BKG-20261110-0001',
    venueId: 'org_venue_001',
    venueName: 'Grand Slam Pickleball Arena',
    venueAddress: '742 Evergreen Terrace, Andheri West',
    venueCity: 'Mumbai',
    courtId: 'court_org_venue_001_1',
    courtName: 'Court 1 (Championship Cushioned)',
    surfaceType: 'Pro Cushion',
    date: tomorrow,
    slotId: 'slot_001',
    slotTime: '07:00 - 08:00',
    startTime: '07:00',
    endTime: '08:00',
    durationMinutes: 60,
    courtFee: 700.0,
    platformFee: 0.0,
    taxes: 0.0,
    totalAmount: 700.0,
    status: BookingStatus.confirmed,
    paymentMethod: 'Pay at Venue (Offline)',
    playerId: 'user_player_001',
    playerName: 'Alex Rivera',
    createdAt: now.subtract(const Duration(days: 1)),
  );

  final sampleUpcomingPending = CourtBooking(
    id: 'bkg_test_002',
    bookingReference: 'PKL-BKG-20261112-0002',
    venueId: 'org_venue_002',
    venueName: 'Pinnacle Sports Complex',
    venueAddress: 'Plot 15, BKC Bandra East',
    venueCity: 'Mumbai',
    courtId: 'court_org_venue_002_2',
    courtName: 'Court 2 (South Court)',
    surfaceType: 'Synthetic Acrylic',
    date: inThreeDays,
    slotId: 'slot_002',
    slotTime: '18:00 - 19:00',
    startTime: '18:00',
    endTime: '19:00',
    durationMinutes: 60,
    courtFee: 850.0,
    platformFee: 0.0,
    taxes: 0.0,
    totalAmount: 850.0,
    status: BookingStatus.paymentPending,
    paymentMethod: 'Pay at Venue (Offline)',
    playerId: 'user_player_001',
    playerName: 'Alex Rivera',
    createdAt: now.subtract(const Duration(hours: 6)),
  );

  final samplePast = CourtBooking(
    id: 'bkg_test_003',
    bookingReference: 'PKL-BKG-20261104-0003',
    venueId: 'org_venue_003',
    venueName: 'Dink & Smash Pickleball Club',
    venueAddress: 'Powai Central Road',
    venueCity: 'Mumbai',
    courtId: 'court_org_venue_003_1',
    courtName: 'Court 1 (Main Court)',
    surfaceType: 'Pro Cushion',
    date: fiveDaysAgo,
    slotId: 'slot_003',
    slotTime: '19:00 - 20:00',
    startTime: '19:00',
    endTime: '20:00',
    durationMinutes: 60,
    courtFee: 600.0,
    platformFee: 0.0,
    taxes: 0.0,
    totalAmount: 600.0,
    status: BookingStatus.completed,
    paymentMethod: 'Pay at Venue (Offline)',
    playerId: 'user_player_001',
    playerName: 'Alex Rivera',
    createdAt: now.subtract(const Duration(days: 6)),
  );

  final sampleCancelled = CourtBooking(
    id: 'bkg_test_004',
    bookingReference: 'PKL-BKG-20261026-0004',
    venueId: 'org_venue_004',
    venueName: 'Metro Pickleball Hub',
    venueAddress: 'Goregaon East Highway',
    venueCity: 'Mumbai',
    courtId: 'court_org_venue_004_3',
    courtName: 'Court 3',
    surfaceType: 'Polyurethane Cushioned',
    date: twoWeeksAgo,
    slotId: 'slot_004',
    slotTime: '10:00 - 11:00',
    startTime: '10:00',
    endTime: '11:00',
    durationMinutes: 60,
    courtFee: 550.0,
    platformFee: 0.0,
    taxes: 0.0,
    totalAmount: 550.0,
    status: BookingStatus.cancelled,
    paymentMethod: 'Pay at Venue (Offline)',
    playerId: 'user_player_001',
    playerName: 'Alex Rivera',
    createdAt: now.subtract(const Duration(days: 16)),
  );

  final allTestBookings = [
    sampleUpcomingConfirmed,
    sampleUpcomingPending,
    samplePast,
    sampleCancelled,
  ];

  group('MockBookingRepository Unit Tests (Feature 2.3)', () {
    test('withDefaultBookings seeds realistic mock bookings', () async {
      final repo = MockBookingRepository.withDefaultBookings();
      final result = await repo.getBookings();

      expect(result, isA<Success<List<CourtBooking>>>());
      final bookings = (result as Success<List<CourtBooking>>).data;
      expect(bookings.length, equals(4));
    });

    test('cancelBooking updates booking status to cancelled', () async {
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);
      final result = await repo.cancelBooking(sampleUpcomingConfirmed.id);

      expect(result, isA<Success<CourtBooking>>());
      final updated = (result as Success<CourtBooking>).data;
      expect(updated.status, equals(BookingStatus.cancelled));

      // Verify in repository
      final fetch = await repo.getBookingById(sampleUpcomingConfirmed.id);
      expect((fetch as Success<CourtBooking>).data.status, equals(BookingStatus.cancelled));
    });

    test('cancelBooking returns NotFoundFailure when booking does not exist', () async {
      final repo = MockBookingRepository(initialBookings: []);
      final result = await repo.cancelBooking('unknown_id');

      expect(result, isA<FailureResult<CourtBooking>>());
      final failure = (result as FailureResult<CourtBooking>).failure;
      expect(failure, isA<NotFoundFailure>());
    });

    test('cancelBooking returns ServerFailure when shouldFail is true', () async {
      final repo = MockBookingRepository(
        shouldFail: true,
        initialBookings: [sampleUpcomingConfirmed],
      );
      final result = await repo.cancelBooking(sampleUpcomingConfirmed.id);

      expect(result, isA<FailureResult<CourtBooking>>());
      final failure = (result as FailureResult<CourtBooking>).failure;
      expect(failure, isA<ServerFailure>());
    });
  });

  group('MyBookingsCubit Unit Tests', () {
    test('initial state is MyBookingsInitial', () {
      final cubit = MyBookingsCubit(
        repository: MockBookingRepository(initialBookings: []),
      );
      expect(cubit.state, isA<MyBookingsInitial>());
    });

    test('loadBookings emits [MyBookingsLoading, MyBookingsLoaded] with categorized bookings', () async {
      final repo = MockBookingRepository(initialBookings: allTestBookings);
      final cubit = MyBookingsCubit(repository: repo);

      await cubit.loadBookings();

      expect(cubit.state, isA<MyBookingsLoaded>());
      final loaded = cubit.state as MyBookingsLoaded;
      expect(loaded.upcomingCount, equals(2));
      expect(loaded.pastCount, equals(1));
      expect(loaded.cancelledCount, equals(1));
      expect(loaded.activeFilter, equals(BookingFilter.upcoming));
      expect(loaded.filteredBookings.length, equals(2));
    });

    test('setFilter updates active filter', () async {
      final repo = MockBookingRepository(initialBookings: allTestBookings);
      final cubit = MyBookingsCubit(repository: repo);

      await cubit.loadBookings();
      cubit.setFilter(BookingFilter.past);

      final loaded = cubit.state as MyBookingsLoaded;
      expect(loaded.activeFilter, equals(BookingFilter.past));
      expect(loaded.filteredBookings.length, equals(1));
      expect(loaded.filteredBookings.first.id, equals(samplePast.id));
    });

    test('cancelBooking marks item as cancelled and sets feedback message', () async {
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);
      final cubit = MyBookingsCubit(repository: repo);

      await cubit.loadBookings();
      final success = await cubit.cancelBooking(sampleUpcomingConfirmed.id);

      expect(success, isTrue);
      final loaded = cubit.state as MyBookingsLoaded;
      expect(loaded.upcomingCount, equals(0));
      expect(loaded.cancelledCount, equals(1));
      expect(loaded.feedbackMessage, contains('cancelled'));
    });

    test('loadBookings emits MyBookingsFailure when repository fails', () async {
      final repo = MockBookingRepository(shouldFail: true);
      final cubit = MyBookingsCubit(repository: repo);

      await cubit.loadBookings();

      expect(cubit.state, isA<MyBookingsFailure>());
      final failure = cubit.state as MyBookingsFailure;
      expect(failure.message, contains('Unable to load bookings'));
    });
  });

  group('BookingDetailsCubit Unit Tests', () {
    test('loadBooking emits [Loading, Loaded] when booking found', () async {
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);
      final cubit = BookingDetailsCubit(repository: repo);

      await cubit.loadBooking(sampleUpcomingConfirmed.id);

      expect(cubit.state, isA<BookingDetailsLoaded>());
      final loaded = cubit.state as BookingDetailsLoaded;
      expect(loaded.booking.bookingReference, equals(sampleUpcomingConfirmed.bookingReference));
    });

    test('loadBooking with initialBooking immediately populates state without loading spinner', () async {
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);
      final cubit = BookingDetailsCubit(repository: repo);

      await cubit.loadBooking(
        sampleUpcomingConfirmed.id,
        initialBooking: sampleUpcomingConfirmed,
      );

      expect(cubit.state, isA<BookingDetailsLoaded>());
    });

    test('cancelBooking updates status to cancelled', () async {
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);
      final cubit = BookingDetailsCubit(repository: repo);

      await cubit.loadBooking(sampleUpcomingConfirmed.id);
      final success = await cubit.cancelBooking(sampleUpcomingConfirmed.id);

      expect(success, isTrue);
      final loaded = cubit.state as BookingDetailsLoaded;
      expect(loaded.booking.status, equals(BookingStatus.cancelled));
      expect(loaded.feedbackMessage, contains('cancelled'));
    });

    test('loadBooking emits Failure when booking is not found', () async {
      final repo = MockBookingRepository(initialBookings: []);
      final cubit = BookingDetailsCubit(repository: repo);

      await cubit.loadBooking('non_existent');

      expect(cubit.state, isA<BookingDetailsFailure>());
    });
  });

  group('MyBookingsPage Widget Tests', () {
    testWidgets('renders page heading, tabs with counts, and upcoming booking cards', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: allTestBookings);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MyBookingsPage(cubit: MyBookingsCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Heading
      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.text('Court Bookings & History'), findsOneWidget);

      // Tabs
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Past'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);

      // Default upcoming cards
      expect(find.text('Grand Slam Pickleball Arena'), findsOneWidget);
      expect(find.text('Pinnacle Sports Complex'), findsOneWidget);
      expect(find.text('PKL-BKG-20261110-0001'), findsOneWidget);
      expect(find.text('PKL-BKG-20261112-0002'), findsOneWidget);
    });

    testWidgets('switching to Past tab displays past bookings and hides upcoming', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: allTestBookings);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MyBookingsPage(cubit: MyBookingsCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Past' tab
      await tester.tap(find.byKey(const Key('filter_tab_past')));
      await tester.pumpAndSettle();

      // Past booking visible
      expect(find.text('Dink & Smash Pickleball Club'), findsOneWidget);
      expect(find.text('PKL-BKG-20261104-0003'), findsOneWidget);

      // Upcoming hidden
      expect(find.text('Grand Slam Pickleball Arena'), findsNothing);
    });

    testWidgets('switching to Cancelled tab displays cancelled bookings', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: allTestBookings);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MyBookingsPage(cubit: MyBookingsCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Cancelled' tab
      await tester.tap(find.byKey(const Key('filter_tab_cancelled')));
      await tester.pumpAndSettle();

      // Cancelled booking visible
      expect(find.text('Metro Pickleball Hub'), findsOneWidget);
      expect(find.text('PKL-BKG-20261026-0004'), findsOneWidget);

      // Past and upcoming hidden
      expect(find.text('Dink & Smash Pickleball Club'), findsNothing);
    });

    testWidgets('renders empty state when category has no bookings', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: []);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MyBookingsPage(cubit: MyBookingsCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Upcoming Bookings'), findsOneWidget);
      expect(find.byKey(const Key('empty_state_action_button')), findsOneWidget);
    });

    testWidgets('tapping Cancel button on card opens confirmation dialog', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MyBookingsPage(cubit: MyBookingsCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      final cancelButton = find.byKey(Key('cancel_booking_${sampleUpcomingConfirmed.id}'));
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Confirmation dialog should be presented
      expect(find.text('Cancel Booking'), findsWidgets);
      expect(find.textContaining('This action cannot be undone'), findsOneWidget);

      // Tap 'Cancel Booking' confirm action
      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Booking'));
      await tester.pumpAndSettle();

      // Card is now gone from upcoming tab (it is cancelled)
      expect(find.text('Grand Slam Pickleball Arena'), findsNothing);
      expect(find.text('No Upcoming Bookings'), findsOneWidget);
    });

    testWidgets('tapping View Details navigates to booking details route', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: AppRoutes.playerBookings,
        routes: [
          GoRoute(
            path: AppRoutes.playerBookings,
            builder: (_, _) => MyBookingsPage(cubit: MyBookingsCubit(repository: repo)),
          ),
          GoRoute(
            path: AppRoutes.playerBookingDetails,
            builder: (context, state) {
              navigatedRoute = state.uri.toString();
              return const Scaffold(body: Text('Booking Details Destination'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final detailsBtn = find.byKey(Key('view_details_${sampleUpcomingConfirmed.id}'));
      expect(detailsBtn, findsOneWidget);

      await tester.tap(detailsBtn);
      await tester.pumpAndSettle();

      expect(navigatedRoute, equals('/player/bookings/${sampleUpcomingConfirmed.id}'));
      expect(find.text('Booking Details Destination'), findsOneWidget);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: allTestBookings);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: MyBookingsPage(cubit: MyBookingsCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Court Bookings & History'), findsOneWidget);
    });

    testWidgets('renders cleanly on wide desktop viewport', (tester) async {
      setWideViewport(tester);
      final repo = MockBookingRepository(initialBookings: allTestBookings);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MyBookingsPage(cubit: MyBookingsCubit(repository: repo)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Court Bookings & History'), findsOneWidget);
    });
  });

  group('BookingDetailsPage Widget Tests', () {
    testWidgets('renders complete reservation details', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BookingDetailsPage(
            bookingId: sampleUpcomingConfirmed.id,
            cubit: BookingDetailsCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Reference
      expect(find.text('PKL-BKG-20261110-0001'), findsOneWidget);
      expect(find.byKey(const Key('copy_reference_button')), findsOneWidget);

      // Venue & Court
      expect(find.text('Grand Slam Pickleball Arena'), findsOneWidget);
      expect(find.text('Court 1 (Championship Cushioned)'), findsOneWidget);
      expect(find.text('Pro Cushion'), findsOneWidget);

      // Pricing & Payment
      expect(find.text('Total Payable Amount'), findsOneWidget);
      expect(find.text('₹700'), findsWidgets);
      expect(find.text('Pay at Venue (Offline)'), findsOneWidget);

      // Cancel button present for active upcoming booking
      expect(find.byKey(const Key('details_cancel_booking_button')), findsOneWidget);
    });

    testWidgets('tapping cancel on details screen triggers confirmation dialog', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BookingDetailsPage(
            bookingId: sampleUpcomingConfirmed.id,
            cubit: BookingDetailsCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('details_cancel_booking_button')));
      await tester.pumpAndSettle();

      expect(find.text('Cancel Booking'), findsWidgets);
      expect(find.textContaining('This action cannot be undone'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Cancel Booking'));
      await tester.pumpAndSettle();

      // Status updated to Cancelled
      expect(find.text('Cancelled'), findsWidgets);
      expect(find.text('Cancellation Note'), findsOneWidget);
      expect(find.byKey(const Key('details_cancel_booking_button')), findsNothing);
    });

    testWidgets('renders ErrorStateView when booking is not found', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: []);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: BookingDetailsPage(
            bookingId: 'invalid_id',
            cubit: BookingDetailsCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Not Found'), findsOneWidget);
      expect(find.byType(ErrorStateView), findsOneWidget);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      setTallViewport(tester);
      final repo = MockBookingRepository(initialBookings: [sampleUpcomingConfirmed]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: BookingDetailsPage(
            bookingId: sampleUpcomingConfirmed.id,
            cubit: BookingDetailsCubit(repository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Grand Slam Pickleball Arena'), findsOneWidget);
    });
  });
}
