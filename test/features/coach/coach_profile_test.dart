import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_coach_profile_repository.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_profile.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_profile_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_profile_state.dart';
import 'package:pickleball_platform/features/coach/presentation/pages/coach_profile_page.dart';
import 'package:pickleball_platform/features/profile/presentation/widgets/avatar_picker_dialog.dart';

Widget _buildTestFrame({
  required Widget child,
  ThemeMode mode = ThemeMode.light,
  Size size = const Size(800, 1800),
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

void _setViewport(WidgetTester tester, [Size size = const Size(800, 2200)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoachProfileCubit Unit Tests', () {
    test('initial state is CoachProfileInitial', () {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );
      expect(cubit.state, equals(const CoachProfileInitial()));
      cubit.close();
    });

    test('loadProfile emits [Loading, Loaded] with mock profile', () async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const CoachProfileLoading(),
          isA<CoachProfileLoaded>()
              .having((s) => s.profile.fullName, 'fullName', 'Vikram Malhotra')
              .having((s) => s.profile.certifications.length, 'certs', 2)
              .having((s) => s.profile.services.length, 'services', 2),
        ]),
      );

      await cubit.loadProfile();
      await cubit.close();
    });

    test('loadProfile emits [Loading, Empty] when profile not found', () async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(simulateEmpty: true),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const CoachProfileLoading(),
          isA<CoachProfileEmpty>(),
        ]),
      );

      await cubit.loadProfile();
      await cubit.close();
    });

    test('loadProfile emits [Loading, Failure] on server failure', () async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(shouldFail: true),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const CoachProfileLoading(),
          isA<CoachProfileFailure>()
              .having((s) => s.failure, 'failure', isA<ServerFailure>()),
        ]),
      );

      await cubit.loadProfile();
      await cubit.close();
    });

    test('updatePersonalDetails validates input and updates profile', () async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );
      await cubit.loadProfile();

      final invalidResult = await cubit.updatePersonalDetails(
        fullName: '',
        phone: '+91 98204 51234',
        email: 'vikram@test.com',
        city: 'Mumbai',
        bio: 'Bio',
      );
      expect(invalidResult, isFalse);
      expect(
        (cubit.state as CoachProfileLoaded).isErrorFeedback,
        isTrue,
      );

      final validResult = await cubit.updatePersonalDetails(
        fullName: 'Vikram S. Malhotra',
        phone: '+91 98204 99999',
        email: 'vikram.new@pickleballcoach.in',
        city: 'Pune',
        bio: 'Updated coaching bio.',
      );
      expect(validResult, isTrue);
      final loaded = cubit.state as CoachProfileLoaded;
      expect(loaded.profile.fullName, equals('Vikram S. Malhotra'));
      expect(loaded.profile.city, equals('Pune'));

      await cubit.close();
    });

    test('updateAvatar updates local mock preset and supports clearing',
        () async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );
      await cubit.loadProfile();

      await cubit.updateAvatar('avatar:champion');
      expect(
        (cubit.state as CoachProfileLoaded).profile.avatarUrl,
        equals('avatar:champion'),
      );

      await cubit.updateAvatar(null);
      expect((cubit.state as CoachProfileLoaded).profile.avatarUrl, isNull);

      await cubit.close();
    });

    test('add, update, and remove certifications', () async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );
      await cubit.loadProfile();

      final added = await cubit.addCertification(
        const CoachCertification(
          id: 'cert_custom',
          name: 'USAPA Referee & Rules Specialist',
          issuingBody: 'USA Pickleball',
          yearObtained: '2025',
        ),
      );
      expect(added, isTrue);
      expect(
        (cubit.state as CoachProfileLoaded).profile.certifications.length,
        equals(3),
      );

      final updated = await cubit.updateCertification(
        const CoachCertification(
          id: 'cert_custom',
          name: 'USAPA Rules & Strategy Specialist',
          issuingBody: 'USA Pickleball',
          yearObtained: '2025',
        ),
      );
      expect(updated, isTrue);
      expect(
        (cubit.state as CoachProfileLoaded)
            .profile
            .certifications
            .firstWhere((c) => c.id == 'cert_custom')
            .name,
        equals('USAPA Rules & Strategy Specialist'),
      );

      final removed = await cubit.removeCertification('cert_custom');
      expect(removed, isTrue);
      expect(
        (cubit.state as CoachProfileLoaded).profile.certifications.length,
        equals(2),
      );

      await cubit.close();
    });

    test('manage specializations rejects empty & duplicates', () async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );
      await cubit.loadProfile();

      expect(await cubit.addSpecialization('   '), isFalse);
      expect(
        await cubit.addSpecialization('Third-Shot Drop & Transition'),
        isFalse,
      );

      expect(await cubit.addSpecialization('Footwork Drills'), isTrue);
      expect(
        (cubit.state as CoachProfileLoaded).profile.specializations,
        contains('Footwork Drills'),
      );

      expect(await cubit.removeSpecialization('Footwork Drills'), isTrue);
      expect(
        (cubit.state as CoachProfileLoaded).profile.specializations,
        isNot(contains('Footwork Drills')),
      );

      await cubit.close();
    });

    test('add, update, remove personal services and update fees', () async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );
      await cubit.loadProfile();

      expect(
        await cubit.updateFees(defaultHourlyFee: 0, feeNotes: 'Invalid'),
        isFalse,
      );

      expect(
        await cubit.updateFees(
          defaultHourlyFee: 2200,
          feeNotes: 'Updated personal fee note.',
        ),
        isTrue,
      );
      expect(
        (cubit.state as CoachProfileLoaded).profile.defaultHourlyFee,
        equals(2200),
      );

      expect(
        await cubit.addService(
          const CoachServiceOffering(
            id: 'srv_new',
            name: 'Video Match Review',
            description: 'Detailed stroke and positioning analysis.',
            durationMinutes: 45,
            fee: 1200,
          ),
        ),
        isTrue,
      );
      expect(
        (cubit.state as CoachProfileLoaded).profile.services.length,
        equals(3),
      );

      expect(
        await cubit.updateService(
          const CoachServiceOffering(
            id: 'srv_new',
            name: 'Video Match Breakdown',
            description: 'Updated description.',
            durationMinutes: 60,
            fee: 1500,
          ),
        ),
        isTrue,
      );
      expect(
        (cubit.state as CoachProfileLoaded)
            .profile
            .services
            .firstWhere((s) => s.id == 'srv_new')
            .fee,
        equals(1500),
      );

      expect(await cubit.removeService('srv_new'), isTrue);
      expect(
        (cubit.state as CoachProfileLoaded).profile.services.length,
        equals(2),
      );

      await cubit.close();
    });
  });

  group('CoachProfilePage Widget Tests', () {
    testWidgets('renders LoadingView initially', (tester) async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachProfilePage(cubit: cubit)),
      );

      expect(find.byType(LoadingView), findsOneWidget);
      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets('renders ErrorStateView on failure', (tester) async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(shouldFail: true),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachProfilePage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Failed to load coach profile.'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders EmptyStateView when no profile exists',
        (tester) async {
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(simulateEmpty: true),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachProfilePage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('Coach Profile Unavailable'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders all 7 profile sections without verification workflows',
        (tester) async {
      _setViewport(tester);
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachProfilePage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coach Profile'), findsOneWidget);
      expect(find.text('Vikram Malhotra'), findsOneWidget);
      expect(find.text('Experience'), findsOneWidget);
      expect(find.text('7 Years of Coaching Experience'), findsOneWidget);
      expect(find.text('Certifications'), findsOneWidget);
      expect(
        find.text('IPTPA Level 2 Certified Teaching Pro'),
        findsOneWidget,
      );
      expect(find.text('Specializations'), findsOneWidget);
      expect(find.text('Third-Shot Drop & Transition'), findsOneWidget);
      expect(find.text('Personal Coaching Fees'), findsOneWidget);
      expect(find.text('₹1800 / hour'), findsOneWidget);
      expect(find.text('Coaching Services'), findsOneWidget);
      expect(find.text('1-on-1 Private Technique Clinic'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);
      expect(find.text('Accepting Inquiries'), findsOneWidget);

      // Ensure no credential verification/approval workflow is invented
      expect(find.textContaining('Submit for Verification'), findsNothing);
      expect(find.textContaining('Pending Approval'), findsNothing);

      await cubit.close();
    });

    testWidgets('edits personal details and changes profile photo via local picker',
        (tester) async {
      _setViewport(tester);
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachProfilePage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      // Open Edit Personal Details dialog and validate empty name first
      await tester.tap(find.byKey(const Key('coach_edit_personal_button')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('coach_edit_name_field')),
        '',
      );
      await tester.tap(find.byKey(const Key('coach_save_personal_button')));
      await tester.pumpAndSettle();
      expect(find.text('Name is required'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('coach_edit_name_field')),
        'Vikram Malhotra Pro',
      );
      await tester.enterText(
        find.byKey(const Key('coach_edit_city_field')),
        'Bengaluru',
      );
      await tester.tap(find.byKey(const Key('coach_save_personal_button')));
      await tester.pumpAndSettle();

      expect(find.text('Vikram Malhotra Pro'), findsOneWidget);
      expect(find.text('Bengaluru'), findsOneWidget);

      // Change profile photo using local mock AvatarPickerDialog
      await tester.tap(find.byKey(const Key('coach_change_photo_button')));
      await tester.pumpAndSettle();
      expect(find.byType(AvatarPickerDialog), findsOneWidget);

      await tester.tap(find.text('Champion'));
      await tester.pumpAndSettle();

      expect(
        (cubit.state as CoachProfileLoaded).profile.avatarUrl,
        equals('avatar:champion'),
      );

      await cubit.close();
    });

    testWidgets('adds, edits, and removes certifications with empty state',
        (tester) async {
      _setViewport(tester);
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachProfilePage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      // Add certification
      await tester.tap(find.byKey(const Key('coach_add_certification_button')));
      await tester.pumpAndSettle();

      // Test validation on empty fields
      await tester.tap(find.byKey(const Key('coach_cert_save_button')));
      await tester.pumpAndSettle();
      expect(find.text('Certification name is required'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('coach_cert_name_field')),
        'AIPA National Coach',
      );
      await tester.enterText(
        find.byKey(const Key('coach_cert_issuer_field')),
        'All India Pickleball Association',
      );
      await tester.enterText(
        find.byKey(const Key('coach_cert_year_field')),
        '2025',
      );
      await tester.tap(find.byKey(const Key('coach_cert_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('AIPA National Coach'), findsOneWidget);

      // Delete existing certifications to verify empty state
      await tester.tap(find.byKey(const Key('coach_delete_cert_cert_001')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('coach_delete_cert_cert_002')));
      await tester.pumpAndSettle();

      // Delete the newly added one via its generated key or cubit
      final remainingId =
          (cubit.state as CoachProfileLoaded).profile.certifications.first.id;
      await tester.tap(find.byKey(Key('coach_delete_cert_$remainingId')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coach_certifications_empty')), findsOneWidget);

      await cubit.close();
    });

    testWidgets('manages specializations, services, and personal fees',
        (tester) async {
      _setViewport(tester);
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachProfilePage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      // Add specialization
      await tester.tap(find.byKey(const Key('coach_add_specialization_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('coach_spec_input_field')),
        'Lefty Stacking',
      );
      await tester.tap(find.byKey(const Key('coach_spec_save_button')));
      await tester.pumpAndSettle();
      expect(find.text('Lefty Stacking'), findsOneWidget);

      // Edit fees
      await tester.tap(find.byKey(const Key('coach_edit_fees_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('coach_fee_amount_field')),
        '2500',
      );
      await tester.tap(find.byKey(const Key('coach_fee_save_button')));
      await tester.pumpAndSettle();
      expect(find.text('₹2500 / hour'), findsOneWidget);

      // Add service
      await tester.tap(find.byKey(const Key('coach_add_service_button')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('coach_service_name_field')),
        'Match Play Analysis',
      );
      await tester.enterText(
        find.byKey(const Key('coach_service_desc_field')),
        'Live court strategy coaching.',
      );
      await tester.enterText(
        find.byKey(const Key('coach_service_duration_field')),
        '60',
      );
      await tester.enterText(
        find.byKey(const Key('coach_service_fee_field')),
        '2000',
      );
      await tester.tap(find.byKey(const Key('coach_service_save_button')));
      await tester.pumpAndSettle();

      expect(find.text('Match Play Analysis'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders cleanly in dark mode and wide desktop viewport',
        (tester) async {
      _setViewport(tester, const Size(1280, 1400));
      final cubit = CoachProfileCubit(
        repository: MockCoachProfileRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          size: const Size(1280, 1400),
          child: CoachProfilePage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coach Profile'), findsOneWidget);
      expect(find.text('Personal Coaching Fees'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);

      await cubit.close();
    });
  });
}
