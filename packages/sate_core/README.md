# sate_core

Pure Dart fault injection and reliability testing engine for on-device AI models.

`sate_core` is the framework-agnostic foundational engine powering SATE AI. It contains zero Flutter or GUI dependencies and can be used in any Dart environment: command-line tools, backend servers, CI/CD runners, and edge devices.

---

## Features

- **11 Standard Fault Injectors**:
  - `MemoryPressureInjector`: Simulates RAM allocation pressure up to limit MB.
  - `MalformedInputInjector`: Feeds empty, oversized (1MB), and garbage payloads.
  - `QuantizationDriftInjector`: Simulates precision degradation across steps.
  - `ThermalThrottleInjector`: Simulates CPU thermal throttling and step degradation.
  - `LatencyInjector`: Injects synthetic latency delays to test fallbacks.
  - `ModelSwapInjector`: Tests dynamic model fallback and runtime swapping.
  - `ConfidenceThresholdInjector`: Validates prediction confidence boundaries.
  - `GpuMemoryPressureInjector`: Simulates GPU VRAM exhaustion scenarios.
  - `DataCorruptionInjector`: Injects noise, blur, and bit flips into inputs.
  - `ModelVersionMismatchInjector`: Simulates model schema and version mismatches.
  - `NetworkLatencyDropInjector`: Simulates network timeouts and socket drops.
- **Adaptive Chaos Injection**:
  - `AdaptiveChaosInjector`: Modulates fault pacing and intensity dynamically using live CPU, RAM, and thermal readings.
- **Stress Cost Estimation**:
  - `CostEstimator`: Pre-flight estimation of test duration, peak memory consumption, battery drain, and cloud API spend across Edge, Server, and Mobile profiles.
- **Golden Baseline Comparison**:
  - Automatically detect regression against established performance thresholds.
- **SQLite Storage & History**:
  - Local persistence of historical test reports using `sqflite_common_ffi`.
- **Localization & Webhooks**:
  - Multi-language markdown and HTML reports (English, Spanish, French, German, Portuguese).
  - Out-of-the-box webhook notification dispatchers for Slack and Discord.

---

## Installation

Add `sate_core` to your `pubspec.yaml`:

```yaml
dependencies:
  sate_core: ^0.1.0
```

Or install via the command line:

```bash
dart pub add sate_core
```

---

## Quick Start

### 1. Basic Stress Test

```dart
import 'package:sate_core/sate_core.dart';

void main() async {
  // Use a built-in mock adapter or wrap your own runtime
  final adapter = MockAdapter();

  final runner = StressRunner(
    adapter: adapter,
    injectors: [
      MemoryPressureInjector(limitMB: 150),
      MalformedInputInjector(),
      LatencyInjector(maxLatencyMs: 250),
    ],
    timeout: const Duration(seconds: 30),
  );

  final report = await runner.run();

  print('Passed: ${report.passed}');
  print('Total tests: ${report.results.length}');
  print(report.toMarkdown());
}
```

### 2. Pre-Flight Cost Estimation

Estimate the resource impact and monetary spend of a stress test before executing it:

```dart
import 'package:sate_core/sate_core.dart';

void main() {
  final estimator = CostEstimator();
  final estimate = estimator.estimate(
    injectors: [
      MemoryPressureInjector(limitMB: 200),
      ThermalThrottleInjector(),
      AdaptiveChaosInjector(),
    ],
    iterationsPerInjector: 10,
    costPerMillionTokens: 0.15,
    profile: EstimateProfile.edge,
  );

  print('Estimated Duration: ${estimate.estimatedDuration.inSeconds}s');
  print('Estimated RAM: ${estimate.estimatedMemoryMB.toStringAsFixed(1)} MB');
  print('Estimated Battery Drain: ${estimate.estimatedBatteryDrainPercent.toStringAsFixed(2)}%');
  print('Estimated Spend: \$${estimate.estimatedCostUSD.toStringAsFixed(4)}');
}
```

### 3. Implementing a Custom Model Adapter

Extend `AIModelAdapter` to connect your own on-device runtime (e.g., TFLite, ONNX, MediaPipe, or llama.cpp):

```dart
import 'package:sate_core/sate_core.dart';

class MyVisionAdapter extends AIModelAdapter {
  @override
  String get modelName => 'MobileNetV2';

  @override
  bool isHealthy = true;

  @override
  double currentMemoryMB = 45.0;

  @override
  double currentGPUMemoryMB = 0.0;

  @override
  Future<AIOutput> runInference(AIInput input) async {
    if (!isHealthy) {
      throw Exception('Model is in degraded state');
    }
    // Call your native runtime here
    return AIOutput(
      data: [0.92, 0.05, 0.03],
      confidence: 0.92,
      latency: const Duration(milliseconds: 14),
    );
  }

  @override
  Future<void> simulateMemoryPressure(double mb) async {
    currentMemoryMB += mb;
  }

  @override
  Future<void> reset() async {
    isHealthy = true;
    currentMemoryMB = 45.0;
  }
}
```

---

## Architecture

`sate_core` is organised into clean, modular layers:

- `src/adapter/`: Interfaces and contracts for model runtimes (`AIModelAdapter`, `AIInput`, `AIOutput`).
- `src/core/`: Core runner, reporting, and cost estimation logic (`StressRunner`, `StressReport`, `CostEstimator`).
- `src/injectors/`: Built-in fault injection implementations and telemetry modulators.
- `src/storage/`: SQLite report database and historical metrics query engine.
- `src/baseline/`: Golden baseline comparators and regression detection.
- `src/templates/`: Localized Markdown/HTML exporters and webhook notifications.

---

## License

MIT License. See [LICENSE](../../LICENSE) for details.

