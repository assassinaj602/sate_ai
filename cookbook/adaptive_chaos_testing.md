# Adaptive Chaos Injection with Live Resource Telemetry

This guide explains how to use SATE AI's **Adaptive Chaos Injection** to simulate dynamic edge device resource pressure without triggering unrecoverable OS hard-kills.

---

## 💡 Overview

Traditional static stress testing scripts allocate fixed buffers (e.g. 200 MB) or sleep for fixed delays. On resource-constrained edge devices (phones, IoT devices, single-board computers), static stress tests either:
1. Under-stress the model when the device has abundant free RAM, or
2. Instantly kill the process via the OS Low Memory Killer (LMK / OOM killer) when free RAM drops too low.

`AdaptiveChaosInjector` solves this by monitoring live device telemetry before each fault cycle and continuously modulating:
- **Injection intensity**: Scales memory allocation based on available RAM headroom.
- **Pacing interval**: Adjusts injection frequency and sleeps longer under heavy CPU load or high thermal states.
- **Safety backoff**: Automatically backs off when available headroom hits critical limits (<5% free RAM or critical thermal status) so models are tested at their edge without premature termination.

---

## 🚀 Quick Start (CLI)

Run stress tests with the `--adaptive-chaos` flag:

```bash
# Run adaptive chaos injection alongside default injectors
sate_ai --model models/detector.tflite --adaptive-chaos

# Run only adaptive chaos injection
sate_ai --model models/detector.tflite --injectors adaptiveChaos
```

---

## 🛠️ Programmatic Usage (Dart / Flutter)

```dart
import 'package:sate_core/sate_core.dart';

void main() async {
  final model = MockAdapter(modelId: 'edge-llm-v1');

  // Configure adaptive chaos injection
  final adaptiveInjector = AdaptiveChaosInjector(
    model: model,
    baseAllocationMB: 60,
    maxAllocationMB: 200,
    minAllocationMB: 15,
    baseInterval: const Duration(milliseconds: 100),
    maxInterval: const Duration(milliseconds: 1000),
    onTelemetrySampled: (telemetry, appliedMB, interval) {
      print('Telemetry: $telemetry');
      print('Applied: $appliedMB MB with pacing interval ${interval.inMilliseconds}ms');
    },
  );

  final runner = StressRunner(
    model: model,
    injectors: [adaptiveInjector],
    timeout: const Duration(seconds: 45),
  );

  final report = await runner.run();
  print(report.toMarkdown());
}
```

---

## 📊 Telemetry Metrics & Pacing Rules

`AdaptiveChaosInjector` observes the following telemetry states:

| Condition | Pacing Behavior | Allocation Impact |
|---|---|---|
| **Abundant Headroom** (>50% free RAM, CPU < 50%) | Aggressive stress | Scales up toward `maxAllocationMB`, accelerates intervals |
| **Nominal Headroom** (20% - 50% free RAM) | Standard stress | Applies `baseAllocationMB` with `baseInterval` |
| **Low Headroom** (<20% free RAM or CPU > 85%) | Throttle down | Scales down toward `minAllocationMB`, increases sleep interval |
| **Thermal Fair** | Mild throttle | 75% nominal allocation, 1.5x pacing delay |
| **Thermal Serious / Critical** or **Critical RAM** (<5% free RAM) | Emergency safety backoff | Minimum allocation (`minAllocationMB`), maximum delay (`maxInterval`) |

---

## 🧪 Custom Telemetry Providers

For specialized edge hardware (e.g. Raspberry Pi, automotive gateways, or robotics platforms), you can implement a custom `ResourceMonitor`:

```dart
class CustomBoardResourceMonitor implements ResourceMonitor {
  @override
  Future<ResourceTelemetry> sample() async {
    final freeMB = await readBoardFreeRam();
    final totalMB = await readBoardTotalRam();
    final cpuUsage = await readCpuLoad();

    return ResourceTelemetry(
      availableMemoryMB: freeMB,
      totalMemoryMB: totalMB,
      cpuLoadPercentage: cpuUsage,
      thermalState: ThermalState.nominal,
      timestamp: DateTime.now(),
    );
  }
}
```
