import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('GoogleMLKitAdapter', () {
    late GoogleMLKitAdapter adapter;

    setUp(() {
      adapter = GoogleMLKitAdapter(
        taskType: MLKitTaskType.textRecognition,
        modelId: 'test-mlkit-model',
        useSimulation: true,
      );
    });

    // --- Interface compliance ---

    test('implements AIModelAdapter', () {
      expect(adapter, isA<AIModelAdapter>());
    });

    test('modelId matches constructor value', () {
      expect(adapter.modelId, equals('test-mlkit-model'));
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

    test('runInference handles text recognition task', () async {
      final output = await adapter.runInference(AIInput(text: 'Hello World'));
      expect(output.text, contains('Text Recognition'));
    });

    test('runInference handles face detection task', () async {
      final faceAdapter = GoogleMLKitAdapter(
        taskType: MLKitTaskType.faceDetection,
        modelId: 'face-detector',
      );
      final output =
          await faceAdapter.runInference(AIInput(text: 'face image'));
      expect(output.text, contains('Face Detection'));
    });

    test('runInference handles image labeling task', () async {
      final labelAdapter = GoogleMLKitAdapter(
        taskType: MLKitTaskType.imageLabeling,
        modelId: 'image-labeler',
      );
      final output =
          await labelAdapter.runInference(AIInput(text: 'cat photo'));
      expect(output.text, contains('Image Labeling'));
    });

    test('runInference handles translation task', () async {
      final translateAdapter = GoogleMLKitAdapter(
        taskType: MLKitTaskType.translation,
        modelId: 'translator',
      );
      final output =
          await translateAdapter.runInference(AIInput(text: 'Hello'));
      expect(output.text, contains('Translation'));
    });

    test('runInference handles language identification task', () async {
      final langAdapter = GoogleMLKitAdapter(
        taskType: MLKitTaskType.languageIdentification,
        modelId: 'lang-identifier',
      );
      final output =
          await langAdapter.runInference(AIInput(text: 'Hello world'));
      expect(output.text, contains('Language Identification'));
    });

    test('runInference returns confidence', () async {
      final output = await adapter.runInference(AIInput(text: 'test'));
      expect(output.confidence, greaterThanOrEqualTo(0.0));
      expect(output.confidence, lessThanOrEqualTo(1.0));
    });

    test('runInference returns metadata', () async {
      final output = await adapter.runInference(AIInput(text: 'test'));
      expect(output.metadata?['runtime'], isNotNull);
      expect(output.metadata?['taskType'], isNotNull);
      expect(output.metadata?['modelId'], isNotNull);
    });

    // --- Constructor ---

    test('constructor with default values works', () {
      final defaultAdapter = GoogleMLKitAdapter();
      expect(defaultAdapter.modelId, equals('mlkit-model'));
      expect(defaultAdapter.taskType, equals(MLKitTaskType.textRecognition));
    });

    test('all task types work', () async {
      for (final taskType in MLKitTaskType.values) {
        final testAdapter = GoogleMLKitAdapter(
          taskType: taskType,
          modelId: 'test-$taskType',
        );
        final output = await testAdapter.runInference(AIInput(text: 'test'));
        expect(output.text, isNotEmpty);
      }
    });
  });
}
