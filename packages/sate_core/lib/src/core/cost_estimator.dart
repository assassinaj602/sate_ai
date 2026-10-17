import 'dart:math';

import '../adapters/model_adapter.dart';
import '../injectors/adaptive_chaos_injector.dart';
import '../injectors/gpu_memory_pressure_injector.dart';
import '../injectors/memory_pressure_injector.dart';
import 'fault_injector.dart';

/// Hardware profile specification used to simulate device power and memory limits.
class DeviceHardwareProfile {
  /// Creates a [DeviceHardwareProfile].
  const DeviceHardwareProfile({
    this.name = 'Standard Mobile Device',
    this.batteryCapacityMah = 4000.0,
    this.idleCurrentMa = 120.0,
    this.inferenceCurrentMa = 850.0,
    this.deviceTotalMemoryMb = 4096.0,
  });

  /// Typical modern smartphone profile.
  static const DeviceHardwareProfile mobile = DeviceHardwareProfile(
    name: 'Mobile Phone',
    batteryCapacityMah: 4000.0,
    idleCurrentMa: 120.0,
    inferenceCurrentMa: 850.0,
    deviceTotalMemoryMb: 4096.0,
  );

  /// Low-power embedded/IoT device profile (e.g. Raspberry Pi / Jetson Nano).
  static const DeviceHardwareProfile edgeIoT = DeviceHardwareProfile(
    name: 'Edge IoT / Embedded',
    batteryCapacityMah: 2500.0,
    idleCurrentMa: 250.0,
    inferenceCurrentMa: 1400.0,
    deviceTotalMemoryMb: 2048.0,
  );

  /// High-power tablet/workstation profile.
  static const DeviceHardwareProfile tablet = DeviceHardwareProfile(
    name: 'Tablet / Workstation',
    batteryCapacityMah: 8000.0,
    idleCurrentMa: 180.0,
    inferenceCurrentMa: 1100.0,
    deviceTotalMemoryMb: 8192.0,
  );

  /// Human-readable label for this profile.
  final String name;

  /// Total nominal battery capacity in milliamp-hours (mAh).
  final double batteryCapacityMah;

  /// Baseline idle device current draw in milliamps (mA).
  final double idleCurrentMa;

  /// Peak active current draw in milliamps (mA) under heavy AI inference and fault stress.
  final double inferenceCurrentMa;

  /// Total device system RAM in megabytes (MB).
  final double deviceTotalMemoryMb;

  /// Deserializes from a JSON map.
  factory DeviceHardwareProfile.fromJson(Map<String, dynamic> json) {
    return DeviceHardwareProfile(
      name: json['name'] as String? ?? 'Custom Device',
      batteryCapacityMah: (json['batteryCapacityMah'] as num).toDouble(),
      idleCurrentMa: (json['idleCurrentMa'] as num).toDouble(),
      inferenceCurrentMa: (json['inferenceCurrentMa'] as num).toDouble(),
      deviceTotalMemoryMb: (json['deviceTotalMemoryMb'] as num).toDouble(),
    );
  }

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'batteryCapacityMah': batteryCapacityMah,
        'idleCurrentMa': idleCurrentMa,
        'inferenceCurrentMa': inferenceCurrentMa,
        'deviceTotalMemoryMb': deviceTotalMemoryMb,
      };
}

/// Estimated cost and resource footprint of running a stress test plan.
class StressCostEstimate {
  /// Creates a [StressCostEstimate].
  const StressCostEstimate({
    required this.modelId,
    required this.totalInjectors,
    required this.estimatedDuration,
    required this.estimatedPeakMemoryMB,
    required this.estimatedBatteryDrainMah,
    required this.estimatedBatteryDrainPercent,
    required this.hardwareProfile,
    this.estimatedInferenceCycles = 0,
    this.estimatedTokenCount = 0,
    this.estimatedCloudCostUsd = 0.0,
  });

  /// The model ID being evaluated.
  final String modelId;

  /// Total number of injectors configured.
  final int totalInjectors;

  /// Projected wall-clock duration of the test run.
  final Duration estimatedDuration;

  /// Projected peak memory consumption in megabytes (MB).
  final double estimatedPeakMemoryMB;

  /// Projected battery consumption in milliamp-hours (mAh).
  final double estimatedBatteryDrainMah;

  /// Projected battery drain percentage (0.0 to 100.0).
  final double estimatedBatteryDrainPercent;

  /// Device hardware profile used for calculation.
  final DeviceHardwareProfile hardwareProfile;

  /// Projected total inference invocations.
  final int estimatedInferenceCycles;

  /// Projected token count for language/embedding models.
  final int estimatedTokenCount;

  /// Projected cloud API cost in USD if using hybrid cloud endpoints.
  final double estimatedCloudCostUsd;

