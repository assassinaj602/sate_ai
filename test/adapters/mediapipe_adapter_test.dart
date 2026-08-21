import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('MediaPipeAdapter', () {
    late MediaPipeAdapter adapter;

    setUp(() {
      adapter = MediaPipeAdapter(
        taskType: MediaPipeTaskType.faceDetection,
        modelId: 'test-face-detector',
      );
    });

    // --- Interface compliance ---

    test('implements AIModelAdapter', () {
      expect(adapter, isA<AIModelAdapter>());
    });

    test('modelId matches constructor value', () {
      expect(adapter.modelId, equals('test-face-detector'));
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
        adapter.runInference(AIInput(text: 'test')),
        throwsA(isA<AIInferenceError>()),
      );
    });

    test('runInference returns AIOutput', () async {
      final output = await adapter.runInference(AIInput(text: 'test image'));
      expect(output, isA<AIOutput>());
      expect(output.text, isNotEmpty);
      expect(output.inferenceTime, greaterThan(Duration.zero));
    });

    test('runInference returns correct output for face detection', () async {
      final output = await adapter.runInference(AIInput(text: 'face image'));
      expect(output.text.toLowerCase(), contains('face detection'));
    });

    test('runInference returns correct output for pose estimation', () async {
      final poseAdapter = MediaPipeAdapter(
        taskType: MediaPipeTaskType.poseEstimation,
        modelId: 'pose-model',
      );
      final output =
          await poseAdapter.runInference(AIInput(text: 'pose image'));
      expect(output.text.toLowerCase(), contains('pose estimation'));
    });

    test('runInference returns correct output for object detection', () async {
      final objectAdapter = MediaPipeAdapter(
        taskType: MediaPipeTaskType.objectDetection,
        modelId: 'object-model',
      );
      final output =
          await objectAdapter.runInference(AIInput(text: 'object image'));
      expect(output.text.toLowerCase(), contains('object detection'));
    });

    test('runInference returns confidence', () async {
      final output = await adapter.runInference(AIInput(text: 'test'));
      expect(output.confidence, greaterThanOrEqualTo(0.0));
      expect(output.confidence, lessThanOrEqualTo(1.0));
    });

    test('runInference returns metadata', () async {
      final output = await adapter.runInference(AIInput(text: 'test'));
      expect(output.metadata != null, isTrue);
      expect(output.metadata!['runtime'], equals('Google ML Kit (MediaPipe)'));
      expect(output.metadata!['taskType'], equals('faceDetection'));
      expect(output.metadata!['modelId'], equals('test-face-detector'));
    });

    // --- Edge cases ---

    test('constructor with default values works', () {
      final defaultAdapter = MediaPipeAdapter();
      expect(defaultAdapter.modelId, equals('mediapipe-model'));
      expect(defaultAdapter.taskType, equals(MediaPipeTaskType.faceDetection));
    });

    test('all task types work', () async {
      for (final taskType in MediaPipeTaskType.values) {
        final testAdapter = MediaPipeAdapter(
          taskType: taskType,
          modelId: 'test-$taskType',
        );
        final output = await testAdapter.runInference(AIInput(text: 'test'));
        expect(output.text, isNotEmpty);
      }
    });
  });
}
