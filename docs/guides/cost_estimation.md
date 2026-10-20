# Stress Test Cost and Resource Estimation

This guide explains how to use SATE AI's **Cost Estimator** to forecast stress test duration, peak memory consumption, simulated battery drain, and cloud API charges prior to executing expensive or destructive fault-injection runs.

---

## 💡 Overview

Running extensive stress tests or continuous chaos suites on resource-constrained edge devices can consume significant power, risk Low Memory Killer (LMK) crashes, or incur unanticipated cloud API billing for hybrid models.

`CostEstimator` provides predictive analysis before launching tests, answering critical pre-flight questions:
- **Duration**: How long will the suite take under the configured injectors, retries, and intervals?
- **Peak RAM / VRAM**: Will the combined memory footprint of the model and injectors exceed device headroom?
- **Battery Impact**: How many milliamp-hours (mAh) and what percentage of battery will be depleted?
- **Cloud Spend**: What is the projected USD API cost based on projected token volume for hosted models?

---

## 🚀 Quick Start (CLI)

Run pre-flight cost estimation before running your test suite with the `--estimate` flag:

```bash
# Estimate duration, memory, and battery consumption for default injectors
sate_ai --estimate

# Estimate with specific injectors and hardware profile
sate_ai --estimate --injectors memoryPressure,thermalThrottle --estimate-profile edge

# Include hybrid/cloud API cost estimation
sate_ai --estimate --estimate-cloud

# Export estimate report to a Markdown file
sate_ai --estimate --markdown --output estimate_report.md

# Export raw JSON metrics for CI/CD pipeline gating
sate_ai --estimate --output estimate_metrics.json
```

---

## 📱 Hardware Profiles

SATE AI provides built-in hardware profiles calibrated against real-world device classes:

| Profile | Target Device Class | Nominal Battery | Idle Current | Inference Current | System RAM |
|---|---|---|---|---|---|
| `mobile` (default) | Modern smartphones | 4000 mAh | 120 mA | 850 mA | 4096 MB |
| `edge` / `edgeIoT` | Embedded / IoT boards (Raspberry Pi, Jetson) | 2500 mAh | 250 mA | 1400 mA | 2048 MB |
| `tablet` | Workstations / high-capacity tablets | 8000 mAh | 180 mA | 1100 mA | 8192 MB |

You can also define custom hardware profiles with custom battery and memory constraints:

```dart
final customProfile = DeviceHardwareProfile(
  name: 'Automotive Telematics Gateway',
  batteryCapacityMah: 12000.0,
  idleCurrentMa: 350.0,
  inferenceCurrentMa: 2200.0,
  deviceTotalMemoryMb: 16384.0,
);
```

---

## 🛠️ Programmatic Usage (Dart / Flutter)

```dart
import 'package:sate_core/sate_core.dart';

void main() {
  final model = MockAdapter(modelId: 'vision-classifier-v2');

  final injectors = [
    MemoryPressureInjector(model: model, limitMb: 200),
    ThermalThrottleInjector(model: model),
    LatencyInjector(model: model),
  ];

  // 1. Create a CostEstimator configured for Edge IoT hardware
  const estimator = CostEstimator(
    hardwareProfile: DeviceHardwareProfile.edgeIoT,
    estimatedInferenceTime: Duration(milliseconds: 120),
    estimatedTokensPerInference: 256,
    cloudPricePerMillionTokensUsd: 1.50,
  );

  // 2. Compute cost and resource projections
  final estimate = estimator.estimate(
    model: model,
    injectors: injectors,
    timeout: const Duration(seconds: 30),
    retryCount: 2,
    isCloudModel: false,
  );

  // 3. Inspect projections
  print('Projected Duration: ${estimate.estimatedDuration.inSeconds}s');
  print('Peak Memory: ${estimate.estimatedPeakMemoryMB} MB (${estimate.memoryUsagePercentage.toStringAsFixed(1)}%)');
  print('Battery Drain: ${estimate.estimatedBatteryDrainMah.toStringAsFixed(2)} mAh');

  // 4. Print formatted Markdown report
  print(estimate.toMarkdown());
}
```

---

## 📋 Sample Markdown Report

When invoked in Markdown mode or on the terminal, `CostEstimator` generates a structured breakdown:

```markdown
# SATE AI Stress Test Cost Estimate

**Target Model:** `vision-classifier-v2`  
**Device Profile:** Edge IoT / Embedded  
**Active Injectors:** 3  

| Metric | Estimated Cost | Notes |
|---|---|---|
| **Projected Duration** | 1s | Wall-clock test time |
| **Peak Memory Usage** | 210.0 MB | ~10.3% of 2048 MB |
| **Battery Consumption** | 0.33 mAh | ~0.01% of 2500 mAh |
| **Inference Cycles** | 6 | Total test probes |

> ⚠️ **Warning:** Projected peak memory exceeds 85% of total device memory. OOM risk is high.
```

---

## ⚙️ CI/CD Budget Gating

You can use `--estimate` in pre-merge CI/CD checks to prevent tests from exceeding device battery or cloud token budgets:

```bash
# Run estimate and dump JSON
sate_ai --estimate --injectors memoryPressure,malformedInput --output /tmp/estimate.json

# Check peak memory does not exceed 3000 MB
PEAK_MEM=$(jq '.estimatedPeakMemoryMB' /tmp/estimate.json)
if (( $(echo "$PEAK_MEM > 3000" | bc -l) )); then
  echo "ERROR: Stress test projected peak memory ($PEAK_MEM MB) exceeds budget (3000 MB)!"
  exit 1
fi
```
