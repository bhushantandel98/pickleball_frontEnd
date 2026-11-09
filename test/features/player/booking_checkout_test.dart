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
import 'package:pickleball_platform/features/player/domain/entities/court_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_checkout_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/booking_checkout_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/booking_checkout_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/booking_confirmation_page.dart';

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

  final testDate = DateTime(2026, 11, 15);

  final validPayload = BookingSelectionPayload(
    venueId: 'test_venue_001',
    venueName: 'Andheri Central Pickleball Club',
    venueAddress: '742 Evergreen Terrace, Andheri West',
    venueCity: 'Mumbai',
    courtId: 'court_001',
    courtName: 'Court 1 (Center Court)',
    surfaceType: 'Pro Cushion',
    date: testDate,
    slotId: 'court_001_slot_06_00',
    slotTime: '06:00 - 07:00',
    price: 600.0,
    durationMinutes: 60,
  );

  final testBooking = CourtBooking(
    id: 'bkg_123456789_1',
    bookingReference: 'PKL-BKG-20261115-0001',
    venueId: 'test_venue_001',
    venueName: 'Andheri Central Pickleball Club',
    venueAddress: '742 Evergreen Terrace, Andheri West',
    venueCity: 'Mumbai',
    courtId: 'court_001',
    courtName: 'Court 1 (Center Court)',
    surfaceType: 'Pro Cushion',
    date: testDate,
    slotId: 'court_001_slot_06_00',
    slotTime: '06:00 - 07:00',
    startTime: '06:00',
    endTime: '07:00',
    durationMinutes: 60,
    courtFee: 600.0,
    platformFee: 0.0,
    taxes: 0.0,
    totalAmount: 600.0,
    status: BookingStatus.confirmed,
    paymentMethod: 'Pay at Venue (Offline)',
    playerId: 'usr_player_001',
    playerName: 'Alex Rivera',
    createdAt: DateTime(2026, 11, 9, 10, 0),
  );

  group('MockBookingRepository Unit Tests', () {
    late MockBookingRepository repository;

    setUp(() {
      repository = MockBookingRepository();
    });

    test('generateBookingReference produces standardized format', () {
      final ref = MockBookingRepository.generateBookingReference(DateTime(2026, 11, 9), 1);
      expect(ref, equals('PKL-BKG-20261109-0001'));

      final ref2 = MockBookingRepository.generateBookingReference(DateTime(2026, 12, 25), 42);
      expect(ref2, equals('PKL-BKG-20261225-0042'));
    });

    test('createBooking successfully creates in-memory booking with correct details', () async {
      final result = await repository.createBooking(
        payload: validPayload,
        playerId: 'player_123',
        playerName: 'John Doe',
      );

      expect(result, isA<Success<CourtBooking>>());
      final booking = (result as Success<CourtBooking>).data;

      expect(booking.bookingReference, startsWith('PKL-BKG-20261115-'));
      expect(booking.venueName, equals('Andheri Central Pickleball Club'));
      expect(booking.courtName, equals('Court 1 (Center Court)'));
      expect(booking.surfaceType, equals('Pro Cushion'));
      expect(booking.slotTime, equals('06:00 - 07:00'));
      expect(booking.startTime, equals('06:00'));
      expect(booking.endTime, equals('07:00'));
      expect(booking.durationMinutes, equals(60));
      expect(booking.courtFee, equals(600.0));
      expect(booking.totalAmount, equals(600.0));
      expect(booking.status, equals(BookingStatus.confirmed));
      expect(booking.paymentMethod, equals('Pay at Venue (Offline)'));
      expect(booking.playerName, equals('John Doe'));

      // Check in list
      final allResult = await repository.getBookings();
      expect((allResult as Success<List<CourtBooking>>).data.length, equals(1));
    });

    test('createBooking returns ValidationFailure when payload is invalid', () async {
      final invalidPayload = BookingSelectionPayload(
        venueId: '',
        venueName: '',
        courtId: '',
        courtName: '',
        surfaceType: '',
        date: testDate,
        slotId: '',
        slotTime: '',
        price: 0,
      );

      final result = await repository.createBooking(payload: invalidPayload);
      expect(result, isA<FailureResult<CourtBooking>>());
      final failure = (result as FailureResult<CourtBooking>).failure;
      expect(failure, isA<ValidationFailure>());
    });

    test('createBooking returns ServerFailure when shouldFail is true', () async {
      final failingRepo = MockBookingRepository(shouldFail: true);
      final result = await failingRepo.createBooking(payload: validPayload);

      expect(result, isA<FailureResult<CourtBooking>>());
      final failure = (result as FailureResult<CourtBooking>).failure;
      expect(failure, isA<ServerFailure>());
    });

    test('getBookingById finds existing booking or returns NotFoundFailure', () async {
      await repository.createBooking(payload: validPayload);
      final all = (await repository.getBookings() as Success<List<CourtBooking>>).data;
      final created = all.first;

      final foundById = await repository.getBookingById(created.id);
      expect(foundById, isA<Success<CourtBooking>>());

      final foundByRef = await repository.getBookingById(created.bookingReference);
      expect(foundByRef, isA<Success<CourtBooking>>());

      final notFound = await repository.getBookingById('non_existent_id');
      expect(notFound, isA<FailureResult<CourtBooking>>());
    });
  });

  group('BookingCheckoutCubit Unit Tests', () {
    late MockBookingRepository repository;

    setUp(() {
      repository = MockBookingRepository();
    });

    test('initial state is BookingCheckoutInitial', () {
      final cubit = BookingCheckoutCubit(repository: repository);
      expect(cubit.state, equals(const BookingCheckoutInitial()));
      cubit.close();
    });

    test('init with null payload emits BookingCheckoutInvalid', () {
      final cubit = BookingCheckoutCubit(repository: repository);
      cubit.init(null);
      expect(cubit.state, isA<BookingCheckoutInvalid>());
      expect(
        (cubit.state as BookingCheckoutInvalid).errorMessage,
        contains('missing'),
      );
      cubit.close();
    });

    test('init with invalid payload emits BookingCheckoutInvalid', () {
      final cubit = BookingCheckoutCubit(repository: repository);
      final invalid = BookingSelectionPayload(
        venueId: '',
        venueName: 'Test Venue',
        courtId: '',
        courtName: 'Court 1',
        surfaceType: 'Hard',
        date: testDate,
        slotId: '',
        slotTime: '06:00 - 07:00',
        price: 0,
      );

      cubit.init(invalid);
      expect(cubit.state, isA<BookingCheckoutInvalid>());
      expect(
        (cubit.state as BookingCheckoutInvalid).errorMessage,
        contains('Incomplete'),
      );
      cubit.close();
    });

    test('init with valid payload emits BookingCheckoutReady with correct amounts', () {
      final cubit = BookingCheckoutCubit(repository: repository);
      cubit.init(validPayload);

      expect(cubit.state, isA<BookingCheckoutReady>());
      final ready = cubit.state as BookingCheckoutReady;
      expect(ready.payload, equals(validPayload));
      expect(ready.courtFee, equals(600.0));
      expect(ready.platformFee, equals(0.0));
      expect(ready.taxes, equals(0.0));
      expect(ready.totalAmount, equals(600.0));
      expect(ready.paymentNotice, contains('Pay at Venue'));

      cubit.close();
    });

    test('confirmBooking emits [Submitting, Success] on valid booking', () async {
      final cubit = BookingCheckoutCubit(repository: repository);
      cubit.init(validPayload);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<BookingCheckoutSubmitting>(),
          isA<BookingCheckoutSuccess>()
              .having((s) => s.booking.venueName, 'venueName', validPayload.venueName)
              .having((s) => s.booking.courtName, 'courtName', validPayload.courtName)
              .having((s) => s.booking.totalAmount, 'totalAmount', 600.0)
              .having((s) => s.booking.bookingReference, 'ref', startsWith('PKL-BKG-')),
        ]),
      );

      await cubit.confirmBooking(playerName: 'Alex Rivera');
      await cubit.close();
    });

    test('confirmBooking emits [Submitting, Failure] when repository fails', () async {
      final failingRepo = MockBookingRepository(shouldFail: true);
      final cubit = BookingCheckoutCubit(repository: failingRepo);
      cubit.init(validPayload);

      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<BookingCheckoutSubmitting>(),
          isA<BookingCheckoutFailure>()
              .having((s) => s.failure.message, 'message', contains('Unable to process')),
        ]),
      );

      await cubit.confirmBooking();
      await cubit.close();
    });
  });

  group('BookingCheckoutPage Widget Tests', () {
    late MockBookingRepository repository;

    setUp(() {
      repository = MockBookingRepository();
    });

    testWidgets('renders correct booking summary details on checkout screen', (tester) async {
      setTallViewport(tester);
      final cubit = BookingCheckoutCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: BookingCheckoutPage(
            payload: validPayload,
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Venue & Location
      expect(find.text('Review Booking'), findsOneWidget);
      expect(find.text('Andheri Central Pickleball Club'), findsWidgets);
      expect(find.textContaining('742 Evergreen Terrace'), findsOneWidget);

      // Court & Slot
      expect(find.text('Court 1 (Center Court)'), findsOneWidget);
      expect(find.text('Pro Cushion'), findsOneWidget);
      expect(find.text('06:00 - 07:00'), findsWidgets);
      expect(find.text('60 min slot'), findsOneWidget);

      // Pricing & Mode
      expect(find.text('₹600'), findsWidgets);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('Offline Venue Payment (V1)'), findsOneWidget);
      expect(find.text('Confirm Booking'), findsWidgets);

      await cubit.close();
    });

    testWidgets('renders ErrorStateView when booking payload is missing or invalid', (tester) async {
      setTallViewport(tester);
      final cubit = BookingCheckoutCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          child: BookingCheckoutPage(
            payload: null,
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Invalid Booking Details'), findsOneWidget);
      expect(find.text('Booking selection details are missing.'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders ErrorStateView when payload fields are incomplete', (tester) async {
      setTallViewport(tester);
      final cubit = BookingCheckoutCubit(repository: repository);
      final invalid = BookingSelectionPayload(
        venueId: '',
        venueName: '',
        courtId: '',
        courtName: '',
        surfaceType: '',
        date: testDate,
        slotId: '',
        slotTime: '',
        price: 0,
      );

      await tester.pumpWidget(
        _buildTestFrame(
          child: BookingCheckoutPage(
            payload: invalid,
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Invalid Booking Details'), findsOneWidget);
      expect(find.text('Incomplete booking information provided.'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('Back / Edit action button triggers pop navigation', (tester) async {
      setTallViewport(tester);
      bool didPop = false;

      final router = GoRouter(
        initialLocation: '/availability',
        routes: [
          GoRoute(
            path: '/availability',
            builder: (_, _) => const Scaffold(body: Text('Availability Screen')),
          ),
          GoRoute(
            path: '/checkout',
            builder: (_, _) => BookingCheckoutPage(
              payload: validPayload,
              cubit: BookingCheckoutCubit(repository: repository),
            ),
          ),
        ],
        observers: [
          _TestNavigatorObserver(onPopped: () => didPop = true),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      router.push('/checkout');
      await tester.pumpAndSettle();

      final backButton = find.byKey(const Key('booking_checkout_mobile_back_button'));
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
      expect(find.text('Availability Screen'), findsOneWidget);
    });

    testWidgets('confirming booking triggers submission and navigates to confirmation', (tester) async {
      setTallViewport(tester);
      CourtBooking? receivedConfirmationBooking;

      final router = GoRouter(
        initialLocation: AppRoutes.playerBookingCheckout,
        routes: [
          GoRoute(
            path: AppRoutes.playerBookingCheckout,
            builder: (context, state) => BookingCheckoutPage(
              payload: validPayload,
              cubit: BookingCheckoutCubit(repository: repository),
            ),
          ),
          GoRoute(
            path: AppRoutes.playerBookingConfirmation,
            builder: (context, state) {
              receivedConfirmationBooking = state.extra as CourtBooking?;
              return Scaffold(
                body: Text(
                  'Confirmation Screen: ${receivedConfirmationBooking?.bookingReference}',
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      // Tap Confirm Booking
      final confirmBtn = find.byKey(const Key('booking_checkout_confirm_button'));
      expect(confirmBtn, findsOneWidget);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify navigated to confirmation screen with generated reference
      expect(find.textContaining('Confirmation Screen: PKL-BKG-'), findsOneWidget);
      expect(receivedConfirmationBooking, isNotNull);
      expect(receivedConfirmationBooking?.venueName, equals('Andheri Central Pickleball Club'));
      expect(receivedConfirmationBooking?.courtName, equals('Court 1 (Center Court)'));
      expect(receivedConfirmationBooking?.totalAmount, equals(600.0));
      expect(receivedConfirmationBooking?.status, equals(BookingStatus.confirmed));
    });

    testWidgets('renders cleanly in 2-column desktop layout on wide viewport', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final cubit = BookingCheckoutCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          size: const Size(1200, 1000),
          child: BookingCheckoutPage(
            payload: validPayload,
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('booking_checkout_desktop_confirm_button')), findsOneWidget);
      expect(find.byKey(const Key('booking_checkout_back_button')), findsOneWidget);
      expect(find.text('Price Breakdown'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      setTallViewport(tester);
      final cubit = BookingCheckoutCubit(repository: repository);

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          child: BookingCheckoutPage(
            payload: validPayload,
            cubit: cubit,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review Booking'), findsOneWidget);
      expect(find.text('Andheri Central Pickleball Club'), findsWidgets);

      await cubit.close();
    });
  });

  group('BookingConfirmationPage Widget Tests', () {
    testWidgets('renders correct confirmed booking details and reference', (tester) async {
      setTallViewport(tester);

      await tester.pumpWidget(
        _buildTestFrame(
          child: BookingConfirmationPage(
            booking: testBooking,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header & Emblem
      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(find.text('Your pickleball court has been reserved successfully.'), findsOneWidget);

      // Booking Reference Box
      expect(find.byKey(const Key('booking_confirmation_reference_card')), findsOneWidget);
      expect(find.text('PKL-BKG-20261115-0001'), findsOneWidget);
      expect(find.text('Pay at Venue (Offline)'), findsWidgets);

      // Reservation Details
      expect(find.byKey(const Key('booking_confirmation_details_card')), findsOneWidget);
      expect(find.text('Andheri Central Pickleball Club'), findsOneWidget);
      expect(find.text('Court 1 (Center Court) (Pro Cushion)'), findsOneWidget);
      expect(find.text('06:00 - 07:00 (60 mins)'), findsOneWidget);
      expect(find.text('₹600'), findsOneWidget);
      expect(find.text('Pending (Pay at Venue Counter)'), findsOneWidget);

      // Action Buttons
      expect(find.byKey(const Key('booking_confirmation_dashboard_button')), findsOneWidget);
      expect(find.byKey(const Key('booking_confirmation_view_details_button')), findsOneWidget);
    });

    testWidgets('renders ErrorStateView when booking is null', (tester) async {
      setTallViewport(tester);

      await tester.pumpWidget(
        _buildTestFrame(
          child: const BookingConfirmationPage(booking: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Booking Details Missing'), findsOneWidget);
      expect(find.text('No active court booking confirmation was found.'), findsOneWidget);
    });

    testWidgets('Back to Dashboard button navigates to player dashboard', (tester) async {
      setTallViewport(tester);
      bool navigatedToDashboard = false;

      final router = GoRouter(
        initialLocation: AppRoutes.playerBookingConfirmation,
        routes: [
          GoRoute(
            path: AppRoutes.playerBookingConfirmation,
            builder: (_, _) => BookingConfirmationPage(booking: testBooking),
          ),
          GoRoute(
            path: AppRoutes.playerDashboard,
            builder: (_, _) {
              navigatedToDashboard = true;
              return const Scaffold(body: Text('Player Dashboard View'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final dashBtn = find.byKey(const Key('booking_confirmation_dashboard_button'));
      expect(dashBtn, findsOneWidget);
      await tester.tap(dashBtn);
      await tester.pumpAndSettle();

      expect(navigatedToDashboard, isTrue);
      expect(find.text('Player Dashboard View'), findsOneWidget);
    });

    testWidgets('View Booking Details button opens details modal dialog', (tester) async {
      setTallViewport(tester);

      await tester.pumpWidget(
        _buildTestFrame(
          child: BookingConfirmationPage(booking: testBooking),
        ),
      );
      await tester.pumpAndSettle();

      final viewDetailsBtn = find.byKey(const Key('booking_confirmation_view_details_button'));
      expect(viewDetailsBtn, findsOneWidget);
      await tester.tap(viewDetailsBtn);
      await tester.pumpAndSettle();

      // Verify dialog is opened
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Booking Details'), findsOneWidget);
      expect(find.text('Alex Rivera'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('renders cleanly in dark theme mode', (tester) async {
      setTallViewport(tester);

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          child: BookingConfirmationPage(booking: testBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(find.text('PKL-BKG-20261115-0001'), findsOneWidget);
    });
  });
}

class _TestNavigatorObserver extends NavigatorObserver {
  final VoidCallback onPopped;
  _TestNavigatorObserver({required this.onPopped});

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    onPopped();
  }
}
