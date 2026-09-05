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

  /// Simulates model swapping or corruption.
  ///
  /// Useful for testing behaviour when model files get corrupted.
  modelSwap,

  /// Validates that model confidence score stays above threshold.
  confidenceValidation,

  /// Simulates GPU memory pressure.
  gpuMemoryPressure,

  /// Simulates input data corruption (image noise, missing pixels, audio glitches).
  dataCorruption,

  /// Simulates model version mismatch (older/newer/incompatible versions loaded).
  modelVersionMismatch,

  /// Benchmark run without fault injection.
  benchmark,

  /// Custom user-generated injector.
  custom,
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
        return 'Artificial Latency';
      case FaultType.thermalThrottle:
        return 'Thermal Throttling';
      case FaultType.networkFailure:
        return 'Network Failure';
      case FaultType.quantizationDrift:
        return 'Quantization Drift';
      case FaultType.modelSwap:
        return 'Model Swap';
      case FaultType.confidenceValidation:
        return 'Confidence Validation';
      case FaultType.gpuMemoryPressure:
        return 'GPU Memory Pressure';
      case FaultType.dataCorruption:
        return 'Data Corruption';
      case FaultType.modelVersionMismatch:
        return 'Model Version Mismatch';
      case FaultType.benchmark:
        return 'Benchmark';
      case FaultType.custom:
        return 'Custom';
    }
  }

  /// Visual icon character for terminal and Markdown logs.
  String get icon {
    switch (this) {
      case FaultType.memoryPressure:
        return '⚡';
      case FaultType.malformedInput:
        return '⚠️';
      case FaultType.latency:
        return '⏱️';
      case FaultType.thermalThrottle:
        return '🔥';
      case FaultType.networkFailure:
        return '🌐';
      case FaultType.quantizationDrift:
        return '📉';
      case FaultType.modelSwap:
        return '🔄';
      case FaultType.confidenceValidation:
        return '🎯';
      case FaultType.gpuMemoryPressure:
        return '🖥️';
      case FaultType.dataCorruption:
        return '👾';
      case FaultType.modelVersionMismatch:
        return '🔀';
      case FaultType.benchmark:
        return '📊';
      case FaultType.custom:
        return '🛠️';
    }
  }
}
