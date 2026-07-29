import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('QuantizationDriftInjector', () {
    late QuantizationDriftInjector injector;
    late MockAdapter model;

    setUp(() {
      injector = QuantizationDriftInjector(
        driftFactor: 0.1,
        degradationThreshold: 0.3,
      );
      model = MockAdapter(modelId: 'test-model');
    });

    // --- Basic interface tests ---

    test('type is FaultType.quantizationDrift', () {
      expect(injector.type, equals(FaultType.quantizationDrift));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
    });

    test('description is non-empty and contains driftFactor', () {
      expect(injector.description, contains('0.1'));
      expect(injector.description, isNotEmpty);
    });

    // --- Initial state tests ---

    test('currentConfidence starts at 1.0', () {
      expect(injector.currentConfidence, equals(1.0));
    });

    test('driftSteps starts at 0', () {
      expect(injector.driftSteps, equals(0));
    });

    test('isDegraded starts as false', () {
      expect(injector.isDegraded, isFalse);
    });

    test('confidenceHistory starts empty', () {
      expect(injector.confidenceHistory, isEmpty);
    });

    // --- Injection tests ---

    test('inject() reduces confidence by driftFactor', () async {
      await injector.inject();
      expect(injector.currentConfidence, equals(0.9));
    });

    test('inject() adds to confidenceHistory', () async {
      await injector.inject();
      expect(injector.confidenceHistory, hasLength(1));
      expect(injector.confidenceHistory[0], equals(0.9));
    });

    test('multiple injections reduce confidence cumulatively', () async {
      for (var i = 0; i < 3; i++) {
        await injector.inject();
      }
      expect(injector.currentConfidence, closeTo(0.7, 0.0001));
      expect(injector.confidenceHistory, hasLength(3));
      expect(injector.confidenceHistory[2], closeTo(0.7, 0.0001));
    });

    test('inject() does not go below 0.0', () async {
      // Inject 15 times (1.0 - 15*0.1 = -0.5, should clamp to 0)
      for (var i = 0; i < 15; i++) {
        await injector.inject();
      }
      expect(injector.currentConfidence, equals(0.0));
      expect(injector.isDegraded, isTrue);
    });

    test('inject() is degraded after 7 injections (threshold 0.3)', () async {
      // 7 injections: 1.0 - 7*0.1 = 0.3 (not degraded, equal to threshold)
      for (var i = 0; i < 7; i++) {
        await injector.inject();
      }
      expect(injector.isDegraded, isFalse); // 0.3 is not < 0.3

      // 8th injection: 0.2 < 0.3, degraded
      await injector.inject();
      expect(injector.isDegraded, isTrue);
    });

    // --- Reset tests ---

    test('reset() restores confidence to 1.0', () async {
      await injector.inject();
      await injector.inject();
      expect(injector.currentConfidence, equals(0.8));

      await injector.reset();
      expect(injector.currentConfidence, equals(1.0));
    });

    test('reset() clears confidenceHistory', () async {
      await injector.inject();
      await injector.inject();
      expect(injector.confidenceHistory, hasLength(2));

      await injector.reset();
      expect(injector.confidenceHistory, isEmpty);
    });

    test('reset() resets isDegraded to false', () async {
      for (var i = 0; i < 10; i++) {
        await injector.inject();
      }
      expect(injector.isDegraded, isTrue);

      await injector.reset();
      expect(injector.isDegraded, isFalse);
    });

    // --- ApplyTo model tests ---

    test('applyTo() simulates memory pressure on model', () async {
      final initialMemory = model.currentMemoryMB;
      await injector.applyTo(model);
      expect(model.currentMemoryMB, greaterThan(initialMemory));
    });

    test('applyTo() marks model as degraded after enough drift', () async {
      // Apply drift until degraded
      // Each applyTo adds 10MB memory pressure (driftFactor * 100 = 10)
      // Degradation threshold is 150MB, so after 16 applications: 160MB
      for (var i = 0; i < 16; i++) {
        await injector.applyTo(model);
      }
      expect(model.isDegraded, isTrue);
    });

    test('applyTo() does not degrade model below threshold', () async {
      // 5 applications: 50MB < 150MB threshold
      for (var i = 0; i < 5; i++) {
        await injector.applyTo(model);
      }
      expect(model.isDegraded, isFalse);
    });

    test('works with custom driftFactor and threshold', () async {
      final customInjector = QuantizationDriftInjector(
        driftFactor: 0.05,
        degradationThreshold: 0.5,
      );
      // 10 injections: 1.0 - 10*0.05 = 0.5000000000000001 (which is > 0.5, so isDegraded is false)
      for (var i = 0; i < 10; i++) {
        await customInjector.inject();
      }
      expect(customInjector.currentConfidence, closeTo(0.5, 0.0001));

      // 11th injection: 0.45 < 0.5, degraded
      await customInjector.inject();
      expect(customInjector.currentConfidence, closeTo(0.45, 0.0001));
      expect(customInjector.isDegraded, isTrue);
    });

    // --- Status tests ---

    test('getStatus() returns correct status string', () async {
      // Healthy status
      expect(injector.getStatus(), contains('Healthy'));
      expect(injector.getStatus(), contains('100%'));

      // Degrade and check status
      for (var i = 0; i < 8; i++) {
        await injector.inject();
      }
      expect(injector.getStatus(), contains('DEGRADED'));
      expect(injector.getStatus(), contains('20%'));
    });

    // --- Assertion tests ---

    test('constructor throws assertion for invalid driftFactor', () {
      expect(
        () => QuantizationDriftInjector(driftFactor: -0.1),
        throwsAssertionError,
      );
      expect(
        () => QuantizationDriftInjector(driftFactor: 1.5),
        throwsAssertionError,
      );
    });

    test('constructor throws assertion for invalid degradationThreshold', () {
      expect(
        () => QuantizationDriftInjector(degradationThreshold: -0.1),
        throwsAssertionError,
      );
      expect(
        () => QuantizationDriftInjector(degradationThreshold: 1.5),
        throwsAssertionError,
      );
    });
  });
}
