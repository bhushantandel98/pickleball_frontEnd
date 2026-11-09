import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/app/service_locator.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/access/user_role.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/mock/data/mock_data.dart';
import 'package:pickleball_platform/core/network/result.dart';
import 'package:pickleball_platform/features/identity/domain/repositories/user_profile_repository.dart';
import 'package:pickleball_platform/features/player/data/repositories/mock_coaching_academy_repository.dart';
import 'package:pickleball_platform/features/player/domain/entities/coaching_academy_item.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_details_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_discovery_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_enrollment_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/academy_enrollment_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_details_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_details_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_discovery_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_discovery_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_inquiry_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/coach_inquiry_state.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_coaching_requests_cubit.dart';
import 'package:pickleball_platform/features/player/presentation/cubit/my_coaching_requests_state.dart';
import 'package:pickleball_platform/features/player/presentation/pages/academy_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/academy_enrollment_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/coach_details_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/coach_inquiry_page.dart';
import 'package:pickleball_platform/features/player/presentation/pages/player_academy_coach_page.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/academy_batch_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/academy_branch_card.dart';
import 'package:pickleball_platform/features/player/presentation/widgets/coach_card.dart';

void setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUp(() async {
    sl.reset();
    await initServiceLocator();
  });

  tearDown(() {
    sl.reset();
  });

  group('MockCoachingAcademyRepository Unit Tests', () {
    test('getAcademyBranches returns pre-seeded branch listings', () async {
      final repo = MockCoachingAcademyRepository();
      final result = await repo.getAcademyBranches();

      expect(result, isA<Success<List<AcademyBranch>>>());
      final branches = (result as Success<List<AcademyBranch>>).data;
      expect(branches.length, greaterThanOrEqualTo(3));
      expect(branches.any((b) => b.id == 'acad_branch_001'), isTrue);
    });

    test('getAcademyBranches filters by text query and city', () async {
      final repo = MockCoachingAcademyRepository();

      final searchResult = await repo.getAcademyBranches(query: 'Worli');
      final searchBranches = (searchResult as Success<List<AcademyBranch>>).data;
      expect(searchBranches.isNotEmpty, isTrue);
      expect(searchBranches.every((b) => b.branchName.contains('Worli') || b.address.contains('Worli')), isTrue);

      final cityResult = await repo.getAcademyBranches(city: 'Mumbai');
      final cityBranches = (cityResult as Success<List<AcademyBranch>>).data;
      expect(cityBranches.every((b) => b.city == 'Mumbai'), isTrue);
    });

    test('getAcademyBranchById finds branch or returns NotFoundFailure', () async {
      final repo = MockCoachingAcademyRepository();

      final success = await repo.getAcademyBranchById('acad_branch_001');
      expect(success, isA<Success<AcademyBranch>>());
      expect((success as Success<AcademyBranch>).data.branchName, equals('Worli Sea Face Campus'));

      final notFound = await repo.getAcademyBranchById('invalid_branch_id');
      expect(notFound, isA<FailureResult<AcademyBranch>>());
      expect((notFound as FailureResult).failure, isA<NotFoundFailure>());
    });

    test('submitEnrollmentRequest: regular enrollment creates pending approval request', () async {
      final repo = MockCoachingAcademyRepository();

      final result = await repo.submitEnrollmentRequest(
        branchId: 'acad_branch_001',
        programId: 'prog_001',
        batchId: 'batch_001', // Open batch (8/12)
        playerName: 'Jordan Vance',
        playerPhone: '+91 99999 88888',
        emergencyContactName: 'Taylor Vance',
        emergencyContactPhone: '+91 99999 77777',
      );

      expect(result, isA<Success<AcademyEnrollmentRequest>>());
      final req = (result as Success<AcademyEnrollmentRequest>).data;
      expect(req.id, startsWith('ENR-'));
      expect(req.status, equals(AcademyEnrollmentStatus.pendingApproval));
      expect(req.isWaitlist, isFalse);
      expect(req.playerName, equals('Jordan Vance'));
    });

    test('submitEnrollmentRequest: full batch with waitlist enabled creates waitlisted request', () async {
      final repo = MockCoachingAcademyRepository();

      final result = await repo.submitEnrollmentRequest(
        branchId: 'acad_branch_001',
        programId: 'prog_001',
        batchId: 'batch_002', // Full batch (10/10, waitlistEnabled: true)
        playerName: 'Riley Reid',
        playerPhone: '+91 99999 88888',
        emergencyContactName: 'Morgan Reid',
        emergencyContactPhone: '+91 99999 77777',
      );

      expect(result, isA<Success<AcademyEnrollmentRequest>>());
      final req = (result as Success<AcademyEnrollmentRequest>).data;
      expect(req.status, equals(AcademyEnrollmentStatus.waitlisted));
      expect(req.isWaitlist, isTrue);
      expect(req.waitlistPosition, greaterThanOrEqualTo(1));
    });

    test('submitEnrollmentRequest: full batch with waitlist closed is rejected', () async {
      final repo = MockCoachingAcademyRepository();

      final result = await repo.submitEnrollmentRequest(
        branchId: 'acad_branch_002',
        programId: 'prog_003',
        batchId: 'batch_005', // Full batch (8/8, waitlistEnabled: false)
        playerName: 'Casey Stone',
        playerPhone: '+91 99999 88888',
        emergencyContactName: 'Pat Stone',
        emergencyContactPhone: '+91 99999 77777',
      );

      expect(result, isA<FailureResult<AcademyEnrollmentRequest>>());
      final failure = (result as FailureResult).failure;
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, contains('waitlist is closed'));
    });

    test('cancelEnrollmentRequest cancels eligible pending request', () async {
      final repo = MockCoachingAcademyRepository();

      final myRequests = (await repo.getMyEnrollmentRequests() as Success<List<AcademyEnrollmentRequest>>).data;
      final pendingReq = myRequests.firstWhere((r) => r.canCancel);

      final cancelResult = await repo.cancelEnrollmentRequest(pendingReq.id);
      expect(cancelResult, isA<Success<AcademyEnrollmentRequest>>());
      final cancelled = (cancelResult as Success<AcademyEnrollmentRequest>).data;
      expect(cancelled.status, equals(AcademyEnrollmentStatus.cancelled));
    });

    test('getCoaches returns coach directory and supports specialization filtering', () async {
      final repo = MockCoachingAcademyRepository();

      final allResult = await repo.getCoaches();
      expect(allResult, isA<Success<List<CoachItem>>>());
      final allCoaches = (allResult as Success<List<CoachItem>>).data;
      expect(allCoaches.length, greaterThanOrEqualTo(4));

      final filteredResult = await repo.getCoaches(specialization: 'DUPR');
      final filtered = (filteredResult as Success<List<CoachItem>>).data;
      expect(filtered.isNotEmpty, isTrue);
      expect(filtered.every((c) => c.specializations.any((s) => s.contains('DUPR'))), isTrue);
    });

    test('submitCoachInquiry creates pending inquiry and cancelCoachInquiry cancels it', () async {
      final repo = MockCoachingAcademyRepository();

      final result = await repo.submitCoachInquiry(
        coachId: 'coach_001',
        serviceId: 'srv_001',
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        preferredDays: 'Tuesdays 8:00 AM',
        trainingGoal: 'Improve speed-up defense',
        message: 'Looking for 1-on-1 coaching',
      );

      expect(result, isA<Success<CoachInquiryRequest>>());
      final inq = (result as Success<CoachInquiryRequest>).data;
      expect(inq.id, startsWith('INQ-'));
      expect(inq.status, equals(CoachInquiryStatus.pendingCoachResponse));
      expect(inq.canCancel, isTrue);

      final cancelRes = await repo.cancelCoachInquiry(inq.id);
      expect(cancelRes, isA<Success<CoachInquiryRequest>>());
      expect((cancelRes as Success<CoachInquiryRequest>).data.status, equals(CoachInquiryStatus.cancelled));
    });

    test('error harness shouldFail returns ServerFailure', () async {
      final failRepo = MockCoachingAcademyRepository(shouldFail: true);
      final result = await failRepo.getAcademyBranches();
      expect(result, isA<FailureResult<List<AcademyBranch>>>());
      expect((result as FailureResult).failure, isA<ServerFailure>());
    });
  });

  group('Feature 2.7 Cubits Unit Tests', () {
    test('AcademyDiscoveryCubit loads branches and updates search/city filters', () async {
      final repo = MockCoachingAcademyRepository();
      final cubit = AcademyDiscoveryCubit(repo);

      await cubit.loadBranches();
      expect(cubit.state, isA<AcademyDiscoveryLoaded>());
      final loaded = cubit.state as AcademyDiscoveryLoaded;
      expect(loaded.branches.isNotEmpty, isTrue);

      cubit.updateSearchQuery('Pinnacle');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((cubit.state as AcademyDiscoveryLoaded).branches.any((b) => b.academyName.contains('Pinnacle')), isTrue);

      cubit.clearFilters();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((cubit.state as AcademyDiscoveryLoaded).searchQuery, isEmpty);
    });

    test('AcademyDetailsCubit loads branch details correctly', () async {
      final repo = MockCoachingAcademyRepository();
      final cubit = AcademyDetailsCubit(repo, branchId: 'acad_branch_001');

      await cubit.loadBranchDetails();
      expect(cubit.state, isA<AcademyDetailsLoaded>());
      final loaded = cubit.state as AcademyDetailsLoaded;
      expect(loaded.branch.id, equals('acad_branch_001'));
      expect(loaded.branch.programs.isNotEmpty, isTrue);
    });

    test('AcademyEnrollmentCubit inits and validates required submission fields', () async {
      final repo = MockCoachingAcademyRepository();
      final cubit = AcademyEnrollmentCubit(repo);

      await cubit.init(
        branchId: 'acad_branch_001',
        programId: 'prog_001',
        batchId: 'batch_001',
      );
      expect(cubit.state, isA<AcademyEnrollmentReady>());

      // Empty name validation
      final failName = await cubit.submitEnrollment(
        playerName: '',
        playerPhone: '+91 99999 88888',
        emergencyContactName: 'Taylor',
        emergencyContactPhone: '+91 99999 77777',
      );
      expect(failName, isFalse);
      expect((cubit.state as AcademyEnrollmentReady).errorMessage, contains('full name'));

      // Valid submission
      final success = await cubit.submitEnrollment(
        playerName: 'Taylor Vance',
        playerPhone: '+91 99999 88888',
        emergencyContactName: 'Jordan Vance',
        emergencyContactPhone: '+91 99999 77777',
      );
      expect(success, isTrue);
      expect(cubit.state, isA<AcademyEnrollmentSuccess>());
    });

    test('CoachDiscoveryCubit loads coaches and toggles specialization filter', () async {
      final repo = MockCoachingAcademyRepository();
      final cubit = CoachDiscoveryCubit(repo);

      await cubit.loadCoaches();
      expect(cubit.state, isA<CoachDiscoveryLoaded>());
      final loaded = cubit.state as CoachDiscoveryLoaded;
      expect(loaded.coaches.isNotEmpty, isTrue);

      cubit.filterBySpecialization('Foundational Stroke Mechanics');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((cubit.state as CoachDiscoveryLoaded).selectedSpecialization, equals('Foundational Stroke Mechanics'));
    });

    test('CoachDetailsCubit loads coach profile and services', () async {
      final repo = MockCoachingAcademyRepository();
      final cubit = CoachDetailsCubit(repo, coachId: 'coach_001');

      await cubit.loadCoachDetails();
      expect(cubit.state, isA<CoachDetailsLoaded>());
      final loaded = cubit.state as CoachDetailsLoaded;
      expect(loaded.coach.id, equals('coach_001'));
      expect(loaded.coach.services.isNotEmpty, isTrue);
    });

    test('CoachInquiryCubit validates inputs and submits inquiry', () async {
      final repo = MockCoachingAcademyRepository();
      final cubit = CoachInquiryCubit(repo);

      await cubit.init(coachId: 'coach_001');
      expect(cubit.state, isA<CoachInquiryReady>());

      final failGoal = await cubit.submitInquiry(
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        preferredDays: 'Mondays',
        trainingGoal: '',
        message: 'Hello Coach',
      );
      expect(failGoal, isFalse);
      expect((cubit.state as CoachInquiryReady).errorMessage, contains('training objective'));

      final success = await cubit.submitInquiry(
        playerName: 'Alex Rivera',
        playerPhone: '+91 98765 43210',
        preferredDays: 'Mondays',
        trainingGoal: 'Reflexes and speed-up defense',
        message: 'Looking for 1-on-1 private lessons.',
      );
      expect(success, isTrue);
      expect(cubit.state, isA<CoachInquirySuccess>());
    });

    test('MyCoachingRequestsCubit loads requests and cancels enrollment and inquiry', () async {
      final repo = MockCoachingAcademyRepository();
      final cubit = MyCoachingRequestsCubit(repo);

      await cubit.loadRequests();
      expect(cubit.state, isA<MyCoachingRequestsLoaded>());
      final loaded = cubit.state as MyCoachingRequestsLoaded;
      expect(loaded.enrollmentRequests.isNotEmpty, isTrue);
      expect(loaded.coachInquiries.isNotEmpty, isTrue);

      final enrollmentId = loaded.enrollmentRequests.first.id;
      await cubit.cancelEnrollment(enrollmentId);
      final afterCancelEnroll = (cubit.state as MyCoachingRequestsLoaded)
          .enrollmentRequests
          .firstWhere((r) => r.id == enrollmentId);
      expect(afterCancelEnroll.status, equals(AcademyEnrollmentStatus.cancelled));

      final inquiryId = loaded.coachInquiries.first.id;
      await cubit.cancelInquiry(inquiryId);
      final afterCancelInquiry = (cubit.state as MyCoachingRequestsLoaded)
          .coachInquiries
          .firstWhere((i) => i.id == inquiryId);
      expect(afterCancelInquiry.status, equals(CoachInquiryStatus.cancelled));
    });
  });

  group('Feature 2.7 Widget Tests', () {
    testWidgets('AcademyBranchCard renders permitted public details only and excludes internal info', (tester) async {
      const branch = AcademyBranch(
        id: 'test_branch',
        academyId: 'test_acad',
        academyName: 'Apex Pickleball Academy',
        branchName: 'Main Campus',
        city: 'Mumbai',
        address: '100 Court Road, Worli',
        operatingHours: 'Mon-Sat: 6:00 AM - 9:00 PM',
        courtCount: 4,
        headCoachName: 'Coach John',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AcademyBranchCard(
              branch: branch,
              onTap: () {},
            ),
          ),
        ),
      );

      // Approved public info
      expect(find.text('Apex Pickleball Academy'), findsOneWidget);
      expect(find.text('Main Campus'), findsOneWidget);
      expect(find.text('Mumbai'), findsOneWidget);
      expect(find.text('100 Court Road, Worli'), findsOneWidget);
      expect(find.text('Mon-Sat: 6:00 AM - 9:00 PM'), findsOneWidget);
      expect(find.text('View Programs & Batches'), findsOneWidget);

      // Excluded internal / unapproved public info
      expect(find.text('4 Courts'), findsNothing);
      expect(find.text('Lead: Coach John'), findsNothing);
      expect(find.text('0 Programs'), findsNothing);
      expect(find.text('1 Program'), findsNothing);
      expect(find.textContaining('₹'), findsNothing);
    });

    testWidgets('CoachCard renders coach details and starting fee', (tester) async {
      const coach = CoachItem(
        id: 'c_test',
        name: 'Coach Marcus',
        title: 'Master Instructor',
        bio: 'Elite coach',
        city: 'Mumbai',
        experienceYears: 6,
        certifications: ['PPR Pro'],
        specializations: ['Third-Shot Drop'],
        availabilitySchedule: 'Weekdays',
        services: [
          CoachService(
            id: 's_1',
            name: 'Private Lesson',
            description: '1-on-1',
            duration: '60 Min',
            fee: 1500.0,
            feeDisplay: '₹1,500 / hr',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: CoachCard(
              coach: coach,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Coach Marcus'), findsOneWidget);
      expect(find.text('Master Instructor'), findsOneWidget);
      expect(find.text('6 Yrs Exp'), findsOneWidget);
      expect(find.text('From ₹1500 / hr'), findsOneWidget);
      expect(find.text('View Profile & Inquire'), findsOneWidget);
    });

    testWidgets('AcademyBatchCard renders schedule, spots and action button', (tester) async {
      const openBatch = AcademyBatch(
        id: 'b_1',
        programId: 'p_1',
        name: 'Morning Intensive Batch',
        schedule: 'Mon, Wed, Fri: 7:00 AM - 8:30 AM',
        maxCapacity: 10,
        enrolledCount: 6,
        instructorName: 'Coach Jane',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: AcademyBatchCard(
              batch: openBatch,
              onEnroll: () {},
            ),
          ),
        ),
      );

      expect(find.text('Morning Intensive Batch'), findsOneWidget);
      expect(find.text('Mon, Wed, Fri: 7:00 AM - 8:30 AM'), findsOneWidget);
      expect(find.text('4 spots left'), findsOneWidget);
      expect(find.text('Request Enrollment'), findsOneWidget);
    });

    testWidgets('PlayerAcademyCoachPage renders 3 tabs and switches cleanly', (tester) async {
      setTallViewport(tester);

      final repo = MockCoachingAcademyRepository();
      final acadCubit = AcademyDiscoveryCubit(repo);
      final coachCubit = CoachDiscoveryCubit(repo);
      final reqCubit = MyCoachingRequestsCubit(repo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: PlayerAcademyCoachPage(
            academyCubit: acadCubit,
            coachCubit: coachCubit,
            requestsCubit: reqCubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Academies & Coaches'), findsOneWidget);
      expect(find.text('Academies'), findsOneWidget);
      expect(find.text('Coaches'), findsOneWidget);
      expect(find.text('My Requests'), findsOneWidget);
      expect(find.byType(AcademyBranchCard), findsWidgets);

      // Switch to Coaches tab
      await tester.tap(find.text('Coaches'));
      await tester.pumpAndSettle();
      expect(find.byType(CoachCard), findsWidgets);

      // Switch to My Requests tab
      await tester.tap(find.text('My Requests'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Academy Enrollments'), findsOneWidget);
      expect(find.textContaining('Coach Inquiries'), findsOneWidget);
    });

    testWidgets('AcademyDetailsPage renders branch overview, programs and batches without unapproved internal details', (tester) async {
      setTallViewport(tester);

      final repo = MockCoachingAcademyRepository();
      final cubit = AcademyDetailsCubit(repo, branchId: 'acad_branch_001');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AcademyDetailsPage(
            branchId: 'acad_branch_001',
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Academy Details'), findsOneWidget);
      expect(find.text('Pinnacle Sports Pickleball Academy'), findsOneWidget);
      expect(find.text('Worli Sea Face Campus'), findsOneWidget);
      expect(find.text('Training Programs & Batches'), findsOneWidget);
      expect(find.byType(AcademyBatchCard), findsWidgets);

      // Verify unapproved internal information is excluded (fees, courts, coach lead tag, phone contacts)
      expect(find.textContaining('Courts'), findsNothing);
      expect(find.textContaining('Lead:'), findsNothing);
      expect(find.textContaining('+91 98200 12345'), findsNothing);
      expect(find.textContaining('₹'), findsNothing);
    });

    testWidgets('AcademyEnrollmentPage leaves fields empty when unauthenticated and enforces emergency contact validation', (tester) async {
      setTallViewport(tester);

      final repo = MockCoachingAcademyRepository();
      final cubit = AcademyEnrollmentCubit(repo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AcademyEnrollmentPage(
            branchId: 'acad_branch_001',
            programId: 'prog_001',
            batchId: 'batch_001',
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Request Academy Enrollment'), findsOneWidget);
      expect(find.text('Applicant Details'), findsOneWidget);
      expect(find.text('Emergency Contact'), findsOneWidget);
      expect(find.text('Submit Enrollment Request'), findsOneWidget);

      // Verify all text fields are initially empty (no hardcoded defaults)
      expect(find.text('Alex Rivera'), findsNothing);
      expect(find.text('+91 98765 43210'), findsNothing);
      expect(find.text('Carlos Rivera'), findsNothing);
      expect(find.text('+91 98765 43211'), findsNothing);

      // Submitting empty form fails on player name
      await tester.tap(find.text('Submit Enrollment Request'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your full name.'), findsOneWidget);

      // Enter player name and phone
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Taylor Vance');
      await tester.enterText(textFields.at(1), '+91 98765 43210');

      // Submitting without emergency contacts fails
      await tester.tap(find.text('Submit Enrollment Request'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter an emergency contact name.'), findsOneWidget);

      // Enter emergency contacts
      await tester.enterText(textFields.at(4), 'Jordan Vance');
      await tester.enterText(textFields.at(5), '+91 98765 43211');

      // Now submission succeeds
      await tester.tap(find.text('Submit Enrollment Request'));
      await tester.pumpAndSettle();

      expect(find.text('Enrollment Request Submitted!'), findsOneWidget);
      expect(find.text('Back to Academies & Coaches'), findsOneWidget);
    });

    testWidgets('AcademyEnrollmentPage pre-fills player profile data when logged in but leaves emergency contacts empty', (tester) async {
      setTallViewport(tester);

      final repo = MockCoachingAcademyRepository();
      final userProfileRepo = sl<UserProfileRepository>();
      final sessionCubit = sl<SessionCubit>();

      // Authenticate as playerUser
      await sessionCubit.signIn(
        userId: MockData.playerUser.id,
        email: MockData.playerUser.email,
        roles: const [UserRole.player],
        activeRole: UserRole.player,
      );

      final cubit = AcademyEnrollmentCubit(
        repo,
        userProfileRepository: userProfileRepo,
        sessionCubit: sessionCubit,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: AcademyEnrollmentPage(
            branchId: 'acad_branch_001',
            programId: 'prog_001',
            batchId: 'batch_001',
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Logged-in profile fields are pre-filled
      expect(find.text(MockData.playerUser.name), findsOneWidget);
      expect(find.text(MockData.playerUser.phone), findsOneWidget);
      expect(find.text(MockData.playerUser.email), findsOneWidget);

      // Emergency contact details are NEVER prefilled with placeholders
      expect(find.text('Carlos Rivera'), findsNothing);
      expect(find.text('+91 98765 43211'), findsNothing);

      // Submitting without entering emergency contact is rejected
      await tester.tap(find.text('Submit Enrollment Request'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter an emergency contact name.'), findsOneWidget);
    });

    testWidgets('CoachDetailsPage renders coach profile, rates, and triggers inquiry navigation', (tester) async {
      setTallViewport(tester);

      final repo = MockCoachingAcademyRepository();
      final cubit = CoachDetailsCubit(repo, coachId: 'coach_001');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CoachDetailsPage(
            coachId: 'coach_001',
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Coach Profile'), findsOneWidget);
      expect(find.text('Coach David Miller'), findsOneWidget);
      expect(find.text('About Coach'), findsOneWidget);
      expect(find.text('Coaching Services & Rates'), findsOneWidget);
      expect(find.text('Send General Coaching Inquiry'), findsOneWidget);
    });

    testWidgets('CoachInquiryPage leaves fields empty when unauthenticated and enforces validation', (tester) async {
      setTallViewport(tester);

      final repo = MockCoachingAcademyRepository();
      final cubit = CoachInquiryCubit(repo);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CoachInquiryPage(
            coachId: 'coach_001',
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Coaching Inquiry'), findsOneWidget);
      expect(find.text('Coach David Miller'), findsOneWidget);
      expect(find.textContaining('Platform Policy'), findsOneWidget);
      expect(find.text('Send Coaching Inquiry'), findsOneWidget);

      // Verify fields are empty initially
      expect(find.text('Alex Rivera'), findsNothing);
      expect(find.text('+91 98765 43210'), findsNothing);
      expect(find.text('Weekday mornings (Tue/Thu 7:00 AM)'), findsNothing);

      // Submitting empty form fails on player name
      await tester.tap(find.text('Send Coaching Inquiry'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter your name.'), findsOneWidget);

      // Enter required fields
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Morgan Reed');
      await tester.enterText(textFields.at(1), '+91 98765 43210');
      await tester.enterText(textFields.at(3), 'Mon & Wed evenings');
      await tester.enterText(textFields.at(5), 'Improve third shot drops');
      await tester.enterText(textFields.at(6), 'Looking for private lessons.');

      await tester.tap(find.text('Send Coaching Inquiry'));
      await tester.pumpAndSettle();

      expect(find.text('Inquiry Sent to Coach!'), findsOneWidget);
      expect(find.text('Back to Academies & Coaches'), findsOneWidget);
    });

    testWidgets('CoachInquiryPage pre-fills applicant details from session profile but leaves inquiry details empty', (tester) async {
      setTallViewport(tester);

      final repo = MockCoachingAcademyRepository();
      final userProfileRepo = sl<UserProfileRepository>();
      final sessionCubit = sl<SessionCubit>();

      // Authenticate as playerUser
      await sessionCubit.signIn(
        userId: MockData.playerUser.id,
        email: MockData.playerUser.email,
        roles: const [UserRole.player],
        activeRole: UserRole.player,
      );

      final cubit = CoachInquiryCubit(
        repo,
        userProfileRepository: userProfileRepo,
        sessionCubit: sessionCubit,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: CoachInquiryPage(
            coachId: 'coach_001',
            cubit: cubit,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Profile details are pre-filled
      expect(find.text(MockData.playerUser.name), findsOneWidget);
      expect(find.text(MockData.playerUser.phone), findsOneWidget);
      expect(find.text(MockData.playerUser.email), findsOneWidget);

      // Inquiry-specific fields are empty (no placeholder strings)
      expect(find.text('Weekday mornings (Tue/Thu 7:00 AM)'), findsNothing);
      expect(find.textContaining('Improve third-shot drop consistency'), findsNothing);

      // Submitting without entering inquiry details fails
      await tester.tap(find.text('Send Coaching Inquiry'));
      await tester.pumpAndSettle();
      expect(find.text('Please indicate your preferred days or times.'), findsOneWidget);
    });
  });
}
