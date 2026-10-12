import 'dart:async';
import 'dart:math';

import '../adapters/model_adapter.dart';
import '../core/fault_injector.dart';
import '../core/fault_type.dart';
import '../core/resource_telemetry.dart';

/// An adaptive fault injector that dynamically modulates fault injection
/// intensity and intervals based on live device CPU, RAM, and thermal readings.
///
/// Rather than applying static allocations that might trigger sudden unrecoverable
/// OS hard-kills, the [AdaptiveChaosInjector] monitors real-time resource headroom
/// and scales injection intensity up or down accordingly.
class AdaptiveChaosInjector implements FaultInjector {
  /// Creates an [AdaptiveChaosInjector].
  AdaptiveChaosInjector({
    required this.model,
    ResourceMonitor? monitor,
    this.baseAllocationMB = 50,
    this.maxAllocationMB = 250,
    this.minAllocationMB = 10,
    this.baseInterval = const Duration(milliseconds: 100),
    this.maxInterval = const Duration(milliseconds: 1000),
    this.minInterval = const Duration(milliseconds: 20),
    this.headroomThresholdRatio = 0.20,
    this.criticalHeadroomRatio = 0.05,
    this.onTelemetrySampled,
  }) : monitor = monitor ?? const SystemResourceMonitor();

  /// The model adapter to stress.
  final AIModelAdapter model;

  /// Monitor provider for sampling live system metrics.
  final ResourceMonitor monitor;

  /// Nominal memory allocation applied when headroom is normal.
  final int baseAllocationMB;

  /// Upper bound memory allocation applied under abundant headroom.
  final int maxAllocationMB;

  /// Lower bound memory allocation applied under low headroom.
  final int minAllocationMB;

  /// Baseline interval between successive stress cycles.
  final Duration baseInterval;

  /// Maximum backed-off interval under resource constraints.
  final Duration maxInterval;

  /// Minimum rapid interval under high resource headroom.
  final Duration minInterval;

  /// Headroom ratio threshold below which throttling begins (default: 20%).
  final double headroomThresholdRatio;

  /// Critical headroom ratio below which emergency backoff engages (default: 5%).
  final double criticalHeadroomRatio;

  /// Optional callback invoked when a telemetry sample is evaluated.
  final void Function(
          ResourceTelemetry telemetry, int appliedMB, Duration appliedInterval)?
      onTelemetrySampled;

  final List<ResourceTelemetry> _telemetryHistory = [];
  int _lastAppliedMB = 0;
  Duration _lastAppliedInterval = Duration.zero;
  bool _isThrottled = false;
  bool _isEmergencyBackedOff = false;

  /// Recorded history of all sampled telemetry observations.
  List<ResourceTelemetry> get telemetryHistory =>
      List.unmodifiable(_telemetryHistory);

  /// Last memory allocation in MB applied during the most recent [inject].
  int get lastAppliedMB => _lastAppliedMB;

  /// Last interval calculated during the most recent [inject].
  Duration get lastAppliedInterval => _lastAppliedInterval;

  /// Whether the injector is currently throttling down due to resource pressure.
  bool get isThrottled => _isThrottled;

  /// Whether the injector entered emergency safety backoff mode.
  bool get isEmergencyBackedOff => _isEmergencyBackedOff;

  @override
  FaultType get type => FaultType.adaptiveChaos;

  @override
  String get name => 'Adaptive Chaos Injector';

  @override
  String get description =>
      'Dynamically scales injection intensity and intervals based on live CPU, RAM, and thermal telemetry.';

