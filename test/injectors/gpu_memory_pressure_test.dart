import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:sate_ai/sate_ai.dart';

class _StubOrtSession implements OrtSession {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('GpuMemoryPressureInjector', () {
    late GpuMemoryPressureInjector injector;
    late MockAdapter model;

    setUp(() {
      injector = GpuMemoryPressureInjector(limitMb: 100);
      model = MockAdapter(modelId: 'test-model');
    });

    test('type is FaultType.gpuMemoryPressure', () {
      expect(injector.type, equals(FaultType.gpuMemoryPressure));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
      expect(injector.name, contains('GPU Memory Pressure'));
    });

    test('description contains limitMb', () {
      expect(injector.description, contains('100'));
    });

    test('applyTo increases GPU memory', () async {
      expect(model.currentGPUMemoryMB, equals(0.0));
      await injector.applyTo(model);
      expect(model.currentGPUMemoryMB, equals(100.0));
    });

    test('applyTo with limitMb > 150 degrades model', () async {
      final highInjector = GpuMemoryPressureInjector(limitMb: 160);
      await highInjector.applyTo(model);
      expect(model.currentGPUMemoryMB, equals(160.0));
      expect(model.isDegraded, isTrue);
    });

    test('reset clears GPU memory', () async {
      await injector.applyTo(model);
      expect(model.currentGPUMemoryMB, greaterThan(0));
      await model.reset();
      expect(model.currentGPUMemoryMB, equals(0.0));
      expect(model.isDegraded, isFalse);
    });

    test('works with OnnxAdapter (simulation)', () async {
      final onnxModel = OnnxAdapter(
        modelBytes: Uint8List(0),
        modelId: 'test-onnx',
        sessionFactory: (_) => _StubOrtSession(),
      );
      final inj = GpuMemoryPressureInjector(limitMb: 50);
      await inj.applyTo(onnxModel);
      expect(onnxModel.currentGPUMemoryMB, equals(50.0));
    });

    test('inject and reset interfaces do not throw', () async {
      await injector.inject();
      await injector.reset();
    });
  });
}
