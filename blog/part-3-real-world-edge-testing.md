# Part 3: Real-World Edge Testing - Benchmarking on Physical Hardware

> *This is Part 3 of a 5-part engineering series about building and launching SATE AI, the open-source fault injection engine for on-device machine learning.*

---

## Why Emulators Are Not Enough

Testing on an Android Virtual Device (AVD) or iOS Simulator running on a 64GB RAM workstation gives a dangerously false sense of security. An emulator shares your host workstation cooling, shares workstation CPU frequency governors, and rarely reproduces the abrupt process evictions of real hardware.

To truly understand how on-device AI behaves under stress, we hooked SATE AI up to physical ARM64 hardware:

- **Target Device**: TECNO CH7n
- **Chipset**: MediaTek Helio G85 (Octa-core: 2x Arm Cortex-A75 @ 2.0 GHz + 6x Arm Cortex-A55 @ 1.8 GHz)
- **GPU**: Arm Mali-G52 MC2
- **System Memory**: 8 GB LPDDR4X
- **Operating System**: Android 12 (API Level 31)

---

## The Evaluated Models

We benchmarked four production-grade model architectures representing distinct edge workloads:

1. **MobileNetV2 (TFLite INT8)**: Quantized 8-bit image classification (224x224x3 input).
2. **MobileNetV2 (ONNX FP32)**: Full 32-bit floating point baseline executed via ONNX Runtime.
3. **ResNet-18 (ONNX FP16)**: Half-precision deep residual neural network.
4. **SmolLM-135M (GGUF Q4)**: Quantized edge Large Language Model executed via `llama.cpp` using 4-bit block quantization.

---

## Key Experimental Findings

### 1. Thermal Throttling Leads to a 4.8x Latency Blowup

When we executed consecutive inference passes on the unquantized ONNX FP32 model, the device thermal sensor recorded temperatures climbing from an idle 38.2°C to 52.8°C.

Once the SoC crossed the 50°C thermal ceiling, Android hardware governors downclocked the Cortex-A75 performance cores:

- **Idle / Baseline P50 Latency**: 42.1 ms
- **P90 Latency under Thermal Stress**: 148.6 ms
- **P99 Latency under Thermal Stress**: 202.4 ms (a **4.8x slowdown**)

For real-time applications targeting 30 frames per second (a 33.3 ms per frame budget), this thermal slowdown instantly collapsed the UI to an unusable 5 frames per second. In contrast, the quantized TFLite INT8 model remained relatively composed, rising from 28.4 ms to only 64.2 ms.

### 2. The 800MB Memory Cliff

We configured the `MemoryPressureInjector` to allocate progressively larger memory buffers (200MB, 400MB, 600MB, 800MB) while running continuous vision inference:

| Allocation Buffer | Free RAM Remaining | Model Survival Rate | Outcome |
| :---: | :---: | :---: | :--- |
| **0 MB (Baseline)** | 3.4 GB | 100% | Clean execution |
| **200 MB** | 3.2 GB | 100% | Latency increased by 4% |
| **400 MB** | 2.9 GB | 100% | Mild GC pressure observed |
| **600 MB** | 2.5 GB | 98.4% | Sporadic native memory allocation delays |
| **800 MB** | 2.1 GB | 0% (Fatal OOM) | Uninstrumented process hard-killed by Android LMK |

When the vision pipeline was protected by SATE AI with active memory monitoring and fallback triggers, the application intercepted the system memory warning at the 600MB threshold and dropped input image resolution by half, maintaining a 100% pass rate without experiencing a single crash.

### 3. Closed-Loop Adaptive Chaos Injection in Action

Static chaos tests frequently overshoot and cause immediate process death, which fails to test the degraded state of an application.

To overcome this, we deployed SATE AI's closed-loop `AdaptiveChaosInjector`. The injector dynamically adjusts its fault injection rate and intensity using real-time system telemetry:

$$\lambda(t) = \max\left(0.05, 1.0 - \alpha \cdot \Delta T(t) - \beta \cdot P_{mem}(t) - \gamma \cdot U_{cpu}(t)\right)$$

Where $\Delta T(t)$ is temperature rise above baseline, $P_{mem}(t)$ is memory pressure, and $U_{cpu}(t)$ is CPU saturation.

Under adaptive injection:
- The stress test continuously modulated fault frequency between 50ms and 800ms intervals.
- The model operated at its absolute operating threshold for 15 minutes of continuous stress.
- **Result**: Zero unhandled kernel evictions, and 100% validation of fallback and recovery paths.

---

## Framework Overhead: Sub-0.4%

A testing framework must not artificially distort the system under observation. We measured the CPU and latency overhead introduced by SATE AI telemetry and injector coordination.

Across 1,000 inference cycles, SATE AI introduced an average latency overhead of **0.38%** (less than 0.16 ms on a 42 ms inference run). Memory tracking and circular telemetry buffers consumed less than 1.8MB of auxiliary RAM.

In [Part 4](part-4-lessons-learned.md), we look behind the scenes at the hardest engineering challenges, mistakes made, and lessons learned along the journey.