  /// Calculates dynamic allocation intensity in MB and interval based on [telemetry].
  ({int allocationMB, Duration interval, bool throttled, bool emergency})
      calculatePacing(ResourceTelemetry telemetry) {
    // 1. Critical state: Thermal critical or memory headroom < 5%
    if (telemetry.thermalState == ThermalState.critical ||
        telemetry.memoryHeadroomRatio <= criticalHeadroomRatio) {
      return (
        allocationMB: minAllocationMB,
        interval: maxInterval,
        throttled: true,
        emergency: true,
      );
    }

    // 2. High stress / thermal throttling: Thermal serious or headroom < threshold (e.g. 20%)
    if (telemetry.thermalState == ThermalState.serious ||
        telemetry.memoryHeadroomRatio < headroomThresholdRatio ||
        telemetry.cpuLoadPercentage > 85.0) {
      // Scale down allocation proportionally to remaining headroom
      final factor =
          max(0.1, telemetry.memoryHeadroomRatio / headroomThresholdRatio);
      final scaledMB = (baseAllocationMB * factor)
          .round()
          .clamp(minAllocationMB, baseAllocationMB);
      final scaledIntervalMs = (baseInterval.inMilliseconds * (1.0 / factor))
          .round()
          .clamp(baseInterval.inMilliseconds, maxInterval.inMilliseconds);

      return (
        allocationMB: scaledMB,
        interval: Duration(milliseconds: scaledIntervalMs),
        throttled: true,
        emergency: false,
      );
    }

    // 3. Mild throttling: Thermal fair
    if (telemetry.thermalState == ThermalState.fair) {
      final scaledMB = (baseAllocationMB * 0.75)
          .round()
          .clamp(minAllocationMB, baseAllocationMB);
      final scaledInterval =
          Duration(milliseconds: (baseInterval.inMilliseconds * 1.5).round());
      return (
        allocationMB: scaledMB,
        interval: scaledInterval,
        throttled: true,
        emergency: false,
      );
    }

    // 4. Abundant headroom (>50% free RAM, low CPU): Scale up aggression
    if (telemetry.memoryHeadroomRatio > 0.50 &&
        telemetry.cpuLoadPercentage < 50.0) {
      final headroomBoost =
          ((telemetry.memoryHeadroomRatio - 0.50) * 2.0).clamp(0.0, 1.0);
      final allocMin = min(baseAllocationMB, maxAllocationMB);
      final allocMax = max(baseAllocationMB, maxAllocationMB);
      final boostMB = (baseAllocationMB +
              (maxAllocationMB - baseAllocationMB) * headroomBoost)
          .round()
          .clamp(allocMin, allocMax);

      final lowerIntervalMs =
          min(minInterval.inMilliseconds, baseInterval.inMilliseconds);
      final upperIntervalMs =
          max(minInterval.inMilliseconds, baseInterval.inMilliseconds);
      final boostIntervalMs = (baseInterval.inMilliseconds -
              (baseInterval.inMilliseconds - lowerIntervalMs) * headroomBoost)
          .round()
          .clamp(lowerIntervalMs, upperIntervalMs);

      return (
        allocationMB: boostMB,
        interval: Duration(milliseconds: boostIntervalMs),
        throttled: false,
        emergency: false,
      );
    }

    // 5. Standard nominal condition
    return (
      allocationMB: baseAllocationMB,
      interval: baseInterval,
      throttled: false,
      emergency: false,
    );
  }

  @override
  Future<void> inject() async {
    final telemetry = await monitor.sample();
    _telemetryHistory.add(telemetry);

    final pacing = calculatePacing(telemetry);
    _lastAppliedMB = pacing.allocationMB;
    _lastAppliedInterval = pacing.interval;
    _isThrottled = pacing.throttled;
    _isEmergencyBackedOff = pacing.emergency;

    onTelemetrySampled?.call(telemetry, _lastAppliedMB, _lastAppliedInterval);

    // Apply simulated memory pressure scaled to device capacity
    await model.simulateMemoryPressure(_lastAppliedMB);

    // Sleep for the calculated pacing duration to mimic adaptive injection rate
    if (_lastAppliedInterval > Duration.zero) {
      await Future<void>.delayed(_lastAppliedInterval);
    }
  }

  @override
  Future<void> reset() async {
    _telemetryHistory.clear();
    _lastAppliedMB = 0;
    _lastAppliedInterval = Duration.zero;
    _isThrottled = false;
    _isEmergencyBackedOff = false;
    await model.reset();
  }
}
