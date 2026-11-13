import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/errors/failures.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/features/coach/data/repositories/mock_coach_dashboard_repository.dart';
import 'package:pickleball_platform/features/coach/domain/entities/coach_dashboard_data.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_dashboard_cubit.dart';
import 'package:pickleball_platform/features/coach/presentation/bloc/coach_dashboard_state.dart';
import 'package:pickleball_platform/features/coach/presentation/pages/coach_dashboard_page.dart';

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

void _setViewport(WidgetTester tester, [Size size = const Size(800, 2000)]) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CoachDashboardCubit Unit Tests', () {
    test('initial state is CoachDashboardInitial', () {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );
      expect(cubit.state, equals(const CoachDashboardInitial()));
      cubit.close();
    });

    test('loadDashboard emits [Loading, Loaded] with valid mock data', () async {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const CoachDashboardLoading(),
          isA<CoachDashboardLoaded>()
              .having((s) => s.data.coachName, 'coachName', 'Vikram Malhotra')
              .having((s) => s.data.acceptedAffiliations.length, 'accepted affiliations', 2)
              .having((s) => s.filteredSessions.length, 'upcoming sessions', 5),
        ]),
      );

      await cubit.loadDashboard();
      await cubit.close();
    });

    test('loadDashboard emits [Loading, Empty] when repository has no data',
        () async {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(simulateEmpty: true),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const CoachDashboardLoading(),
          isA<CoachDashboardEmpty>(),
        ]),
      );

      await cubit.loadDashboard();
      await cubit.close();
    });

    test('loadDashboard emits [Loading, Failure] when repository fails',
        () async {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(shouldFail: true),
      );

      expectLater(
        cubit.stream,
        emitsInOrder([
          const CoachDashboardLoading(),
          isA<CoachDashboardFailure>()
              .having((s) => s.failure, 'failure', isA<ServerFailure>()),
        ]),
      );

      await cubit.loadDashboard();
      await cubit.close();
    });

    test('Personal context filter separates personal data from academy data',
        () async {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );
      await cubit.loadDashboard();

      cubit.selectContextType(CoachContextType.personal);
      final loaded = cubit.state as CoachDashboardLoaded;

      expect(loaded.showPersonalContext, isTrue);
      expect(loaded.showAcademyContext, isFalse);
      expect(
        loaded.filteredSessions
            .every((s) => s.contextType == CoachSessionContext.personal),
        isTrue,
      );
      expect(loaded.filteredSessions.length, equals(2));
      expect(loaded.filteredAcademyPlayerSummaries, isEmpty);
      expect(loaded.filteredAcademyFinanceSummaries, isEmpty);
      expect(
        loaded.filteredPendingTasks
            .every((t) => t.contextType == CoachSessionContext.personal),
        isTrue,
      );

      await cubit.close();
    });

    test('Academy and Branch filtering scopes sessions, players, tasks, and finances',
        () async {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );
      await cubit.loadDashboard();

      cubit.selectAcademy('acad_001');
      var loaded = cubit.state as CoachDashboardLoaded;
      expect(loaded.showPersonalContext, isFalse);
      expect(loaded.showAcademyContext, isTrue);
      expect(loaded.availableBranches.length, equals(2));
      expect(
        loaded.filteredSessions.every((s) => s.academyId == 'acad_001'),
        isTrue,
      );
      expect(loaded.filteredAcademyFinanceSummaries.length, equals(2));

      // Filter further to Bandra West Branch
      cubit.selectBranch('branch_bandra');
      loaded = cubit.state as CoachDashboardLoaded;
      expect(loaded.filteredSessions.length, equals(1));
      expect(loaded.filteredSessions.first.branchId, equals('branch_bandra'));
      expect(loaded.filteredAcademyPlayerSummaries.length, equals(1));
      expect(
        loaded.filteredAcademyPlayerSummaries.first.branchId,
        equals('branch_bandra'),
      );
      expect(loaded.filteredAcademyFinanceSummaries.length, equals(1));
      expect(
        loaded.filteredAcademyFinanceSummaries.first.branchId,
        equals('branch_bandra'),
      );
      expect(loaded.filteredPendingTasks, isEmpty);

      // Attempting to filter by an unaccepted academy does nothing
      cubit.selectAcademy('acad_pending_003');
      expect(
        (cubit.state as CoachDashboardLoaded).filter.selectedAcademyId,
        equals('acad_001'),
      );

      // Clear filters restores All Contexts
      cubit.clearFilters();
      loaded = cubit.state as CoachDashboardLoaded;
      expect(loaded.filter.contextType, equals(CoachContextType.all));
      expect(loaded.filteredSessions.length, equals(5));

      await cubit.close();
    });

    test('refreshDashboard preserves active context filter', () async {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );
      await cubit.loadDashboard();
      cubit.selectContextType(CoachContextType.personal);

      await cubit.refreshDashboard();
      final loaded = cubit.state as CoachDashboardLoaded;
      expect(loaded.filter.contextType, equals(CoachContextType.personal));

      await cubit.close();
    });
  });

  group('CoachDashboardPage Widget Tests', () {
    testWidgets('renders LoadingView initially', (tester) async {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachDashboardPage(cubit: cubit)),
      );

      expect(find.byType(LoadingView), findsOneWidget);
      await tester.pumpAndSettle();
      await cubit.close();
    });

    testWidgets('renders ErrorStateView on failure with retry', (tester) async {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(shouldFail: true),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachDashboardPage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateView), findsOneWidget);
      expect(find.text('Unable to load coach dashboard data.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await cubit.close();
    });

    testWidgets('renders EmptyStateView when dashboard data is empty',
        (tester) async {
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(simulateEmpty: true),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachDashboardPage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No Coach Activity Yet'), findsOneWidget);

      await cubit.close();
    });

    testWidgets(
        'renders upcoming sessions, pending tasks, separated player and finance summaries',
        (tester) async {
      _setViewport(tester);
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachDashboardPage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      // Header & Coach identity
      expect(find.text('Coach Dashboard'), findsOneWidget);
      expect(find.text('Vikram Malhotra'), findsOneWidget);

      // Upcoming Sessions & Read-only academy schedule notice
      expect(find.text('Upcoming Sessions'), findsOneWidget);
      expect(
        find.text('Third-Shot Drop & Kitchen Footwork (1-on-1)'),
        findsOneWidget,
      );
      expect(
        find.text('Academy Managed Schedule (Read-only)'),
        findsWidgets,
      );

      // Pending Tasks
      expect(find.text('Pending Tasks'), findsOneWidget);
      expect(
        find.text('Personal Session Booking Request — Ananya Rao'),
        findsOneWidget,
      );
      expect(
        find.text('Academy Affiliation Invitation — Coastal Spin Academy'),
        findsOneWidget,
      );

      // Player Summary separation
      expect(find.text('Player Summary'), findsOneWidget);
      expect(
        find.byKey(const Key('coach_personal_player_summary_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const Key('coach_academy_player_summary_acad_001_branch_andheri'),
        ),
        findsOneWidget,
      );

      // Finance Summary separation (only accepted academies, never Coastal Spin Academy)
      expect(find.text('Finance Summary'), findsOneWidget);
      expect(
        find.byKey(const Key('coach_personal_finance_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('coach_academy_finance_acad_001_branch_andheri')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('coach_academy_finance_acad_pending_003_all')),
        findsNothing,
      );

      await cubit.close();
    });

    testWidgets(
        'interactive Personal, Academy, and Branch filter chips update sections and empty states',
        (tester) async {
      _setViewport(tester);
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachDashboardPage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      // Tap Personal Coaching filter
      await tester.tap(find.byKey(const Key('coach_filter_personal')));
      await tester.pumpAndSettle();

      expect(
        find.text('Third-Shot Drop & Kitchen Footwork (1-on-1)'),
        findsOneWidget,
      );
      expect(
        find.text('Intermediate Doubles Tactics — Evening Batch B'),
        findsNothing,
      );
      expect(
        find.byKey(const Key('coach_personal_finance_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('coach_academy_finance_acad_001_branch_andheri')),
        findsNothing,
      );

      // Tap Academy filter -> select Apex Pickleball Academy -> select Bandra West Branch
      await tester.tap(find.byKey(const Key('coach_filter_academy')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('coach_filter_academy_acad_pending_003')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('coach_filter_academy_acad_001')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('coach_filter_branch_branch_bandra')));
      await tester.pumpAndSettle();

      expect(
        find.text('Junior High-Performance Morning Squad'),
        findsOneWidget,
      );
      expect(
        find.text('Intermediate Doubles Tactics — Evening Batch B'),
        findsNothing,
      );
      // Bandra branch has 0 pending tasks -> shows clean empty state card
      expect(find.byKey(const Key('coach_tasks_empty')), findsOneWidget);
      expect(
        find.byKey(const Key('coach_personal_finance_card')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('coach_academy_finance_acad_001_branch_bandra')),
        findsOneWidget,
      );

      await cubit.close();
    });

    testWidgets('tapping a pending task opens detail dialog', (tester) async {
      _setViewport(tester);
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(child: CoachDashboardPage(cubit: cubit)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('coach_task_card_task_001')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);

      await cubit.close();
    });

    testWidgets('renders cleanly in dark mode and wide desktop viewport',
        (tester) async {
      _setViewport(tester, const Size(1280, 1400));
      final cubit = CoachDashboardCubit(
        repository: const MockCoachDashboardRepository(),
      );

      await tester.pumpWidget(
        _buildTestFrame(
          mode: ThemeMode.dark,
          size: const Size(1280, 1400),
          child: CoachDashboardPage(cubit: cubit),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Coach Dashboard'), findsOneWidget);
      expect(find.text('Upcoming Sessions'), findsOneWidget);
      expect(find.text('Finance Summary'), findsOneWidget);

      await cubit.close();
    });
  });
}
