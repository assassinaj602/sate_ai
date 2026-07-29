import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai_example/main.dart';

void main() {
  testWidgets('SATE AI Dashboard smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const SateAIApp());

    // Verify that the SATE AI title is present.
    expect(find.text('SATE AI'), findsOneWidget);

    // Verify that the run button is present.
    expect(find.text('Run Stress Test'), findsOneWidget);
  });
}
