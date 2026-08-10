import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('DataCorruptionInjector', () {
    late DataCorruptionInjector injector;
    late MockAdapter model;

    setUp(() {
      injector = DataCorruptionInjector(
        corruptionType: DataCorruptionType.gaussianNoise,
        intensity: 0.1,
      );
      model = MockAdapter(modelId: 'test-model');
    });

    // --- Basic interface tests ---

    test('type is FaultType.dataCorruption', () {
      expect(injector.type, equals(FaultType.dataCorruption));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
    });

    test('description contains intensity', () {
      expect(injector.description, contains('0.1'));
    });

    // --- Initial state tests ---

    test('injectionCount starts at 0', () {
      expect(injector.injectionCount, equals(0));
    });

    test('inject increments injectionCount', () async {
      await injector.inject();
      expect(injector.injectionCount, equals(1));
    });

    test('reset resets injectionCount', () async {
      await injector.inject();
      await injector.inject();
      expect(injector.injectionCount, equals(2));
      await injector.reset();
      expect(injector.injectionCount, equals(0));
    });

    // --- applyTo tests ---

    test('applyTo simulates memory pressure', () async {
      final initialMemory = model.currentMemoryMB;
      await injector.applyTo(model);
      expect(model.currentMemoryMB, greaterThan(initialMemory));
    });

    test('applyTo throws error when intensity > 0.6', () async {
      final highIntensityInjector = DataCorruptionInjector(
        corruptionType: DataCorruptionType.gaussianNoise,
        intensity: 0.7,
      );
      await expectLater(
        highIntensityInjector.applyTo(model),
        throwsA(isA<AIInferenceError>()),
      );
    });

    test('applyTo does not throw when intensity <= 0.6', () async {
      final lowIntensityInjector = DataCorruptionInjector(
        corruptionType: DataCorruptionType.gaussianNoise,
        intensity: 0.5,
      );
      // Should not throw
      await lowIntensityInjector.applyTo(model);
      expect(true, isTrue); // If we got here, it passed
    });

    // --- corruptData utility tests ---

    test('corruptData applies Gaussian noise', () {
      final data = [0.5, 0.5, 0.5, 0.5, 0.5];
      final injector = DataCorruptionInjector(
        corruptionType: DataCorruptionType.gaussianNoise,
        intensity: 0.1,
        seed: 42,
      );
      final corrupted = injector.corruptData(data);
      expect(corrupted, isNot(equals(data)));
      // Values should be within bounds
      for (final value in corrupted) {
        expect(value, inInclusiveRange(0.0, 1.0));
      }
    });

    test('corruptData applies blur', () {
      final data = [1.0, 0.0, 1.0, 0.0, 1.0];
      final injector = DataCorruptionInjector(
        corruptionType: DataCorruptionType.blur,
        intensity: 0.3,
      );
      final corrupted = injector.corruptData(data);
      // Blur should smooth the data
      expect(corrupted, isNot(equals(data)));
      expect(corrupted[0], lessThan(1.0));
      expect(corrupted[4], lessThan(1.0));
    });

    test('corruptData applies occlusion', () {
      final data = [1.0, 1.0, 1.0, 1.0, 1.0];
      final injector = DataCorruptionInjector(
        corruptionType: DataCorruptionType.occlusion,
        intensity: 0.4,
        seed: 42,
      );
      final corrupted = injector.corruptData(data);
      expect(corrupted, isNot(equals(data)));
      expect(corrupted.any((v) => v == 0.0), isTrue);
    });

    test('corruptData applies salt & pepper', () {
      final data = [0.5, 0.5, 0.5, 0.5, 0.5];
      final injector = DataCorruptionInjector(
        corruptionType: DataCorruptionType.saltPepper,
        intensity: 0.3,
        seed: 42,
      );
      final corrupted = injector.corruptData(data);
      expect(corrupted, isNot(equals(data)));
      expect(corrupted.any((v) => v == 0.0 || v == 1.0), isTrue);
    });

    test('corruptData applies audio glitch', () {
      final data = List<double>.generate(50, (i) => i * 0.02);
      final injector = DataCorruptionInjector(
        corruptionType: DataCorruptionType.audioGlitch,
        intensity: 0.5,
        seed: 42,
      );
      final corrupted = injector.corruptData(data);
      expect(corrupted, isNot(equals(data)));
    });

    test('constructor asserts valid intensity', () {
      expect(
        () => DataCorruptionInjector(intensity: -0.1),
        throwsAssertionError,
      );
      expect(
        () => DataCorruptionInjector(intensity: 1.1),
        throwsAssertionError,
      );
    });

    test('getStatus returns correct string', () {
      expect(injector.getStatus(), contains('gaussianNoise'));
      expect(injector.getStatus(), contains('0.1'));
    });
  });
}
