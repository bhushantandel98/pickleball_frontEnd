import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pickleball_platform/core/access/session_cubit.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/router/app_router.dart';
import 'package:pickleball_platform/core/router/app_routes.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/login_page.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/register_page.dart';
import 'package:pickleball_platform/features/identity/presentation/pages/welcome_page.dart';
import 'package:pickleball_platform/features/identity/presentation/widgets/brand_logo_emblem.dart';

void main() {
  Widget buildTestableWidget({
    Widget? child,
    ThemeMode themeMode = ThemeMode.light,
    VoidCallback? onLogin,
    VoidCallback? onRegister,
  }) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: child ??
          WelcomePage(
            onLoginPressed: onLogin,
            onRegisterPressed: onRegister,
          ),
    );
  }

  group('WelcomePage UI Elements & Reusability Tests', () {
    testWidgets('renders brand emblem, heading, description, and feature highlights',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      // Brand emblem
      expect(find.byType(BrandLogoEmblem), findsOneWidget);
      expect(find.bySemanticsLabel('Pickleball Platform Logo'), findsOneWidget);

      // Primary Heading
      expect(find.text('Welcome to Pickleball'), findsOneWidget);

      // Description text
      expect(
        find.textContaining('The unified platform connecting players, coaches'),
        findsOneWidget,
      );

      // Feature highlights
      expect(find.text('12 Roles'), findsOneWidget);
      expect(find.text('Venues'), findsOneWidget);
      expect(find.text('Tournaments'), findsOneWidget);

      // Terms notice
      expect(
        find.textContaining('Terms of Service and Privacy Policy'),
        findsOneWidget,
      );
    });

    testWidgets('renders primary Sign In button and outline Create Account button',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      final signInFinder = find.widgetWithText(AppButton, 'Sign In');
      final createAccountFinder = find.widgetWithText(AppButton, 'Create Account');

      expect(signInFinder, findsOneWidget);
      expect(createAccountFinder, findsOneWidget);

      final signInButton = tester.widget<AppButton>(signInFinder);
      final createAccountButton = tester.widget<AppButton>(createAccountFinder);

      expect(signInButton.variant, equals(AppButtonVariant.primary));
      expect(createAccountButton.variant, equals(AppButtonVariant.outline));
    });

    testWidgets('invokes onLoginPressed callback when Sign In button is tapped',
        (tester) async {
      bool loginCalled = false;
      await tester.pumpWidget(
        buildTestableWidget(onLogin: () => loginCalled = true),
      );

      await tester.tap(find.widgetWithText(AppButton, 'Sign In'));
      await tester.pump();

      expect(loginCalled, isTrue);
    });

    testWidgets('invokes onRegisterPressed callback when Create Account button is tapped',
        (tester) async {
      bool registerCalled = false;
      await tester.pumpWidget(
        buildTestableWidget(onRegister: () => registerCalled = true),
      );

      await tester.tap(find.widgetWithText(AppButton, 'Create Account'));
      await tester.pump();

      expect(registerCalled, isTrue);
    });

    testWidgets('renders correctly in dark mode', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(themeMode: ThemeMode.dark),
      );

      expect(find.text('Welcome to Pickleball'), findsOneWidget);
      expect(find.byType(BrandLogoEmblem), findsOneWidget);
    });
  });

  group('WelcomePage Navigation Integration Tests', () {
    late SessionCubit sessionCubit;
    late GoRouter router;

    setUp(() {
      sessionCubit = SessionCubit();
      router = createAppRouter(
        sessionCubit: sessionCubit,
        initialLocation: AppRoutes.welcome,
      );
    });

    tearDown(() {
      sessionCubit.close();
    });

    testWidgets('tapping Sign In navigates to placeholder login route (/auth/login)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Pickleball'), findsOneWidget);

      // Tap Sign In
      await tester.tap(find.widgetWithText(AppButton, 'Sign In'));
      await tester.pumpAndSettle();

      // Navigated to login screen
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('tapping Create Account navigates to placeholder register route (/auth/register)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.lightTheme,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Pickleball'), findsOneWidget);

      // Tap Create Account
      await tester.tap(find.widgetWithText(AppButton, 'Create Account'));
      await tester.pumpAndSettle();

      // Navigated to register screen
      expect(find.byType(RegisterPage), findsOneWidget);
      expect(find.text('Create Player Account'), findsOneWidget);
    });
  });

  group('WelcomePage Responsive Layout Tests', () {
    testWidgets('mobile viewport (<600dp) renders direct content layout without outer AppCard',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Pickleball'), findsOneWidget);
      expect(find.byType(AppCard), findsNothing);
    });

    testWidgets('desktop viewport (>1024dp) renders content wrapped in AppCard with max width constraint',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Pickleball'), findsOneWidget);
      expect(find.byType(AppCard), findsOneWidget);
    });
  });
}
