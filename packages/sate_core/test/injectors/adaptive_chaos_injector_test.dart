import 'package:sate_core/sate_core.dart';
import 'package:test/test.dart';

/// Test helper implementing [ResourceMonitor] with configurable telemetry.
class FakeResourceMonitor implements ResourceMonitor {
  FakeResourceMonitor(this.telemetry);

  ResourceTelemetry telemetry;

  @override
  Future<ResourceTelemetry> sample() async => telemetry;
}

void main() {
  group('AdaptiveChaosInjector', () {
    test('initializes with expected default properties', () {
      final model = MockAdapter();
      final injector = AdaptiveChaosInjector(model: model);

      expect(injector.type, equals(FaultType.adaptiveChaos));
      expect(injector.name, equals('Adaptive Chaos Injector'));
      expect(injector.description, contains('live CPU, RAM, and thermal'));
      expect(injector.isThrottled, isFalse);
      expect(injector.isEmergencyBackedOff, isFalse);
      expect(injector.telemetryHistory, isEmpty);
    });

    test('injects aggressively when memory headroom is abundant', () async {
      final model = MockAdapter();
      final monitor = FakeResourceMonitor(ResourceTelemetry(
        availableMemoryMB: 3500,
        totalMemoryMB: 4096,
        cpuLoadPercentage: 20,
        thermalState: ThermalState.nominal,
        timestamp: DateTime.now(),
      ));

      final injector = AdaptiveChaosInjector(
        model: model,
        monitor: monitor,
        baseAllocationMB: 50,
        maxAllocationMB: 200,
        baseInterval: const Duration(milliseconds: 1),
        minInterval: const Duration(milliseconds: 1),
      );

      await injector.inject();

      expect(injector.isThrottled, isFalse);
      expect(injector.isEmergencyBackedOff, isFalse);
      expect(injector.lastAppliedMB, greaterThan(50));
      expect(model.currentMemoryMB, equals(injector.lastAppliedMB.toDouble()));
      expect(injector.telemetryHistory.length, equals(1));
    });

    test('scales back injection intensity when memory headroom is low', () async {
      final model = MockAdapter();
      final monitor = FakeResourceMonitor(ResourceTelemetry(
        availableMemoryMB: 400,
        totalMemoryMB: 4096, // ~9.7% headroom
        cpuLoadPercentage: 45,
        thermalState: ThermalState.nominal,
        timestamp: DateTime.now(),
      ));

      final injector = AdaptiveChaosInjector(
        model: model,
        monitor: monitor,
        baseAllocationMB: 100,
        minAllocationMB: 10,
        baseInterval: const Duration(milliseconds: 1),
      );

      await injector.inject();

      expect(injector.isThrottled, isTrue);
      expect(injector.isEmergencyBackedOff, isFalse);
      expect(injector.lastAppliedMB, lessThan(100));
      expect(injector.lastAppliedMB, greaterThanOrEqualTo(10));
    });

    test('triggers emergency backoff when memory headroom is critically depleted', () async {
      final model = MockAdapter();
      final monitor = FakeResourceMonitor(ResourceTelemetry(
        availableMemoryMB: 100,
        totalMemoryMB: 4096, // ~2.4% headroom
        cpuLoadPercentage: 90,
        thermalState: ThermalState.nominal,
        timestamp: DateTime.now(),
      ));

      final injector = AdaptiveChaosInjector(
        model: model,
        monitor: monitor,
        baseAllocationMB: 100,
        minAllocationMB: 10,
        baseInterval: const Duration(milliseconds: 1),
        maxInterval: const Duration(milliseconds: 2),
      );

      await injector.inject();

      expect(injector.isThrottled, isTrue);
      expect(injector.isEmergencyBackedOff, isTrue);
      expect(injector.lastAppliedMB, equals(10));
    });

    test('throttles when thermal state is serious or critical', () async {
      final model = MockAdapter();
      final monitor = FakeResourceMonitor(ResourceTelemetry(
        availableMemoryMB: 3000,
        totalMemoryMB: 4096,
        cpuLoadPercentage: 50,
        thermalState: ThermalState.critical,
        timestamp: DateTime.now(),
      ));

      final injector = AdaptiveChaosInjector(
        model: model,
        monitor: monitor,
        baseAllocationMB: 80,
        minAllocationMB: 15,
        baseInterval: const Duration(milliseconds: 1),
        maxInterval: const Duration(milliseconds: 2),
      );

      await injector.inject();

      expect(injector.isThrottled, isTrue);
      expect(injector.isEmergencyBackedOff, isTrue);
      expect(injector.lastAppliedMB, equals(15));
    });

    test('modulates pacing under mild thermal fair state', () async {
      final model = MockAdapter();
      final monitor = FakeResourceMonitor(ResourceTelemetry(
        availableMemoryMB: 2000,
        totalMemoryMB: 4096,
        cpuLoadPercentage: 40,
        thermalState: ThermalState.fair,
        timestamp: DateTime.now(),
      ));

      final injector = AdaptiveChaosInjector(
        model: model,
        monitor: monitor,
        baseAllocationMB: 100,
        baseInterval: const Duration(milliseconds: 1),
      );

      await injector.inject();

      expect(injector.isThrottled, isTrue);
      expect(injector.isEmergencyBackedOff, isFalse);
      expect(injector.lastAppliedMB, equals(75)); // 75% of base
    });

    test('recovers to nominal intensity when headroom returns to normal', () async {
      final model = MockAdapter();
      final monitor = FakeResourceMonitor(ResourceTelemetry(
        availableMemoryMB: 200,
        totalMemoryMB: 4096,
        cpuLoadPercentage: 70,
        thermalState: ThermalState.nominal,
        timestamp: DateTime.now(),
      ));

      final injector = AdaptiveChaosInjector(
        model: model,
        monitor: monitor,
        baseAllocationMB: 60,
        minAllocationMB: 10,
        baseInterval: const Duration(milliseconds: 1),
      );

      await injector.inject();
      expect(injector.isThrottled, isTrue);

      // System recovers
      monitor.telemetry = ResourceTelemetry(
        availableMemoryMB: 1500,
        totalMemoryMB: 4096, // ~36% free
        cpuLoadPercentage: 60,
        thermalState: ThermalState.nominal,
        timestamp: DateTime.now(),
      );

      await injector.inject();
      expect(injector.isThrottled, isFalse);
      expect(injector.isEmergencyBackedOff, isFalse);
      expect(injector.lastAppliedMB, equals(60));
    });

    test('resets model and telemetry history properly on reset()', () async {
      final model = MockAdapter();
      final monitor = FakeResourceMonitor(ResourceTelemetry(
        availableMemoryMB: 2000,
        totalMemoryMB: 4096,
        cpuLoadPercentage: 30,
        thermalState: ThermalState.nominal,
        timestamp: DateTime.now(),
      ));

      final injector = AdaptiveChaosInjector(
        model: model,
        monitor: monitor,
        baseInterval: const Duration(milliseconds: 1),
      );

      await injector.inject();
      expect(injector.telemetryHistory.length, equals(1));
      expect(model.currentMemoryMB, greaterThan(0));

      await injector.reset();
      expect(injector.telemetryHistory, isEmpty);
      expect(injector.lastAppliedMB, equals(0));
      expect(model.currentMemoryMB, equals(0.0));
      expect(injector.isThrottled, isFalse);
    });

    test('records telemetry audit log across consecutive cycles', () async {
      final model = MockAdapter();
      final monitor = FakeResourceMonitor(ResourceTelemetry(
        availableMemoryMB: 2000,
        totalMemoryMB: 4096,
        cpuLoadPercentage: 30,
        thermalState: ThermalState.nominal,
        timestamp: DateTime.now(),
      ));

      final samples = <ResourceTelemetry>[];
      final injector = AdaptiveChaosInjector(
        model: model,
        monitor: monitor,
        baseInterval: const Duration(milliseconds: 1),
        onTelemetrySampled: (tel, mb, interval) {
          samples.add(tel);
        },
      );

      await injector.inject();
      await injector.inject();
      await injector.inject();

      expect(injector.telemetryHistory.length, equals(3));
      expect(samples.length, equals(3));
    });

    test('integrates with StressRunner and produces report', () async {
      final model = MockAdapter(
        modelId: 'adaptive-chaos-test-model',
        inferenceDelay: const Duration(milliseconds: 1),
      );
      final monitor = FakeResourceMonitor(ResourceTelemetry(
        availableMemoryMB: 3000,
        totalMemoryMB: 4096,
        cpuLoadPercentage: 25,
        thermalState: ThermalState.nominal,
        timestamp: DateTime.now(),
      ));

      final injector = AdaptiveChaosInjector(
        model: model,
        monitor: monitor,
        baseAllocationMB: 40,
        baseInterval: const Duration(milliseconds: 1),
      );

      final runner = StressRunner(
        model: model,
        injectors: [injector],
      );

      final report = await runner.run();
      expect(report.results.length, equals(1));
      expect(report.results.first.injectorType, equals(FaultType.adaptiveChaos));
      expect(report.passed, isTrue);
    });
  });
}
