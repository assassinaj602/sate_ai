# SATE AI

Fault Injection Framework for On-Device AI Models in Flutter

[![pub package](https://img.shields.io/pub/v/sate_ai.svg)](https://pub.dev/packages/sate_ai)
[![pub points](https://img.shields.io/pub/points/sate_ai)](https://pub.dev/packages/sate_ai/score)
[![pub likes](https://img.shields.io/pub/likes/sate_ai)](https://pub.dev/packages/sate_ai/score)
[![GitHub stars](https://img.shields.io/github/stars/assassinaj602/sate_ai?style=flat)](https://github.com/assassinaj602/sate_ai/stargazers)
[![CI](https://github.com/assassinaj602/sate_ai/actions/workflows/test.yml/badge.svg)](https://github.com/assassinaj602/sate_ai/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue.svg)](https://flutter.dev)

## Overview

SATE AI is a fault injection framework for testing on-device AI models in
Flutter and Dart. It simulates real-world failure scenarios — memory pressure,
malformed inputs, quantization drift, thermal throttling, latency, model
corruption, network failure, GPU memory pressure, and confidence degradation —
so developers can validate model reliability before shipping to production.

## Features

- 11 fault injectors covering memory, I/O, thermal, and network failure modes
- 8 model adapters: MockAdapter, OnnxAdapter, TFLiteAdapter, FllamaAdapter,
  MediaPipeAdapter, CoreMLAdapter, GoogleMLKitAdapter, and custom adapters
- CLI tool with subcommands for stress, benchmark, batch, schedule, serve,
  health-check, badge, and template output
- HTML report export with Chart.js charts
- Real-time SSE monitoring dashboard
- Golden baseline regression detection
- Stress test retries and flaky test detection
- SQLite storage for historical report tracking
- CI/CD status badges (SVG)
- Custom report templates (JSON/YAML)
- Retry and flaky test detection
- Stress scheduler (cron)
- VS Code extension

## Installation

```yaml
dependencies:
  sate_ai: ^0.13.0
```

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:sate_ai/sate_ai.dart';

Future<void> main() async {
  final model = MockAdapter(modelId: 'my-model');

  final report = await SateAI.stress(
    model: model,
    injectors: [
      MemoryPressureInjector(limitMb: 100),
      MalformedInputInjector(),
    ],
    retryCount: 3,
    flakyThreshold: 2,
  );

  if (report.passed) {
    print('Model passed all stress tests.');
  } else {
    print('Model failed: ${report.failureCount} failures.');
    print(report.toMarkdown());
  }
}
```

## Fault Injectors

| Injector | Fault Type |
|----------|-----------|
| MemoryPressureInjector | memoryPressure |
| MalformedInputInjector | malformedInput |
| QuantizationDriftInjector | quantizationDrift |
| ThermalThrottleInjector | thermalThrottle |
| LatencyInjector | latency |
| ModelSwapInjector | modelSwap |
| NetworkLatencyDropInjector | networkFailure |
| ConfidenceThresholdInjector | confidenceValidation |
| GpuMemoryPressureInjector | gpuMemoryPressure |
| DataCorruptionInjector | dataCorruption |
| ModelVersionMismatchInjector | modelVersionMismatch |

## Model Adapters

| Adapter | Runtime |
|---------|---------|
| MockAdapter | Pure Dart (testing) |
| OnnxAdapter | ONNX Runtime |
| TFLiteAdapter | TensorFlow Lite |
| FllamaAdapter | llama.cpp (Llama, Phi, Gemma) |
| MediaPipeAdapter | Google MediaPipe (vision) |
| CoreMLAdapter | Apple Core ML (iOS) |
| GoogleMLKitAdapter | Google ML Kit |

## CLI

```bash
# Basic stress test
sate_ai --model model.gguf --injectors memoryPressure,malformedInput

# With retry and flaky detection
sate_ai --model model.gguf --injectors memoryPressure --retry 3 --flaky-threshold 2

# Benchmark mode
sate_ai --model model.gguf --benchmark --benchmark-runs 20

# Batch mode with auto-detection
sate_ai --models model1.onnx,model2.tflite,model3.gguf --auto-detect

# Health check
sate_ai --model model.gguf --health-check

# HTML report
sate_ai --model model.gguf --injectors memoryPressure --html --output report.html

# Custom template
sate_ai --model model.gguf --injectors memoryPressure --template templates/slack.yaml

# Generate badges
sate_ai --model model.gguf --injectors memoryPressure --badge-output docs/sate_ai

# Save to SQLite
sate_ai --model model.gguf --injectors memoryPressure --db history.db

# List history
sate_ai --db history.db --db-history

# Golden baseline
sate_ai --model model.gguf --baseline
sate_ai --model model.gguf --compare --tolerance 5.0

# Real-time monitoring dashboard
sate_ai serve --port 8080

# Scheduling
sate_ai --model model.gguf --schedule "0 2 * * *"

# Compare two reports
sate_ai --compare-reports report1.json,report2.json --diff-html --diff-output diff.html

# Generate a custom injector
sate_ai create injector MyCustomInjector
```

## Documentation

- [Website](https://assassinaj602.github.io/sate_ai/)
- [API Reference](https://pub.dev/documentation/sate_ai)
- [Research Paper](https://assassinaj602.github.io/sate_ai/paper.html)
- [Contributing Guide](CONTRIBUTING.md)

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT — see [LICENSE](LICENSE).
