/// Types of faults that can be injected into AI model stress tests.
///
/// Each value represents a distinct failure scenario that an on-device AI
/// model may encounter in production.
enum FaultType {
  /// Simulates memory pressure to trigger OOM or degraded performance.
  ///
  /// Relevant for models that allocate large buffers during inference.
  memoryPressure,

  /// Injects malformed, empty, or oversized inputs.
  ///
  /// Tests that the model validates and handles bad inputs gracefully.
  malformedInput,

  /// Simulates artificial latency / performance degradation.
  ///
  /// Useful for testing timeout handling in calling code.
  latency,

  /// Simulates CPU/GPU thermal throttling.
  ///
  /// Models can exhibit 5–10× slower inference when the device is hot.
  thermalThrottle,

  /// Simulates network failures for cloud-dependent model components.
  ///
  /// Relevant for hybrid on-device/cloud inference pipelines.
  networkFailure,

  /// Simulates gradual precision loss / output degradation.
  ///
  /// Tests that the model degrades gracefully rather than crashing.
  quantizationDrift,
}

/// Extension helpers on [FaultType].
extension FaultTypeX on FaultType {
  /// Human-readable display name for UI and reports.
  String get displayName {
    switch (this) {
      case FaultType.memoryPressure:
        return 'Memory Pressure';
      case FaultType.malformedInput:
        return 'Malformed Input';
      case FaultType.latency:
        return 'Latency';
      case FaultType.thermalThrottle:
        return 'Thermal Throttle';
      case FaultType.networkFailure:
        return 'Network Failure';
      case FaultType.quantizationDrift:
        return 'Quantization Drift';
    }
  }

  /// Emoji icon for terminal / Markdown output.
  String get icon {
    switch (this) {
      case FaultType.memoryPressure:
        return '🧠';
      case FaultType.malformedInput:
        return '📥';
      case FaultType.latency:
        return '⏱';
      case FaultType.thermalThrottle:
        return '🌡';
      case FaultType.networkFailure:
        return '🌐';
      case FaultType.quantizationDrift:
        return '📉';
    }
  }
}
