import 'dart:io';

/// Device thermal state indicating temperature throttling status.
enum ThermalState {
  /// Normal device temperature; no throttling active.
  nominal,

  /// Device is slightly elevated in temperature; mild throttling may occur.
  fair,

  /// High device temperature; aggressive CPU/GPU throttling is active.
  serious,

  /// Critical thermal overload; device may shut down or abort tasks.
  critical,
}

/// Snapshot of live system resource telemetry.
class ResourceTelemetry {
  /// Creates a [ResourceTelemetry] snapshot.
  const ResourceTelemetry({
    required this.availableMemoryMB,
    required this.totalMemoryMB,
    required this.cpuLoadPercentage,
    required this.thermalState,
    required this.timestamp,
  });

  /// Available system memory in megabytes (MB).
  final double availableMemoryMB;

  /// Total system memory in megabytes (MB).
  final double totalMemoryMB;

  /// Estimated CPU load percentage in range 0.0 to 100.0.
  final double cpuLoadPercentage;

  /// Current device thermal state.
  final ThermalState thermalState;

  /// Wall-clock timestamp when this telemetry was sampled.
  final DateTime timestamp;

  /// Proportion of free memory available in range 0.0 to 1.0.
  double get memoryHeadroomRatio =>
      totalMemoryMB > 0 ? (availableMemoryMB / totalMemoryMB).clamp(0.0, 1.0) : 0.5;

  /// Whether current telemetry indicates dangerous resource depletion.
  bool get isCritical =>
      thermalState == ThermalState.critical || memoryHeadroomRatio < 0.05;

  /// Whether current telemetry suggests throttling down stress intensity.
  bool get shouldThrottle =>
      thermalState == ThermalState.serious ||
      thermalState == ThermalState.critical ||
      memoryHeadroomRatio < 0.20 ||
      cpuLoadPercentage > 85.0;

  /// Deserializes a [ResourceTelemetry] from a JSON map.
  factory ResourceTelemetry.fromJson(Map<String, dynamic> json) {
    return ResourceTelemetry(
      availableMemoryMB: (json['availableMemoryMB'] as num).toDouble(),
      totalMemoryMB: (json['totalMemoryMB'] as num).toDouble(),
      cpuLoadPercentage: (json['cpuLoadPercentage'] as num).toDouble(),
      thermalState: ThermalState.values.firstWhere(
        (e) => e.name == json['thermalState'],
        orElse: () => ThermalState.nominal,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Serializes this [ResourceTelemetry] to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'availableMemoryMB': availableMemoryMB,
        'totalMemoryMB': totalMemoryMB,
        'cpuLoadPercentage': cpuLoadPercentage,
        'thermalState': thermalState.name,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'ResourceTelemetry(mem: ${availableMemoryMB.toStringAsFixed(1)}/${totalMemoryMB.toStringAsFixed(1)}MB, '
      'cpu: ${cpuLoadPercentage.toStringAsFixed(1)}%, thermal: ${thermalState.name})';
}

/// Abstract provider interface for querying live device resource metrics.
abstract class ResourceMonitor {
  /// Samples the current device resource metrics.
  Future<ResourceTelemetry> sample();
}

/// Default cross-platform system monitor that queries Dart runtime memory info.
class SystemResourceMonitor implements ResourceMonitor {
  /// Creates a [SystemResourceMonitor].
  const SystemResourceMonitor({
    this.fallbackTotalMemoryMB = 4096.0,
  });

  /// Total system memory assumption if OS total cannot be directly read.
  final double fallbackTotalMemoryMB;

  @override
  Future<ResourceTelemetry> sample() async {
    // ProcessInfo.currentRss provides resident set size of current process.
    final currentRssBytes = ProcessInfo.currentRss;
    final currentRssMB = currentRssBytes / (1024 * 1024);

    final maxRssBytes = ProcessInfo.maxRss;
    final maxRssMB = maxRssBytes / (1024 * 1024);

    // Compute estimated available memory based on current process footprint
    final estimatedAvailable = (fallbackTotalMemoryMB - currentRssMB).clamp(0.0, fallbackTotalMemoryMB);

    return ResourceTelemetry(
      availableMemoryMB: estimatedAvailable,
      totalMemoryMB: fallbackTotalMemoryMB,
      cpuLoadPercentage: (maxRssMB > 0 ? (currentRssMB / maxRssMB * 100.0) : 25.0).clamp(5.0, 95.0),
      thermalState: ThermalState.nominal,
      timestamp: DateTime.now(),
    );
  }
}
