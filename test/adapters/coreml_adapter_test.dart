import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('CoreMLAdapter', () {
    late CoreMLAdapter adapter;

    setUp(() {
      adapter = CoreMLAdapter(
        modelPath: 'assets/models/model.mlmodel',
        modelId: 'test-coreml-model',
        useSimulation: true,
      );
    });

    // --- Interface compliance ---

    test('implements AIModelAdapter', () {
      expect(adapter, isA<AIModelAdapter>());
    });

    test('modelId matches constructor value', () {
      expect(adapter.modelId, equals('test-coreml-model'));
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

    test('isLoaded starts as false', () {
      expect(adapter.isLoaded, isFalse);
    });

    // --- Loading ---

    test('load() loads the model', () async {
      await adapter.load();
      expect(adapter.isLoaded, isTrue);
    });

    test('runInference loads model automatically', () async {
      await adapter.runInference(AIInput(text: 'test'));
      expect(adapter.isLoaded, isTrue);
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
        adapter.runInference(AIInput(text: 'test')),
        throwsA(isA<AIInferenceError>()),
      );
    });

    test('runInference returns AIOutput', () async {
      final output = await adapter.runInference(AIInput(text: 'test input'));
      expect(output, isA<AIOutput>());
      expect(output.text, isNotEmpty);
      expect(output.inferenceTime, greaterThan(Duration.zero));
    });

    test('runInference handles image input', () async {
      final output =
          await adapter.runInference(AIInput(text: 'image of a cat'));
      expect(output.text, contains('cat'));
    });

    test('runInference handles text input', () async {
      final output =
          await adapter.runInference(AIInput(text: 'text sentence'));
      expect(output.text, contains('text classification'));
    });

    test('runInference handles numeric input', () async {
      final output = await adapter.runInference(AIInput(text: 'number 42'));
      expect(output.text, contains('numeric'));
    });

    test('runInference returns confidence', () async {
      final output = await adapter.runInference(AIInput(text: 'test'));
      expect(output.confidence, greaterThanOrEqualTo(0.0));
      expect(output.confidence, lessThanOrEqualTo(1.0));
    });

    test('runInference returns metadata', () async {
      final output = await adapter.runInference(AIInput(text: 'test'));
      expect(output.metadata?['runtime'], isNotNull);
      expect(output.metadata?['modelId'], isNotNull);
      expect(output.metadata?['simulation'], isNotNull);
    });

    // --- Constructor ---

    test('constructor with default values works', () {
      final defaultAdapter = CoreMLAdapter(
        modelPath: 'model.mlmodel',
        modelId: 'default',
      );
      expect(defaultAdapter.modelId, equals('default'));
      expect(defaultAdapter.useSimulation, isTrue);
    });
  });
}
