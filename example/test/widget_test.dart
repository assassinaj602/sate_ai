// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';

import 'package:sate_ai_example/main.dart';

void main() {
  testWidgets('SATE AI Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SateAIApp());

    // Verify that SATE AI title is present.
    expect(find.text('SATE AI'), findsOneWidget);

    // Verify that the run button is present.
    expect(find.text('Run Stress Test'), findsOneWidget);
  });
}
