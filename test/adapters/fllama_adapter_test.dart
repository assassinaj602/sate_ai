import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('FllamaAdapter', () {
    late FllamaAdapter adapter;

    setUp(() {
      adapter = FllamaAdapter(
        modelPath: 'assets/models/phi-2.Q4_K_M.gguf',
        modelId: 'test-phi-2',
        contextSize: 256,
        threads: 1,
        tokens: 32,
      );
    });

    // --- Interface compliance ---

    test('implements AIModelAdapter', () {
      expect(adapter, isA<AIModelAdapter>());
    });

    test('modelId matches constructor value', () {
      expect(adapter.modelId, equals('test-phi-2'));
    });

    test('modelId is non-empty', () {
      expect(adapter.modelId, isNotEmpty);
    });

    // --- Initial state ---

    test('currentMemoryMB starts at 0', () {
      expect(adapter.currentMemoryMB, equals(0.0));
    });

    test('currentGPUMemoryMB starts at 0', () {
      expect(adapter.currentGPUMemoryMB, equals(0.0));
    });

    test('isDegraded starts as false', () {
      expect(adapter.isDegraded, isFalse);
    });

    test('isHealthy starts as true', () async {
      expect(await adapter.isHealthy(), isTrue);
    });

    // --- Memory pressure ---

    test('simulateMemoryPressure increases currentMemoryMB', () async {
      await adapter.simulateMemoryPressure(50);
      expect(adapter.currentMemoryMB, equals(50.0));
      expect(await adapter.isHealthy(), isTrue);
    });

    test('simulateMemoryPressure degrades after threshold', () async {
      await adapter.simulateMemoryPressure(160);
      expect(adapter.currentMemoryMB, equals(160.0));
      expect(adapter.isDegraded, isTrue);
      expect(await adapter.isHealthy(), isFalse);
    });

    test('simulateGPUMemoryPressure increases currentGPUMemoryMB', () async {
      await adapter.simulateGPUMemoryPressure(50);
      expect(adapter.currentGPUMemoryMB, equals(50.0));
    });

    test('simulateGPUMemoryPressure degrades after threshold', () async {
      await adapter.simulateGPUMemoryPressure(160);
      expect(adapter.currentGPUMemoryMB, equals(160.0));
      expect(adapter.isDegraded, isTrue);
    });

    // --- Reset ---

    test('reset clears memory and degradation', () async {
      await adapter.simulateMemoryPressure(160);
      expect(adapter.isDegraded, isTrue);

      await adapter.reset();
      expect(adapter.currentMemoryMB, equals(0.0));
      expect(adapter.currentGPUMemoryMB, equals(0.0));
      expect(adapter.isDegraded, isFalse);
      expect(await adapter.isHealthy(), isTrue);
    });

    // --- Inference ---

    test('runInference throws when degraded', () async {
      await adapter.simulateMemoryPressure(160);
      await expectLater(
        adapter.runInference(AIInput(text: 'Hello')),
        throwsA(isA<AIInferenceError>()),
      );
    });

    test('runInference returns AIOutput', () async {
      final output = await adapter.runInference(AIInput(text: 'Hello, world!'));
      expect(output, isA<AIOutput>());
      expect(output.text, isNotEmpty);
      expect(output.inferenceTime, greaterThan(Duration.zero));
    });

    test('runInference handles empty input', () async {
      final output = await adapter.runInference(AIInput(text: ''));
      expect(output.text, isNotEmpty);
    });

    test('runInference returns confidence', () async {
      final output = await adapter.runInference(AIInput(text: 'Hello'));
      expect(output.confidence, greaterThanOrEqualTo(0.0));
      expect(output.confidence, lessThanOrEqualTo(1.0));
    });

    test('runInference returns metadata', () async {
      final output = await adapter.runInference(AIInput(text: 'Hello'));
      expect(output.metadata != null, isTrue);
      expect(output.metadata!['runtime'], equals('Fllama (llama.cpp)'));
      expect(output.metadata!['modelId'], equals('test-phi-2'));
      expect(output.metadata!['memoryMB'], equals(0.0));
    });

    // --- Edge cases ---

    test('constructor with default values works', () {
      final defaultAdapter = FllamaAdapter(
        modelPath: 'model.gguf',
        modelId: 'default',
      );
      expect(defaultAdapter.modelId, equals('default'));
      expect(defaultAdapter.contextSize, equals(512));
      expect(defaultAdapter.threads, equals(2));
    });

    test('dispose does not throw', () async {
      expect(() async => await adapter.dispose(), returnsNormally);
    });
  });
}
