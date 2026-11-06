import 'package:flutter_test/flutter_test.dart';
import 'package:pickleball_platform/app/app.dart';

void main() {
  testWidgets('PickleballApp bootstrap smoke test', (WidgetTester tester) async {
    // Build root app widget and trigger a frame
    await tester.pumpWidget(const PickleballApp());
    await tester.pumpAndSettle();

    // Verify initial bootstrap screen redirects unauthenticated user to welcome screen
    expect(find.text('Welcome to Pickleball'), findsOneWidget);
  });
}
