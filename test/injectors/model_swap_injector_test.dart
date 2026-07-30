import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('ModelSwapInjector', () {
    late ModelSwapInjector injector;
    late MockAdapter model;

    setUp(() {
      model = MockAdapter(modelId: 'test-model');
      injector = ModelSwapInjector(
        model: model,
        initialQuality: 1.0,
        qualityDegradation: 0.1,
        qualityThreshold: 0.3,
      );
    });

    test('type is FaultType.modelSwap', () {
      expect(injector.type, equals(FaultType.modelSwap));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
    });

    test('description contains parameters', () {
      expect(injector.description, contains('0.1'));
      expect(injector.description, contains('0.3'));
    });

    test('currentQuality starts at initialQuality', () {
      expect(injector.currentQuality, equals(1.0));
    });

    test('isDegraded starts as false', () {
      expect(injector.isDegraded, isFalse);
    });

    test('inject() reduces quality', () async {
      await injector.inject();
      expect(injector.currentQuality, closeTo(0.9, 0.0001));
      expect(injector.qualityHistory, hasLength(1));
    });

    test('multiple injections reduce quality cumulatively', () async {
      for (var i = 0; i < 3; i++) {
        await injector.inject();
      }
      expect(injector.currentQuality, closeTo(0.7, 0.0001));
      expect(injector.qualityHistory, hasLength(3));
    });

    test('inject() marks degraded when quality < threshold', () async {
      // 7 injections: 1.0 - 7*0.1 = 0.3 (not degraded, equal to threshold)
      for (var i = 0; i < 7; i++) {
        await injector.inject();
      }
      expect(injector.isDegraded, isFalse);
      // 8th injection: 0.2 < 0.3
      await injector.inject();
      expect(injector.isDegraded, isTrue);
    });

    test('reset() restores quality and clears state', () async {
      for (var i = 0; i < 8; i++) {
        await injector.inject();
      }
      expect(injector.currentQuality, lessThan(0.3));
      expect(injector.isDegraded, isTrue);

      await injector.reset();
      expect(injector.currentQuality, equals(1.0));
      expect(injector.isDegraded, isFalse);
      expect(injector.qualityHistory, isEmpty);
    });

    test('inject() simulates memory pressure', () async {
      final initialMemory = model.currentMemoryMB;
      await injector.inject();
      expect(model.currentMemoryMB, greaterThan(initialMemory));
    });

    test('inject() marks model as degraded on MockAdapter', () async {
      // Degrades model by exceeding memory limit (150MB) on MockAdapter.
      // Quality goes: 0.9 (10MB) -> 0.8 (20MB) -> ... -> 0.2 (80MB + 20MB) = 100MB.
      // Apply enough injections to push MockAdapter past 150MB:
      for (var i = 0; i < 12; i++) {
        await injector.inject();
      }
      expect(model.isDegraded, isTrue);
    });

    test('getStatus() returns correct string', () {
      expect(injector.getStatus(), contains('Healthy'));
      expect(injector.getStatus(), contains('100%'));
    });

    test('constructor assertions work', () {
      expect(
        () => ModelSwapInjector(model: model, initialQuality: -0.1),
        throwsAssertionError,
      );
      expect(
        () => ModelSwapInjector(model: model, qualityDegradation: 0.0),
        throwsAssertionError,
      );
      expect(
        () => ModelSwapInjector(model: model, qualityThreshold: 1.5),
        throwsAssertionError,
      );
    });
  });
}
