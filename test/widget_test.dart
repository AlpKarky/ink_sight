// Basic smoke test for the InkSight app.

import 'package:flutter_test/flutter_test.dart';

import 'package:inksight/main.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Build the preview app and verify it renders
    await tester.pumpWidget(const InkSightPreview());
    await tester.pumpAndSettle();

    // Verify the sign in page is displayed
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });
}
