import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai_example/tutorial/interactive_tutorial.dart';

void main() {
  group('InteractiveTutorialDialog Tests', () {
    Widget buildTestHarness(
      WidgetTester tester, {
      TutorialConfiguration initialConfig = const TutorialConfiguration(),
      void Function(TutorialConfiguration config)? onApply,
    }) {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      return MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: InteractiveTutorialDialog(
            initialConfiguration: initialConfig,
            onApplyConfiguration: onApply,
          ),
        ),
      );
    }

    testWidgets(
        'displays header, progress bar, and all 5 step navigation chips',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness(tester));
      await tester.pump(const Duration(milliseconds: 200));

      // Header
      expect(find.text('SATE AI Guided Tutorial'), findsOneWidget);
      expect(
        find.text('Learn on-device AI fault injection and resilience testing'),
        findsOneWidget,
      );

      // Step chips
      expect(find.text('1. Installation'), findsOneWidget);
      expect(find.text('2. Basic Test'), findsOneWidget);
      expect(find.text('3. Injectors'), findsOneWidget);
      expect(find.text('4. Custom Adapters'), findsOneWidget);
      expect(find.text('5. Reports'), findsOneWidget);

      // Bottom bar
      expect(find.text('Step 1 of 5'), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Apply to Dashboard'), findsOneWidget);
    });

    testWidgets('Step 1 switches code snippet when platform chips are tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness(tester));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
          find.text('Step 1: Installation and Architecture'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('CLI'), findsOneWidget);
      expect(find.text('Android'), findsOneWidget);
      expect(find.text('Web'), findsOneWidget);

      // Tap CLI
      await tester.tap(find.text('CLI'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('dart pub global activate sate_cli'),
          findsOneWidget);

      // Tap Android
      await tester.tap(find.text('Android'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('sate-android'), findsOneWidget);

      // Tap Web
      await tester.tap(find.text('Web'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('@sate-ai/core'), findsOneWidget);
    });

    testWidgets(
        'navigates sequentially through steps with Next and Back buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness(tester));
      await tester.pump(const Duration(milliseconds: 200));

      // Start at Step 1
      expect(
          find.text('Step 1: Installation and Architecture'), findsOneWidget);
      expect(find.text('Step 1 of 5'), findsOneWidget);

      // Advance to Step 2
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Step 2: Basic Stress Test Execution'), findsOneWidget);
      expect(find.text('Step 2 of 5'), findsOneWidget);

      // Advance to Step 3
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Step 3: Configuring Fault Injectors'), findsOneWidget);
      expect(find.text('Step 3 of 5'), findsOneWidget);

      // Go back to Step 2
      await tester.tap(find.text('Back'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Step 2: Basic Stress Test Execution'), findsOneWidget);
      expect(find.text('Step 2 of 5'), findsOneWidget);
    });

    testWidgets('Step 2 executes baseline probe and updates status',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness(tester));
      await tester.pump(const Duration(milliseconds: 200));

      // Navigate to Step 2
      await tester.tap(find.text('Next'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Run Baseline Probe'), findsOneWidget);
      await tester.ensureVisible(find.text('Run Baseline Probe'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap probe button
      await tester.tap(find.text('Run Baseline Probe'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify probe completed
      expect(find.textContaining('Success! Response:'), findsOneWidget);
    });

    testWidgets('Step 3 allows toggling injectors and updates active count',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness(tester));
      await tester.pump(const Duration(milliseconds: 200));

      // Jump to Step 3
      await tester.ensureVisible(find.text('3. Injectors'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('3. Injectors'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Step 3: Configuring Fault Injectors'), findsOneWidget);
      expect(find.text('AdaptiveChaosInjector'), findsOneWidget);

      // Initially 5 active injectors
      expect(find.textContaining('Configured 5 active injector(s)'),
          findsOneWidget);

      // Toggle AdaptiveChaosInjector on
      await tester.ensureVisible(find.text('AdaptiveChaosInjector'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('AdaptiveChaosInjector'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Configured 6 active injector(s)'),
          findsOneWidget);
    });

    testWidgets(
        'Step 4 switches between Vision and LLM custom adapter templates',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness(tester));
      await tester.pump(const Duration(milliseconds: 200));

      // Jump to Step 4
      await tester.ensureVisible(find.text('4. Custom Adapters'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('4. Custom Adapters'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Step 4: Implementing Custom Adapters'), findsOneWidget);
      expect(find.textContaining('MyCustomVisionAdapter'), findsOneWidget);

      // Switch to LLM template
      await tester.ensureVisible(find.text('LLM / Generative'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('LLM / Generative'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('MyCustomLLMAdapter'), findsOneWidget);
    });

    testWidgets('Step 5 displays reports and toggles pass/fail simulation',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHarness(tester));
      await tester.pump(const Duration(milliseconds: 200));

      // Jump to Step 5
      await tester.ensureVisible(find.text('5. Reports'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('5. Reports'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(
          find.text('Step 5: Analyzing Reports and Metrics'), findsOneWidget);
      expect(find.text('STRESS REPORT: PASSED'), findsOneWidget);

      // Toggle state to failed
      await tester.ensureVisible(find.text('Toggle State'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Toggle State'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('STRESS REPORT: FAILED (REGRESSION)'), findsOneWidget);
    });

    testWidgets(
        'Apply to Dashboard triggers onApplyConfiguration with modified settings',
        (WidgetTester tester) async {
      TutorialConfiguration? appliedConfig;

      await tester.pumpWidget(buildTestHarness(
        tester,
        onApply: (config) => appliedConfig = config,
      ));
      await tester.pump(const Duration(milliseconds: 200));

      // Jump to Step 3 and toggle adaptive chaos
      await tester.ensureVisible(find.text('3. Injectors'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('3. Injectors'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.ensureVisible(find.text('AdaptiveChaosInjector'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('AdaptiveChaosInjector'));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Apply to Dashboard
      await tester.tap(find.text('Apply to Dashboard'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(appliedConfig, isNotNull);
      expect(appliedConfig!.useAdaptiveChaos, isTrue);
    });
  });
}
