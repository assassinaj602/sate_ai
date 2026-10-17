import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai_example/main.dart';

void main() {
  testWidgets('SATE AI Dashboard smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const SateAIApp());

    // Verify that the SATE AI title and Tutorial button are present.
    expect(find.text('SATE AI Stress Test Demo'), findsOneWidget);
    expect(find.text('Tutorial'), findsOneWidget);

    // Verify that the run button is present.
    expect(find.text('Run Suite'), findsOneWidget);

    // Verify tapping Tutorial button opens the tutorial dialog.
    await tester.tap(find.text('Tutorial'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('SATE AI Guided Tutorial'), findsOneWidget);
    expect(find.text('Step 1: Installation and Architecture'), findsOneWidget);
  });
}
