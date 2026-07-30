import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('ConfidenceThresholdInjector Unit Tests', () {
    late MockAdapter mockModel;

    setUp(() {
      mockModel = MockAdapter(modelId: 'test-model');
    });

    test('1. Type is FaultType.confidenceValidation', () {
      final injector = ConfidenceThresholdInjector(model: mockModel);
      expect(injector.type, FaultType.confidenceValidation);
    });

    test('2. Name is non-empty and correct', () {
      final injector = ConfidenceThresholdInjector(model: mockModel);
      expect(injector.name, 'Confidence Threshold Validator');
    });

    test('3. Description is non-empty and mentions threshold', () {
      final injector =
          ConfidenceThresholdInjector(model: mockModel, threshold: 0.7);
      expect(injector.description, contains('0.7'));
    });

    test('4. Threshold defaults to 0.5', () {
      final injector = ConfidenceThresholdInjector(model: mockModel);
      expect(injector.threshold, 0.5);
    });

    test('5. Constructor asserts on invalid threshold', () {
      expect(
          () => ConfidenceThresholdInjector(model: mockModel, threshold: -0.1),
          throwsAssertionError);
      expect(
          () => ConfidenceThresholdInjector(model: mockModel, threshold: 1.1),
          throwsAssertionError);
    });

    test('6. reset clears failed state and resets confidence', () async {
      final injector =
          ConfidenceThresholdInjector(model: mockModel, threshold: 0.8);

      await injector.inject();
      expect(injector.failed, isFalse);

      await injector.reset();
      expect(injector.failed, isFalse);
      expect(injector.lastConfidence, 1.0);
    });

    test('7. inject throws AIInferenceError if confidence is below threshold',
        () async {
      final injector = ConfidenceThresholdInjector(
          model: mockModel, threshold: 0.99); // Mock is 0.97

      await expectLater(
        injector.inject(),
        throwsA(isA<AIInferenceError>()),
      );
      expect(injector.failed, isTrue);
      expect(injector.lastConfidence, 0.97);
    });

    test('8. inject completes normally if confidence is above threshold',
        () async {
      final injector = ConfidenceThresholdInjector(
          model: mockModel, threshold: 0.9); // Mock is 0.97

      await expectLater(injector.inject(), completes);
      expect(injector.failed, isFalse);
      expect(injector.lastConfidence, 0.97);
    });

    test(
        '9. StressRunner integration with ConfidenceThresholdInjector (failure)',
        () async {
      final injector = ConfidenceThresholdInjector(
          model: mockModel, threshold: 0.99); // Will fail since mock is 0.97

      final report = await SateAI.stress(
        model: mockModel,
        injectors: [injector],
      );

      expect(report.passed, isFalse);
      expect(report.results.first.passed, isFalse);
      expect(report.results.first.errorMessage,
          contains('Confidence threshold breached'));
    });

    test(
        '10. StressRunner integration with ConfidenceThresholdInjector (success)',
        () async {
      final injector = ConfidenceThresholdInjector(
          model: mockModel, threshold: 0.9); // Will pass since mock is 0.97

      final report = await SateAI.stress(
        model: mockModel,
        injectors: [injector],
      );

      expect(report.passed, isTrue);
    });
  });
}
