import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/core/design_system/app_theme.dart';
import 'package:pickleball_platform/core/design_system/responsive_layout.dart';
import 'package:pickleball_platform/core/widgets/app_button.dart';
import 'package:pickleball_platform/core/widgets/app_card.dart';
import 'package:pickleball_platform/core/widgets/app_chip.dart';
import 'package:pickleball_platform/core/widgets/app_dialog.dart';
import 'package:pickleball_platform/core/widgets/app_dropdown.dart';
import 'package:pickleball_platform/core/widgets/app_text_field.dart';
import 'package:pickleball_platform/core/widgets/common_app_bar.dart';
import 'package:pickleball_platform/core/widgets/state_views/account_suspended_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/empty_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/error_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/loading_view.dart';
import 'package:pickleball_platform/core/widgets/state_views/permission_denied_view.dart';

Widget _wrapWithTheme(Widget child, {bool isDark = false}) {
  return MaterialApp(
    theme: isDark ? AppTheme.darkTheme : AppTheme.lightTheme,
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('Design System — Atomic Component Tests', () {
    testWidgets('AppButton renders label, handles tap, and disables when loading',
        (tester) async {
      var tapped = false;

      // Normal enabled state
      await tester.pumpWidget(
        _wrapWithTheme(
          AppButton.primary(
            label: 'Submit',
            onPressed: () => tapped = true,
          ),
        ),
      );
      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.text('Submit'));
      expect(tapped, isTrue);

      // Loading state
      tapped = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          AppButton.primary(
            label: 'Submit',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(AppButton));
      expect(tapped, isFalse);
    });

    testWidgets('AppButton destructive and outline variants render with theme styles',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          Column(
            children: [
              AppButton.destructive(label: 'Delete', onPressed: () {}),
              AppButton.outline(label: 'Outline', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Outline'), findsOneWidget);
    });

    testWidgets('AppTextField renders label and toggles password visibility',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const AppTextField.password(),
        ),
      );

      expect(find.text('Password'), findsOneWidget);

      final textField = tester.widget<EditableText>(find.byType(EditableText));
      expect(textField.obscureText, isTrue);

      // Tap toggle visibility
      await tester.tap(find.byType(IconButton));
      await tester.pump();

      final updatedField = tester.widget<EditableText>(find.byType(EditableText));
      expect(updatedField.obscureText, isFalse);
    });

    test('AppTextField asserts when both controller and initialValue are provided', () {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      expect(
        () => AppTextField(
          controller: controller,
          initialValue: 'conflict',
        ),
        throwsAssertionError,
      );

      expect(
        () => AppTextField.password(
          controller: controller,
          initialValue: 'conflict',
        ),
        throwsAssertionError,
      );
    });

    testWidgets('AppTextField accepts controller or initialValue separately',
        (tester) async {
      final controller = TextEditingController(text: 'With Controller');
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _wrapWithTheme(
          Column(
            children: [
              AppTextField(controller: controller),
              const AppTextField(initialValue: 'With InitialValue'),
            ],
          ),
        ),
      );

      expect(find.text('With Controller'), findsOneWidget);
      expect(find.text('With InitialValue'), findsOneWidget);
    });

    testWidgets('AppDropdown displays selected item and items list', (tester) async {
      String? selected = 'RoleA';

      await tester.pumpWidget(
        _wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return AppDropdown<String>(
                label: 'Role',
                value: selected,
                items: const [
                  DropdownMenuItem(value: 'RoleA', child: Text('Role A')),
                  DropdownMenuItem(value: 'RoleB', child: Text('Role B')),
                ],
                onChanged: (val) => setState(() => selected = val),
              );
            },
          ),
        ),
      );

      expect(find.text('Role A'), findsOneWidget);
      await tester.tap(find.text('Role A'));
      await tester.pumpAndSettle();

      expect(find.text('Role B').last, findsOneWidget);
      await tester.tap(find.text('Role B').last);
      await tester.pumpAndSettle();

      expect(selected, 'RoleB');
    });

    testWidgets('AppCard renders child and handles tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          AppCard(
            onTap: () => tapped = true,
            child: const Text('Card Content'),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      expect(tapped, isTrue);
    });

    testWidgets('AppChip renders success, warning, error and neutral states',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const Column(
            children: [
              AppChip.success(label: 'Active'),
              AppChip.warning(label: 'Pending'),
              AppChip.error(label: 'Rejected'),
              AppChip(label: 'Draft'),
            ],
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('AppChip renders in dark mode with valid contrast tokens', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const Column(
            children: [
              AppChip.success(label: 'Active'),
              AppChip.warning(label: 'Pending'),
              AppChip.error(label: 'Rejected'),
              AppChip.info(label: 'Info'),
              AppChip(label: 'Draft'),
            ],
          ),
          isDark: true,
        ),
      );

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Info'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets('AppConfirmationDialog displays message and callbacks execute',
        (tester) async {
      var confirmed = false;

      await tester.pumpWidget(
        _wrapWithTheme(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppConfirmationDialog.show(
                    context: context,
                    title: 'Confirm Removal',
                    message: 'Are you sure you want to remove this player?',
                    isDestructive: true,
                  ).then((val) {
                    if (val == true) confirmed = true;
                  });
                },
                child: const Text('Open Dialog'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Removal'), findsOneWidget);
      expect(find.text('Are you sure you want to remove this player?'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      expect(confirmed, isTrue);
    });

    testWidgets('CommonAppBar renders title and subtitle correctly', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const Scaffold(
            appBar: CommonAppBar(
              title: 'Tournament Operations',
              subtitle: 'Active Role: Organizer',
            ),
          ),
        ),
      );

      expect(find.text('Tournament Operations'), findsOneWidget);
      expect(find.text('Active Role: Organizer'), findsOneWidget);
    });
  });

  group('Design System — State Views Tests', () {
    testWidgets('LoadingView renders message', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(const LoadingView(message: 'Loading venues...')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading venues...'), findsOneWidget);
    });

    testWidgets('EmptyStateView renders title, message and action button', (tester) async {
      var actionTriggered = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          EmptyStateView(
            title: 'No Bookings',
            message: 'You have no scheduled court bookings.',
            actionLabel: 'Discover Courts',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('No Bookings'), findsOneWidget);
      expect(find.text('You have no scheduled court bookings.'), findsOneWidget);
      expect(find.text('Discover Courts'), findsOneWidget);

      await tester.tap(find.text('Discover Courts'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('ErrorStateView renders error and handles retry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          ErrorStateView(
            message: 'Network connection lost.',
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Something Went Wrong'), findsOneWidget);
      expect(find.text('Network connection lost.'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('PermissionDeniedView renders restricted access information',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(const PermissionDeniedView()),
      );

      expect(find.text('Access Restricted'), findsOneWidget);
      expect(
        find.text('You do not have permission to view this section or perform this action.'),
        findsOneWidget,
      );
    });

    testWidgets('AccountSuspendedView renders support details and CTA when contact is provided',
        (tester) async {
      var contactTapped = false;
      await tester.pumpWidget(
        _wrapWithTheme(
          AccountSuspendedView(
            supportContact: 'admin@pickleball.org',
            onContactSupport: () => contactTapped = true,
          ),
        ),
      );

      expect(find.text('Account Suspended'), findsOneWidget);
      expect(find.text('Contact: admin@pickleball.org'), findsOneWidget);

      await tester.tap(find.text('Reach Support'));
      expect(contactTapped, isTrue);
    });

    testWidgets('AccountSuspendedView hides contact section when supportContact is omitted',
        (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const AccountSuspendedView(),
        ),
      );

      expect(find.text('Account Suspended'), findsOneWidget);
      expect(find.textContaining('Contact:'), findsNothing);
      expect(find.byType(AppButton), findsNothing);
    });
  });

  group('Design System — ResponsiveLayout Tests', () {
    testWidgets('ResponsiveLayout adapts layout based on screen width', (tester) async {
      // Mobile screen (<600)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        _wrapWithTheme(
          ResponsiveLayout(
            mobile: (_) => const Text('Mobile Layout'),
            tablet: (_) => const Text('Tablet Layout'),
            desktop: (_) => const Text('Desktop Layout'),
          ),
        ),
      );
      expect(find.text('Mobile Layout'), findsOneWidget);
      expect(find.text('Tablet Layout'), findsNothing);

      // Tablet screen (600 - 1024)
      tester.view.physicalSize = const Size(800, 1000);
      await tester.pumpWidget(
        _wrapWithTheme(
          ResponsiveLayout(
            mobile: (_) => const Text('Mobile Layout'),
            tablet: (_) => const Text('Tablet Layout'),
            desktop: (_) => const Text('Desktop Layout'),
          ),
        ),
      );
      expect(find.text('Tablet Layout'), findsOneWidget);

      // Desktop screen (>1024)
      tester.view.physicalSize = const Size(1200, 900);
      await tester.pumpWidget(
        _wrapWithTheme(
          ResponsiveLayout(
            mobile: (_) => const Text('Mobile Layout'),
            tablet: (_) => const Text('Tablet Layout'),
            desktop: (_) => const Text('Desktop Layout'),
          ),
        ),
      );
      expect(find.text('Desktop Layout'), findsOneWidget);
    });
  });

  group('Design System — AppChip WCAG AA Contrast Tests', () {
    double calculateContrast(Color foreground, Color background) {
      final l1 = foreground.computeLuminance();
      final l2 = background.computeLuminance();
      final lighter = l1 > l2 ? l1 : l2;
      final darker = l1 > l2 ? l2 : l1;
      return (lighter + 0.05) / (darker + 0.05);
    }

    test('All four chip variants in Light Theme meet WCAG AA contrast (>= 4.5:1)', () {
      final lightTheme = AppTheme.lightTheme;
      const variants = [
        AppChipType.success,
        AppChipType.warning,
        AppChipType.error,
        AppChipType.info,
      ];

      for (final variant in variants) {
        final (bg, text) = AppChip.resolveColors(lightTheme, variant);
        final ratio = calculateContrast(text, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'Variant $variant in light theme failed WCAG AA (contrast: ${ratio.toStringAsFixed(2)}:1)',
        );
      }
    });

    test('All four chip variants in Dark Theme meet WCAG AA contrast (>= 4.5:1)', () {
      final darkTheme = AppTheme.darkTheme;
      const variants = [
        AppChipType.success,
        AppChipType.warning,
        AppChipType.error,
        AppChipType.info,
      ];

      for (final variant in variants) {
        final (bg, text) = AppChip.resolveColors(darkTheme, variant);
        final ratio = calculateContrast(text, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason: 'Variant $variant in dark theme failed WCAG AA (contrast: ${ratio.toStringAsFixed(2)}:1)',
        );
      }
    });

    test('Neutral chip variant in both themes meets WCAG AA contrast (>= 4.5:1)', () {
      final lightTheme = AppTheme.lightTheme;
      final darkTheme = AppTheme.darkTheme;

      final (lightBg, lightText) = AppChip.resolveColors(lightTheme, AppChipType.neutral);
      final (darkBg, darkText) = AppChip.resolveColors(darkTheme, AppChipType.neutral);

      expect(calculateContrast(lightText, lightBg), greaterThanOrEqualTo(4.5));
      expect(calculateContrast(darkText, darkBg), greaterThanOrEqualTo(4.5));
    });
  });
}
