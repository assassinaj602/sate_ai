# SATE AI

<div align="center">

  <h3>🧪 Test what happens when your on-device AI model fails</h3>

  [![pub package](https://img.shields.io/pub/v/sate_ai.svg)](https://pub.dev/packages/sate_ai)
  [![CI](https://github.com/YOUR_USERNAME/sate_ai/workflows/CI/badge.svg)](https://github.com/YOUR_USERNAME/sate_ai/actions)
  [![Coverage](https://img.shields.io/codecov/c/github/YOUR_USERNAME/sate_ai)](https://codecov.io/gh/YOUR_USERNAME/sate_ai)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![Flutter](https://img.shields.io/badge/Flutter-3.10%2B-blue.svg)](https://flutter.dev)

</div>

---

## 🎯 What is SATE AI?

**SATE AI is the first fault-injection framework for on-device AI in Flutter.**

When your AI model runs on a user's phone, it **will** fail:

| Failure Mode | What Happens |
|---|---|
| 🧠 **Memory pressure** | OOM crash mid-inference |
| 📉 **Malformed input** | Garbage / empty outputs |
| ⚡ **Thermal throttling** | 10× slower inference |
| 🔄 **Model swaps** | Silent corruption |
| 📥 **Binary garbage input** | Undefined behavior |

**SATE AI catches these BEFORE your users do.**

```dart
import 'package:sate_ai/sate_ai.dart';

final report = await SateAI.stress(
  model: MockAdapter(),          // swap in your real model
  injectors: [
    MemoryPressureInjector(limitMb: 150),
    MalformedInputInjector(),
  ],
);

if (!report.passed) {
  print('⚠️  Model failed under stress!');
  print(report.toMarkdown());   // full breakdown
}
```

---

## 🚀 Why this exists

**Problem:** On-device AI is exploding (Llama 3, Phi-3, Gemma 2) but there is **zero tooling** to test reliability on-device.

**Solution:** SATE AI gives you a `pytest`-style experience for AI failure modes — plug in your model, plug in your fault scenarios, get a structured report.

**Goal:** Make on-device AI reliability testing as standard as widget testing.

---

## 📦 Installation

```yaml
# pubspec.yaml
dependencies:
  sate_ai: ^0.1.0
```

```bash
flutter pub get
```

---

## 🏃 Quick Start

### 1. Wrap your model

```dart
// Use MockAdapter while building, swap for a real adapter later
final model = MockAdapter(modelId: 'my-llm-v1');
```

### 2. Run a stress test

```dart
final report = await SateAI.stress(
  model: model,
  injectors: [
    MemoryPressureInjector(model: model, limitMb: 100),
    MalformedInputInjector(),
  ],
  timeout: const Duration(seconds: 60),
);
```

### 3. Inspect results

```dart
print('Passed: ${report.passed}');
print('Tests:  ${report.results.length}');
print('Failed: ${report.failureCount}');

// Save as Markdown report
final markdown = report.toMarkdown();
File('stress_report.md').writeAsStringSync(markdown);

// Or as JSON for CI
final json = report.toJsonString();
```

---

## 🏗 Architecture

```
sate_ai/
├── lib/src/
│   ├── core/
│   │   ├── fault_type.dart          # FaultType enum
│   │   ├── fault_injector.dart      # FaultInjector abstract base
│   │   ├── stress_runner.dart       # Orchestration engine
│   │   └── report.dart              # StressReport, FaultResult, Failure
│   ├── adapters/
│   │   ├── model_adapter.dart       # AIModelAdapter interface
│   │   └── mock_adapter.dart        # MockAdapter for testing
│   └── injectors/
│       ├── memory_pressure_injector.dart
│       └── malformed_input_injector.dart
├── lib/sate_ai.dart                 # Public API barrel
├── test/                            # 35 unit tests
└── example/                         # Flutter demo app
```

---

## 🔌 Writing a Custom Injector

```dart
class ThermalThrottleInjector implements FaultInjector {
  @override
  FaultType get type => FaultType.thermalThrottle;

  @override
  String get name => 'Thermal Throttle Injector';

  @override
  String get description => 'Simulates CPU throttling under heat';

  @override
  Future<void> inject() async {
    // Simulate thermal state via platform channel or busy-loop
    await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Future<void> reset() async {}
}
```

---

## 🛣 Roadmap

- [x] Core fault injection engine
- [x] `MemoryPressureInjector`
- [x] `MalformedInputInjector`
- [x] `MockAdapter`
- [ ] `ThermalThrottleInjector`
- [ ] `LatencyInjector`
- [ ] `ModelSwapInjector`
- [ ] TFLite adapter
- [ ] ONNX Runtime adapter
- [ ] Fllama adapter
- [ ] Web dashboard for reports
- [ ] GitHub Action for CI

---

## 🤝 Contributing

Contributions are what make open source great! See [CONTRIBUTING.md](CONTRIBUTING.md) for:

- 🐛 Bug reports
- 💡 New injectors
- 🔌 New adapters
- 📚 Documentation

---

## 📄 License

MIT — see [LICENSE](LICENSE).

---

## 🙏 Acknowledgments

Built from research in mobile AI reliability testing. Inspired by the `pytest` and chaos engineering communities.

---

<div align="center">
  <strong>⭐ Star this repo if you believe on-device AI needs proper testing!</strong>
</div>
