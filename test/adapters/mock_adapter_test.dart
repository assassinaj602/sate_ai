import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('MockAdapter', () {
    late MockAdapter adapter;

    setUp(() {
      adapter = MockAdapter(
        inferenceDelay: const Duration(milliseconds: 10),
      );
    });

    // ------------------------------------------------------------------
    // Identity
    // ------------------------------------------------------------------

    test('modelId defaults to mock-model-v1', () {
      expect(adapter.modelId, equals('mock-model-v1'));
    });

    test('custom modelId is preserved', () {
      final custom = MockAdapter(modelId: 'my-model-123');
      expect(custom.modelId, equals('my-model-123'));
    });

    // ------------------------------------------------------------------
    // Healthy inference
    // ------------------------------------------------------------------

    test('runInference returns AIOutput for text input', () async {
      final output = await adapter.runInference(AIInput(text: 'hello'));
      expect(output, isA<AIOutput>());
      expect(output.text, isNotEmpty);
    });

    test('runInference includes confidence score', () async {
      final output = await adapter.runInference(AIInput(text: 'test'));
      expect(output.confidence, isNotNull);
      expect(output.confidence, greaterThan(0.0));
    });

    test('runInference inferenceTime is positive', () async {
      final output = await adapter.runInference(AIInput(text: 'test'));
      expect(output.inferenceTime.inMilliseconds, greaterThan(0));
    });

    // ------------------------------------------------------------------
    // Failure mode
    // ------------------------------------------------------------------

    test('forceFailure=true causes runInference to throw AIInferenceError',
        () async {
      final broken = MockAdapter(forceFailure: true);
      await expectLater(
        broken.runInference(AIInput(text: 'x')),
        throwsA(isA<AIInferenceError>()),
      );
    });

    test('forceFailure message is included in exception', () async {
      final broken = MockAdapter(
        forceFailure: true,
        forceFailureMessage: 'custom error msg',
      );
      try {
        await broken.runInference(AIInput(text: 'x'));
        fail('Expected AIInferenceError');
      } on AIInferenceError catch (e) {
        expect(e.message, contains('custom error msg'));
      }
    });

    // ------------------------------------------------------------------
    // Memory simulation
    // ------------------------------------------------------------------

    test('simulateMemoryPressure increases currentMemoryMB', () async {
      expect(adapter.allocatedMemory, isNull);
      await adapter.simulateMemoryPressure(50);
      expect(adapter.currentMemoryMB, greaterThanOrEqualTo(50));
      expect(adapter.allocatedMemory, isNotNull);
    });

    test('simulateMemoryPressure over 150 MB marks adapter as degraded',
        () async {
      await adapter.simulateMemoryPressure(200);
      expect(adapter.isDegraded, isTrue);
    });

    test('reset() clears memory and degradation', () async {
      await adapter.simulateMemoryPressure(200);
      expect(adapter.isDegraded, isTrue);
      expect(adapter.allocatedMemory, isNotNull);
      await adapter.reset();
      expect(adapter.isDegraded, isFalse);
      expect(adapter.currentMemoryMB, equals(0.0));
      expect(adapter.allocatedMemory, isNull);
    });

    // ------------------------------------------------------------------
    // isHealthy
    // ------------------------------------------------------------------

    test('isHealthy returns true for a fresh adapter', () async {
      final healthy = await adapter.isHealthy();
      expect(healthy, isTrue);
    });

    test('isHealthy returns false when degraded', () async {
      adapter.degraded = true;
      final healthy = await adapter.isHealthy();
      expect(healthy, isFalse);
    });
  });
}
