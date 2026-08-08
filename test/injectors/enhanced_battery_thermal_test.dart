import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('Enhanced ThermalThrottleInjector (with battery)', () {
    late ThermalThrottleInjector injector;
    late MockAdapter model;

    setUp(() {
      model = MockAdapter(modelId: 'test-model');
      injector = ThermalThrottleInjector(
        model: model,
        temperatureStep: 10,
        maxTemperature: 85,
        batteryThreshold: 20,
        batteryDropStep: 10.0,
        throttledDelayMs: 10,
        extraDelayMs: 20,
      );
    });

    test('initial battery level is 100', () {
      expect(injector.batteryLevel, equals(100));
      expect(injector.isBatteryLow, isFalse);
    });

    test('inject decreases battery level', () async {
      await injector.inject();
      expect(injector.batteryLevel, equals(90));
    });

    test('battery becomes low when below threshold', () async {
      // After 9 injections: 100 - 9*10 = 10 (<=20)
      for (var i = 0; i < 9; i++) {
        await injector.inject();
      }
      expect(injector.batteryLevel, equals(10));
      expect(injector.isBatteryLow, isTrue);
    });

    test('throttling triggers on battery low even if temperature low', () async {
      final lowBatteryModel = MockAdapter(modelId: 'low-battery-model');
      // Create injector with high maxTemperature so temperature doesn't trigger thermal throttle
      final lowBatteryInjector = ThermalThrottleInjector(
        model: lowBatteryModel,
        temperatureStep: 5,
        maxTemperature: 200,
        batteryThreshold: 30,
        batteryDropStep: 15.0,
        throttledDelayMs: 10,
        extraDelayMs: 10,
      );
      // After 5 injections: 100 - 5*15 = 25 <=30, battery low, temp=25+5*5=50 (<<200)
      for (var i = 0; i < 5; i++) {
        await lowBatteryInjector.inject();
      }
      expect(lowBatteryInjector.isBatteryLow, isTrue);
      expect(lowBatteryInjector.isThrottling, isTrue);
    });

    test('reset restores battery', () async {
      await injector.inject(); // battery drops to 90
      expect(injector.batteryLevel, equals(90));
      await injector.reset();
      expect(injector.batteryLevel, equals(100));
      expect(injector.isBatteryLow, isFalse);
    });

    test('applyTo adds extra memory pressure when battery low', () async {
      // Force battery low by multiple injections
      for (var i = 0; i < 8; i++) {
        await injector.applyTo(model);
      }
      expect(injector.isBatteryLow, isTrue);
      final initialMemory = model.currentMemoryMB;
      await injector.applyTo(model);
      // After applyTo, memory pressure includes extra 30 for low battery + 20 for throttling + temperature-based
      expect(model.currentMemoryMB, greaterThan(initialMemory + 40));
    });

    test('isDegraded returns true when battery is low or throttling', () async {
      expect(injector.isDegraded, isFalse);
      for (var i = 0; i < 9; i++) {
        await injector.inject();
      }
      expect(injector.isDegraded, isTrue);
    });

    test('getStatus includes battery level in output', () async {
      await injector.inject();
      expect(injector.getStatus(), contains('battery: 90%'));
    });
  });
}
