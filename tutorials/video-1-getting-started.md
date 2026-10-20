# Video 1: Getting Started with SATE AI

> **Episode**: 01 of 05  
> **Target Duration**: 3 minutes 45 seconds  
> **Level**: Beginner  
> **Topics**: Installing SATE AI, Running Your First Stress Test, Understanding the Stress Report  

---

## 📋 Production Script & Timeline

| Time | Segment | Visual On Screen | Audio / Narration |
| :---: | :--- | :--- | :--- |
| **00:00 - 00:30** | **Hook & Problem** | Screen recording of a mobile app freezing and disappearing to home screen during AI inference. | "Have you ever deployed a machine learning model to a mobile app, passed all your unit tests, only to have users report sudden crashes? In this video, we introduce SATE AI: an open-source chaos engineering engine designed specifically for on-device AI." |
| **00:30 - 01:15** | **Installation** | VS Code terminal: running `flutter pub add sate_ai` and viewing `pubspec.yaml`. | "Getting started takes under sixty seconds. Add `sate_ai` to your Flutter project dependencies, or install `sate_cli` globally if you are running pure Dart tests. SATE AI works with TensorFlow Lite, ONNX Runtime, llama.cpp, and mock engines out of the box." |
| **01:15 - 02:30** | **First Stress Test** | Code editor writing a unit test with `StressRunner`, `MockModelAdapter`, and `MemoryPressureInjector`. | "Let us write our first test. We instantiate our model adapter, wrap it with `StressRunner`, and attach our first injector: `MemoryPressureInjector`. We configure it to simulate an 800MB memory allocation spike. When we run `flutter test`, SATE AI executes warmup runs, applies the stress, and records telemetry." |
| **02:30 - 03:20** | **Understanding the Report** | Terminal showing ASCII summary report with pass rate, P50/P90/P99 latency, and recommendations. | "Notice the report generated in the terminal: you get instant visibility into P50, P90, and P99 latency percentiles, memory consumption delta, and fallback activations. If the model violates latency budgets or fails under pressure, SATE AI highlights actionable remediation steps." |
| **03:20 - 03:45** | **Outro & Next Episode** | Graphic card promoting Episode 2: Custom Injectors. | "In Episode 2, we will look under the hood and build our very own custom fault injector. Star the repo on GitHub, and I will see you in the next video!" |

---

## 💻 Code Example: Your First Stress Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  test('MobileNetV2 vision pipeline survives memory pressure', () async {
    // 1. Configure the model adapter (TFLite, ONNX, or Mock)
    final model = MockModelAdapter(
      name: 'MobileNetV2-INT8',
      baseLatency: const Duration(milliseconds: 25),
    );

    // 2. Build the StressRunner with your target fault injectors
    final runner = StressRunner(
      adapter: model,
      injectors: [
        MemoryPressureInjector(allocationSizeMB: 400),
        MalformedTensorInjector(corruptionRate: 0.1),
      ],
      iterations: 20,
    );

    // 3. Execute the stress run
    final report = await runner.run();

    // 4. Assert reliability criteria
    expect(report.passRate, equals(1.0));
    expect(report.p99Latency.inMilliseconds, lessThan(150));
    print(report.toTerminalSummary());
  });
}
```

---

## 🎙️ Complete Voiceover Transcript

**[00:00]** Welcome to the SATE AI tutorial series. When machine learning models run on mobile devices, they face harsh conditions: memory spikes, thermal throttling, and corrupted camera frames.

**[00:30]** SATE AI allows you to systematically inject these anomalies during testing so your app handles degradation gracefully. To install it, run `flutter pub add sate_ai` in your terminal.

**[01:15]** Here we write our first stress test. We define our model adapter, attach a `MemoryPressureInjector` configured to 400 megabytes, and run twenty iterations through `StressRunner`.

**[02:30]** The output provides complete telemetry: 100% pass rate, 28 millisecond P50 latency, and 45 millisecond P99 latency. If an allocation fails, you get clear diagnostics rather than an operating system crash.

**[03:20]** In our next episode, we will build a custom fault injector from scratch. See you there!