  /// Percentage of total device memory that will be consumed at peak.
  double get memoryUsagePercentage => hardwareProfile.deviceTotalMemoryMb > 0
      ? (estimatedPeakMemoryMB / hardwareProfile.deviceTotalMemoryMb * 100.0).clamp(0.0, 100.0)
      : 0.0;

  /// Serializes to a JSON map.
  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'totalInjectors': totalInjectors,
        'estimatedDurationMs': estimatedDuration.inMilliseconds,
        'estimatedPeakMemoryMB': estimatedPeakMemoryMB,
        'memoryUsagePercentage': memoryUsagePercentage,
        'estimatedBatteryDrainMah': estimatedBatteryDrainMah,
        'estimatedBatteryDrainPercent': estimatedBatteryDrainPercent,
        'estimatedInferenceCycles': estimatedInferenceCycles,
        'estimatedTokenCount': estimatedTokenCount,
        'estimatedCloudCostUsd': estimatedCloudCostUsd,
        'hardwareProfile': hardwareProfile.toJson(),
      };

  /// Deserializes from a JSON map.
  factory StressCostEstimate.fromJson(Map<String, dynamic> json) {
    return StressCostEstimate(
      modelId: json['modelId'] as String,
      totalInjectors: json['totalInjectors'] as int,
      estimatedDuration: Duration(milliseconds: json['estimatedDurationMs'] as int),
      estimatedPeakMemoryMB: (json['estimatedPeakMemoryMB'] as num).toDouble(),
      estimatedBatteryDrainMah: (json['estimatedBatteryDrainMah'] as num).toDouble(),
      estimatedBatteryDrainPercent: (json['estimatedBatteryDrainPercent'] as num).toDouble(),
      hardwareProfile: DeviceHardwareProfile.fromJson(json['hardwareProfile'] as Map<String, dynamic>),
      estimatedInferenceCycles: json['estimatedInferenceCycles'] as int? ?? 0,
      estimatedTokenCount: json['estimatedTokenCount'] as int? ?? 0,
      estimatedCloudCostUsd: (json['estimatedCloudCostUsd'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Formats the estimate as a Markdown table report.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# SATE AI Stress Test Cost Estimate');
    buffer.writeln();
    buffer.writeln('**Target Model:** `$modelId`  ');
    buffer.writeln('**Device Profile:** ${hardwareProfile.name}  ');
    buffer.writeln('**Active Injectors:** $totalInjectors  ');
    buffer.writeln();
    buffer.writeln('| Metric | Estimated Cost | Notes |');
    buffer.writeln('|---|---|---|');

    final minutes = estimatedDuration.inMinutes;
    final seconds = estimatedDuration.inSeconds % 60;
    final durationStr = minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
    buffer.writeln('| **Projected Duration** | $durationStr | Wall-clock test time |');
    buffer.writeln(
        '| **Peak Memory Usage** | ${estimatedPeakMemoryMB.toStringAsFixed(1)} MB | ~${memoryUsagePercentage.toStringAsFixed(1)}% of ${hardwareProfile.deviceTotalMemoryMb.toStringAsFixed(0)} MB |');
    buffer.writeln(
        '| **Battery Consumption** | ${estimatedBatteryDrainMah.toStringAsFixed(2)} mAh | ~${estimatedBatteryDrainPercent.toStringAsFixed(2)}% of ${hardwareProfile.batteryCapacityMah.toStringAsFixed(0)} mAh |');
    buffer.writeln('| **Inference Cycles** | $estimatedInferenceCycles | Total test probes |');

    if (estimatedCloudCostUsd > 0.0) {
      buffer.writeln('| **Cloud API Cost** | \$${estimatedCloudCostUsd.toStringAsFixed(4)} | Based on ~$estimatedTokenCount tokens |');
    }

    buffer.writeln();
    if (memoryUsagePercentage > 85.0) {
      buffer.writeln('> ⚠️ **Warning:** Projected peak memory exceeds 85% of total device memory. OOM risk is high.');
      buffer.writeln();
    }
    if (estimatedBatteryDrainPercent > 5.0) {
      buffer.writeln('> 🔋 **Notice:** Projected battery drain exceeds 5%. Ensure test device is connected to power.');
      buffer.writeln();
    }

    return buffer.toString();
  }

  @override
  String toString() =>
      'StressCostEstimate(duration: ${estimatedDuration.inSeconds}s, peakMem: ${estimatedPeakMemoryMB.toStringAsFixed(1)}MB, battery: ${estimatedBatteryDrainPercent.toStringAsFixed(2)}%)';
}

/// Calculator that projects test duration, peak memory, and battery consumption
/// before a stress test is executed.
class CostEstimator {
  /// Creates a [CostEstimator].
  const CostEstimator({
    this.hardwareProfile = DeviceHardwareProfile.mobile,
    this.estimatedInferenceTime = const Duration(milliseconds: 150),
    this.estimatedTokensPerInference = 128,
    this.cloudPricePerMillionTokensUsd = 0.15,
  });

  /// Device hardware profile used to model power and RAM constraints.
  final DeviceHardwareProfile hardwareProfile;

  /// Expected average inference execution duration per probe.
  final Duration estimatedInferenceTime;

  /// Expected token footprint per inference probe for language models.
  final int estimatedTokensPerInference;

  /// Unit price per 1,000,000 tokens for cloud endpoints.
  final double cloudPricePerMillionTokensUsd;

  /// Estimates the resource and time cost for testing [model] with [injectors].
  StressCostEstimate estimate({
    required AIModelAdapter model,
    required List<FaultInjector> injectors,
    Duration timeout = const Duration(seconds: 30),
    int retryCount = 1,
    bool isCloudModel = false,
  }) {
    if (injectors.isEmpty) {
      return StressCostEstimate(
        modelId: model.modelId,
        totalInjectors: 0,
        estimatedDuration: Duration.zero,
        estimatedPeakMemoryMB: model.currentMemoryMB,
        estimatedBatteryDrainMah: 0.0,
        estimatedBatteryDrainPercent: 0.0,
        hardwareProfile: hardwareProfile,
      );
    }

    final attemptsPerInjector = max(1, retryCount);
    final totalInferenceCycles = injectors.length * attemptsPerInjector;

    // 1. Duration Calculation
    // Base time per injector: injection setup/reset overhead + inference duration
    var totalDurationMs = 0;
    for (final injector in injectors) {
      // Default per-injector overhead (setup, settling, reset)
      var perAttemptMs = estimatedInferenceTime.inMilliseconds + 50;

      if (injector is AdaptiveChaosInjector) {
        // Adaptive chaos has internal pacing intervals
        perAttemptMs += injector.baseInterval.inMilliseconds;
      }

      // Bound by timeout to prevent runaway estimates
      final effectiveAttemptMs = min(perAttemptMs, timeout.inMilliseconds);
      totalDurationMs += effectiveAttemptMs * attemptsPerInjector;
    }

    // Add 200ms fixed runner initialization and teardown overhead
    totalDurationMs += 200;
    final estimatedDuration = Duration(milliseconds: totalDurationMs);

    // 2. Peak Memory Calculation
    // Model baseline memory + highest memory pressure applied across all injectors
    final baselineMemory = max(10.0, model.currentMemoryMB);
    var maxInjectorMemoryDelta = 0.0;

    for (final injector in injectors) {
      if (injector is MemoryPressureInjector) {
        maxInjectorMemoryDelta = max(maxInjectorMemoryDelta, injector.limitMb.toDouble());
      } else if (injector is GpuMemoryPressureInjector) {
        maxInjectorMemoryDelta = max(maxInjectorMemoryDelta, injector.limitMb.toDouble());
      } else if (injector is AdaptiveChaosInjector) {
        maxInjectorMemoryDelta = max(maxInjectorMemoryDelta, injector.baseAllocationMB.toDouble());
      } else {
        // Generic non-memory injectors have minimal memory overhead (~15 MB probe buffers)
        maxInjectorMemoryDelta = max(maxInjectorMemoryDelta, 15.0);
      }
    }

    final peakMemoryMB = baselineMemory + maxInjectorMemoryDelta;

    // 3. Battery Consumption Calculation
    // Battery Drain (mAh) = (Current (mA) * Duration (hours))
    final durationHours = totalDurationMs / (1000.0 * 60.0 * 60.0);
    // Weighted current draw: 80% active inference current, 20% idle current
    final avgCurrentMa = (hardwareProfile.inferenceCurrentMa * 0.80) + (hardwareProfile.idleCurrentMa * 0.20);
    final batteryDrainMah = avgCurrentMa * durationHours;

    final batteryDrainPercent = hardwareProfile.batteryCapacityMah > 0
        ? (batteryDrainMah / hardwareProfile.batteryCapacityMah * 100.0)
        : 0.0;

    // 4. Cloud Cost Calculation
    final totalTokens = totalInferenceCycles * estimatedTokensPerInference;
    final cloudCost = isCloudModel
        ? (totalTokens / 1000000.0) * cloudPricePerMillionTokensUsd
        : 0.0;

    return StressCostEstimate(
      modelId: model.modelId,
      totalInjectors: injectors.length,
      estimatedDuration: estimatedDuration,
      estimatedPeakMemoryMB: peakMemoryMB,
      estimatedBatteryDrainMah: batteryDrainMah,
      estimatedBatteryDrainPercent: batteryDrainPercent,
      hardwareProfile: hardwareProfile,
      estimatedInferenceCycles: totalInferenceCycles,
      estimatedTokenCount: totalTokens,
      estimatedCloudCostUsd: cloudCost,
    );
  }
}
