import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:sate_ai/sate_ai.dart';

import 'tflite_adapter_test.mocks.dart';

@GenerateMocks([Interpreter])
void main() {
  group('TFLiteAdapter', () {
    late TFLiteAdapter adapter;
    late MockInterpreter mockInterpreter;

    setUp(() {
      mockInterpreter = MockInterpreter();
      adapter = TFLiteAdapter(
        modelId: 'test-tflite-model',
        interpreter: mockInterpreter,
      );
    });

    test('modelId is correctly set', () {
      expect(adapter.modelId, equals('test-tflite-model'));
    });

    test('currentMemoryMB starts at 0', () {
      expect(adapter.currentMemoryMB, equals(0.0));
    });

    test('isDegraded starts as false', () {
      expect(adapter.isDegraded, isFalse);
    });

    test('isHealthy starts as true', () async {
      expect(await adapter.isHealthy(), isTrue);
    });

    test('simulateMemoryPressure increases memory usage', () async {
      await adapter.simulateMemoryPressure(50);
      expect(adapter.currentMemoryMB, equals(50.0));
      expect(await adapter.isHealthy(), isTrue);
    });

    test('exceeding memory pressure threshold degrades adapter', () async {
      await adapter.simulateMemoryPressure(160);
      expect(adapter.currentMemoryMB, equals(160.0));
      expect(adapter.isDegraded, isTrue);
      expect(await adapter.isHealthy(), isFalse);
    });

    test('reset restores default state', () async {
      await adapter.simulateMemoryPressure(160);
      expect(adapter.isDegraded, isTrue);

      await adapter.reset();
      expect(adapter.currentMemoryMB, equals(0.0));
      expect(adapter.isDegraded, isFalse);
      expect(await adapter.isHealthy(), isTrue);
    });

    test('runInference returns correct output and respects degradation',
        () async {
      final input = AIInput(text: 'hello');
      final output = await adapter.runInference(input);
      expect(output.text, contains('TFLite output: hello'));
      expect(output.confidence, closeTo(0.9, 0.01));

      await adapter.simulateMemoryPressure(160);
      expect(
        () => adapter.runInference(input),
        throwsA(isA<AIInferenceError>()),
      );
    });

    test('dispose closes interpreter instance', () {
      adapter.dispose();
      verify(mockInterpreter.close()).called(1);
    });
  });
}
