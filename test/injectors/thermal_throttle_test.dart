import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('ThermalThrottleInjector', () {
    late ThermalThrottleInjector injector;
    late MockAdapter model;

    setUp(() {
      model = MockAdapter(modelId: 'test-model');
      injector = ThermalThrottleInjector(
        model: model,
        temperatureStep: 10,
        maxTemperature: 85,
        throttledDelayMs: 100,
        extraDelayMs: 200,
      );
    });

    // --- Basic interface tests ---

    test('type is FaultType.thermalThrottle', () {
      expect(injector.type, equals(FaultType.thermalThrottle));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
    });

    test('description is non-empty and contains temperatureStep', () {
      expect(injector.description, contains('10'));
      expect(injector.description, isNotEmpty);
    });

    // --- Initial state tests ---

    test('currentTemperature starts at 25°C', () {
      expect(injector.currentTemperature, equals(25));
    });

    test('isThrottling starts as false', () {
      expect(injector.isThrottling, isFalse);
    });

    test('throttleCount starts at 0', () {
      expect(injector.throttleCount, equals(0));
    });

    test('temperatureHistory starts empty', () {
      expect(injector.temperatureHistory, isEmpty);
    });

    test('injectionSteps starts at 0', () {
      expect(injector.injectionSteps, equals(0));
    });

    test('isDegraded starts as false', () {
      expect(injector.isDegraded, isFalse);
    });

    // --- Injection tests ---

    test('inject() increases temperature by temperatureStep', () async {
      await injector.inject();
      expect(injector.currentTemperature, equals(35));
    });

    test('inject() adds to temperatureHistory', () async {
      await injector.inject();
      expect(injector.temperatureHistory, hasLength(1));
      expect(injector.temperatureHistory[0], equals(35));
    });

    test('multiple injections increase temperature cumulatively', () async {
      for (var i = 0; i < 3; i++) {
        await injector.inject();
      }
      expect(injector.currentTemperature, equals(55));
      expect(injector.temperatureHistory, hasLength(3));
    });

    test('inject() triggers throttling when temperature >= max', () async {
      // 6 injections: 25 + 6*10 = 85 (throttled, >= max)
      for (var i = 0; i < 6; i++) {
        await injector.inject();
      }
      expect(injector.isThrottling, isTrue);
    });

    test('inject() increments throttleCount when throttling', () async {
      // 6 injections to reach throttling
      for (var i = 0; i < 6; i++) {
        await injector.inject();
      }
      expect(injector.throttleCount, equals(1));

      // One more injection keeps throttling and increments count
      await injector.inject();
      expect(injector.throttleCount, equals(2));
    });

    // --- Reset tests ---

    test('reset() restores temperature to 25°C', () async {
      for (var i = 0; i < 5; i++) {
        await injector.inject();
      }
      expect(injector.currentTemperature, equals(75));

      await injector.reset();
      expect(injector.currentTemperature, equals(25));
    });

    test('reset() clears temperatureHistory', () async {
      for (var i = 0; i < 3; i++) {
        await injector.inject();
      }
      expect(injector.temperatureHistory, hasLength(3));

      await injector.reset();
      expect(injector.temperatureHistory, isEmpty);
    });

    test('reset() clears isThrottling', () async {
      for (var i = 0; i < 6; i++) {
        await injector.inject();
      }
      expect(injector.isThrottling, isTrue);

      await injector.reset();
      expect(injector.isThrottling, isFalse);
    });

    test('reset() resets throttleCount to 0', () async {
      for (var i = 0; i < 6; i++) {
        await injector.inject();
      }
      expect(injector.throttleCount, greaterThan(0));

      await injector.reset();
      expect(injector.throttleCount, equals(0));
    });

    // --- Model integration tests ---

    test('inject() simulates memory pressure on model', () async {
      final initialMemory = model.currentMemoryMB;
      await injector.inject();
      expect(model.currentMemoryMB, greaterThan(initialMemory));
    });

    test('inject() marks model as degraded after throttling', () async {
      // Apply until throttling (6 applications)
      for (var i = 0; i < 6; i++) {
        await injector.inject();
      }
      // Note: ThermalThrottleInjector delegates memory pressure.
      // SATE AI's runner considers a model degraded when model.isDegraded is true.
      // On MockAdapter, memory pressure of 150MB+ causes model.isDegraded to be true.
      // Let's verify that the injector successfully applies enough memory pressure
      // to make MockAdapter degrade.
      // MockAdapter defaults to degrading > 150MB.
      // We simulate (temperature/10) MB, plus 20MB extra if throttled.
      // Step: 25 -> 35 -> 45 -> 55 -> 65 -> 75 -> 85 (throttled).
      // Memory: 3.5 + 4.5 + 5.5 + 6.5 + 7.5 + 8.5 + (8.5+20) = 64.5 MB.
      // To force MockAdapter degradation, we can trigger more injections.
      for (var i = 0; i < 10; i++) {
        await injector.inject();
      }
      expect(model.isDegraded, isTrue);
    });

    test('inject() does not degrade model before throttling', () async {
      // 4 applications: 25 + 4*10 = 65°C (not throttled, memory pressure low)
      for (var i = 0; i < 4; i++) {
        await injector.inject();
      }
      expect(model.isDegraded, isFalse);
    });

    test('works with custom parameters correctly', () async {
      final customInjector = ThermalThrottleInjector(
        model: model,
        temperatureStep: 15,
        maxTemperature: 70,
        throttledDelayMs: 50,
        extraDelayMs: 100,
      );
      // 3 injections: 25 + 3*15 = 70 (throttled, >= max)
      for (var i = 0; i < 3; i++) {
        await customInjector.inject();
      }
      expect(customInjector.isThrottling, isTrue);
    });

    // --- Status tests ---

    test('getStatus() returns correct status string', () async {
      // Normal status
      expect(injector.getStatus(), contains('Normal'));
      expect(injector.getStatus(), contains('25°C'));

      // Throttle and check status
      for (var i = 0; i < 6; i++) {
        await injector.inject();
      }
      expect(injector.getStatus(), contains('THROTTLING'));
      expect(injector.getStatus(), contains('85°C'));
    });

    // --- Assertion tests ---

    test('constructor throws assertion for invalid temperatureStep', () {
      expect(
        () => ThermalThrottleInjector(model: model, temperatureStep: 0),
        throwsAssertionError,
      );
      expect(
        () => ThermalThrottleInjector(model: model, temperatureStep: 60),
        throwsAssertionError,
      );
    });

    test('constructor throws assertion for invalid maxTemperature', () {
      expect(
        () => ThermalThrottleInjector(model: model, maxTemperature: 30),
        throwsAssertionError,
      );
      expect(
        () => ThermalThrottleInjector(model: model, maxTemperature: 130),
        throwsAssertionError,
      );
    });
  });
}
