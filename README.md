# SATE AI

Fault Injection Framework for On-Device AI Models in Flutter

[![pub package](https://img.shields.io/pub/v/sate_ai.svg)](https://pub.dev/packages/sate_ai)
[![pub points](https://img.shields.io/pub/points/sate_ai)](https://pub.dev/packages/sate_ai/score)
[![popularity](https://img.shields.io/pub/popularity/sate_ai)](https://pub.dev/packages/sate_ai/score)
[![likes](https://img.shields.io/pub/likes/sate_ai)](https://pub.dev/packages/sate_ai/score)
[![GitHub stars](https://img.shields.io/github/stars/assassinaj602/sate_ai?style=flat)](https://github.com/assassinaj602/sate_ai/stargazers)
[![CI](https://github.com/assassinaj602/sate_ai/workflows/CI/badge.svg)](https://github.com/assassinaj602/sate_ai/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-blue.svg)](https://dart.dev)

---

## Overview

SATE AI is a fault injection framework for testing on-device AI models in Flutter applications. It simulates real-world failure scenarios — memory pressure, malformed inputs, and model degradation — so developers can validate model reliability before shipping to production.

On-device AI models (Llama, Phi, Gemma, and similar) run directly on user devices where resource constraints are unpredictable. Memory pressure causes out-of-memory crashes mid-inference. Unexpected inputs cause silent failures or exceptions. Without a structured testing approach, these issues surface only in production.

SATE AI provides a `pytest`-style experience for AI failure modes: wrap your model in an adapter, configure fault injectors, and receive a structured `StressReport` with pass/fail results, timing data, and serialization to Markdown or JSON for CI/CD pipelines.

### Key Benefits

- Identify model failures before users encounter them
- Validate error handling and recovery mechanisms in a controlled environment
- Integrate AI reliability checks into existing CI/CD pipelines
- Reduce production incidents caused by resource exhaustion or unexpected inputs
- Develop against a `MockAdapter` without requiring a real AI model

---

## Features

- Core fault injection engine with a composable `FaultInjector` interface
- `StressRunner` for orchestrating multiple injectors with timeout support
- `StressReport` with JSON and Markdown serialization
- `MockAdapter` for testing without real AI models
- `MemoryPressureInjector` for out-of-memory simulation
- `MalformedInputInjector` for input validation testing (empty, oversized, binary garbage)
- `SateAI.stress()` convenience API for one-call test execution
- Extensible adapter interface for wrapping any on-device AI runtime
- 59 unit tests with full coverage of core modules
- Web dashboard for visualizing stress test reports with charts and exports

---

## Installation

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  sate_ai: ^0.1.0
```

Then run:

```bash
flutter pub get
```

Import the library:

```dart
import 'package:sate_ai/sate_ai.dart';
```

---

## Quick Start

```dart
import 'package:sate_ai/sate_ai.dart';

Future<void> main() async {
  // Use MockAdapter during development; replace with a real adapter for production.
  final model = MockAdapter(modelId: 'my-llm-v1');

  // Run a stress test with multiple fault injectors.
  final report = await SateAI.stress(
    model: model,
    injectors: [
      MemoryPressureInjector(limitMb: 100),
      MalformedInputInjector(),
    ],
    timeout: const Duration(seconds: 60),
  );

  // Inspect results.
  if (report.passed) {
    print('Model passed all stress tests.');
  } else {
    print('Model failed: ${report.failureCount} failure(s) detected.');
    print(report.toMarkdown());
  }

  // Export to JSON for CI/CD pipelines.
  final json = report.toJsonString();
  print(json);
}
```

### Expected Output

When all tests pass:

```
Model passed all stress tests.
```

When failures are detected, `report.toMarkdown()` produces a structured report:

```
# Stress Report: my-llm-v1

- Passed: false
- Total Tests: 2
- Failures: 1
- Duration: 1.23s

## Failures

### Memory Pressure Injector
- Fault: memoryPressure
- Error: Model degraded under memory pressure (currentMemoryMB: 150)
```

---

## Adapters

An `AIModelAdapter` wraps any on-device AI runtime and exposes a uniform interface for running inference and inspecting model state.

| Adapter | Status | Notes |
|---|---|---|
| MockAdapter | Available | Simulates memory pressure and degradation for testing |
| OnnxAdapter | Available | Wraps `onnxruntime ^1.4.1` (Android, iOS, Linux, macOS, Windows) |
| TensorFlow Lite | Planned | Wraps tflite_flutter |
| Fllama | Planned | Wraps fllama for Llama-family models |

### Writing a Custom Adapter

```dart
class MyModelAdapter implements AIModelAdapter {
  @override
  String get modelId => 'my-model-v1';

  @override
  Future<AIOutput> runInference(AIInput input) async {
    // Call your model runtime here.
    final result = await myRuntime.infer(input.text);
    return AIOutput(
      text: result,
      inferenceTime: Duration(milliseconds: 120),
      confidence: 0.92,
    );
  }

  @override
  bool get isHealthy => myRuntime.isAvailable;

  @override
  int get currentMemoryMB => myRuntime.memoryUsage;
}
```

---

## Fault Injectors

A `FaultInjector` simulates a specific failure mode by manipulating the model adapter's state before inference runs.

| Injector | Status | Fault Type |
|---|---|---|
| MemoryPressureInjector | Available | memoryPressure |
| MalformedInputInjector | Available | malformedInput |
| QuantizationDriftInjector | Available | Simulates gradual precision loss |
| ThermalThrottleInjector | Available | Simulates CPU thermal throttling |
| LatencyInjector | Available | Simulates increasing inference latency |
| ModelSwapInjector | Available | Simulates model corruption |

### Writing a Custom Injector

```dart
class ThermalThrottleInjector implements FaultInjector {
  @override
  FaultType get type => FaultType.thermalThrottle;

  @override
  String get name => 'Thermal Throttle Injector';

  @override
  String get description => 'Simulates CPU throttling under sustained thermal load.';

  @override
  Future<void> inject(AIModelAdapter model) async {
    // Add artificial latency to simulate a throttled CPU.
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Future<void> reset(AIModelAdapter model) async {
    // No persistent state to clean up.
  }
}
```

---

## Architecture

```
sate_ai/
  lib/src/
    core/
      fault_type.dart          - FaultType enum
      fault_injector.dart      - FaultInjector abstract interface
      stress_runner.dart       - Orchestration engine
      report.dart              - StressReport, FaultResult, Failure
    adapters/
      model_adapter.dart       - AIModelAdapter interface, AIInput, AIOutput
      mock_adapter.dart        - MockAdapter for testing
    injectors/
      memory_pressure_injector.dart
      malformed_input_injector.dart
  lib/sate_ai.dart             - Public API barrel export
  test/                        - 59 unit tests
  example/                     - Flutter demo application
```

---

## CI/CD Integration

SATE AI is designed to run in CI/CD pipelines. Use the JSON output to fail a build when a model regresses under stress:

```dart
final report = await SateAI.stress(
  model: MyModelAdapter(),
  injectors: [
    MemoryPressureInjector(limitMb: 200),
    MalformedInputInjector(),
  ],
);

if (!report.passed) {
  // Write report artifact and exit with error code.
  File('stress_report.json').writeAsStringSync(report.toJsonString());
  exit(1);
}
```

A GitHub Actions workflow for CI is included in the repository at `.github/workflows/ci.yml`.

---

## Documentation

- [API Reference](https://pub.dev/documentation/sate_ai)
- [Contributing Guide](https://github.com/assassinaj602/sate_ai/blob/main/CONTRIBUTING.md)
- [Example Application](https://github.com/assassinaj602/sate_ai/tree/main/example)
- [Changelog](https://github.com/assassinaj602/sate_ai/blob/main/CHANGELOG.md)
- [Web Dashboard](web/) - Visualize stress test reports

---

## Contributing

Contributions are welcome. Please read the [Contributing Guide](https://github.com/assassinaj602/sate_ai/blob/main/CONTRIBUTING.md) before submitting a pull request.

Good first issues are labeled [`good first issue`](https://github.com/assassinaj602/sate_ai/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) and cover:

- New fault injectors (thermal throttle, latency, model swap)
- New adapters (ONNX Runtime, TensorFlow Lite, Fllama)
- Documentation improvements
- Additional test coverage

### Development Setup

```bash
git clone https://github.com/assassinaj602/sate_ai.git
cd sate_ai
flutter pub get
flutter test
flutter analyze
```

## Command Line Interface

SATE AI provides a CLI for running stress tests from the terminal.

### Installation

```bash
flutter pub global activate sate_ai
```

### Usage

```bash
sate_ai --model path/to/model.gguf --injectors memoryPressure,malformedInput
```

Options:
- `--model, -m` – Path to model file (required)
- `--injectors, -i` – Comma-separated list of injectors
- `--timeout, -t` – Timeout per test (seconds)
- `--output, -o` – Save report to file
- `--markdown, -md` – Output as Markdown instead of JSON
- `--help, -h` – Show help

---

## License

This project is licensed under the MIT License. See the [LICENSE](https://github.com/assassinaj602/sate_ai/blob/main/LICENSE) file for the full text.

---

## Links

- [GitHub Repository](https://github.com/assassinaj602/sate_ai)
- [Issue Tracker](https://github.com/assassinaj602/sate_ai/issues)
- [Discussions](https://github.com/assassinaj602/sate_ai/discussions)
- [pub.dev Package](https://pub.dev/packages/sate_ai)
- [Changelog](https://github.com/assassinaj602/sate_ai/blob/main/CHANGELOG.md)
- [Contributors](https://github.com/assassinaj602/sate_ai/graphs/contributors)
