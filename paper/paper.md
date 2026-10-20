---
title: 'SATE AI: Systematic Fault Injection and Empirical Reliability Engineering for On-Device Machine Learning Models'
tags:
  - Dart
  - Flutter
  - Machine Learning
  - Edge Computing
  - Fault Injection
  - Chaos Engineering
  - TensorFlow Lite
  - ONNX Runtime
authors:
  - name: Muhammad Assad Ullah
    orcid: 0009-0008-2811-1474
    affiliation: 1
affiliations:
  - name: Department of Computer Engineering, University of Engineering and Technology Taxila, Pakistan
    index: 1
date: October 2026
bibliography: paper.bib
---

# Summary

The rapid migration of machine learning workloads from cloud data centers to edge and mobile devices has unlocked private, low-latency intelligence across smartphones, IoT nodes, and embedded robotics. However, edge execution environments are fundamentally hostile compared to cloud servers: available RAM fluctuates rapidly due to background tasks, thermal ceilings trigger aggressive CPU/GPU core frequency throttling [@wang2024thermal], and integer quantization (INT8, FP16) introduces numerical drift under edge corner-case inputs [@jacob2018quantization; @frantar2023gptq]. When an on-device model encounters memory saturation or unexpected runtime stress, mobile operating systems terminate the host process without producing a structured diagnostic crash dump.

`SATE AI` (Stress and Adversarial Testing Engine for AI) is an open-source, cross-platform fault injection and reliability engineering framework purpose-built for on-device machine learning models. Implemented across Dart, Flutter, Kotlin (Android Native), and TypeScript (Web/Node.js), `SATE AI` enables developers to systematically inject controlled operational anomalies (process memory spikes, CPU core saturation, thermal throttling, tensor corruptions, and network drops) directly into live inference pipelines. By observing output divergence, latency shifts, and graceful fallback behavior, `SATE AI` empowers software engineers to certify edge ML systems against catastrophic failures before deploying to production.

# Statement of Need

Modern machine learning verification tooling primarily focuses on cloud-hosted inference and pre-deployment model accuracy benchmarking. Frameworks such as DeepXplore [@pei2017deepxplore] and DeepTest [@tian2018deeptest] apply white-box neuron coverage and synthetic input mutations to uncover algorithmic corner cases in standalone test environments. Similarly, TensorFuzz [@odena2019tensorfuzz] employs coverage-guided fuzzing to detect numerical instability in neural network graphs.

However, these existing methodologies exhibit critical blind spots when deployed to consumer edge devices:

1. **System-Level Hostility**: Existing fuzzers test model logic in isolation, ignoring host OS dynamics such as Out-Of-Memory (OOM) killer terminations, dynamic thermal throttling, and multi-threading thread pool starvation.
2. **Lack of Uniform Runtime Abstraction**: Production mobile applications integrate heterogeneous inference runtimes, such as TensorFlow Lite [@david2021tensorflow], ONNX Runtime, Apple CoreML, llama.cpp, Google ML Kit, and MediaPipe. Testing each engine requires disparate, non-standardized harness code.
3. **Absence of Closed-Loop Telemetry**: Traditional chaos engineering tools inject static stress spikes that frequently cause immediate OS hard-kills rather than exploring the model degradation envelope.

`SATE AI` bridges this gap by providing a unified, extensible testing engine that couples controlled fault injection with real-time hardware telemetry feedback. It equips software engineers, mobile developers, and ML reliability researchers with reproducible regression pipelines that execute both in local development test suites and in headless continuous integration (CI) workflows.

# Software Architecture and Key Features

`SATE AI` is structured into five cohesive modules within a monorepo architecture:

- **`sate_core`**: The platform-agnostic Dart kernel defining foundational contracts: `FaultInjector`, `AIModelAdapter`, `StressRunner`, `StressReport`, and `MetricCollector`.
- **`sate_ai`**: The flagship Flutter package providing concrete injectors, pre-configured adapters, and rich terminal and visual dashboards.
- **`sate_cli`**: A headless, standalone command-line executable (`sate`) supporting automated test execution, model type auto-detection, pre-flight stress cost estimation, and JUnit/HTML/JSON report generation.
- **`sate_android`**: Kotlin Android native SDK providing zero-overhead JNI/NDK telemetry hooks and hardware sensor access.
- **`sate_web`**: TypeScript SDK bringing browser and Node.js WebAssembly inference testing parity.

## Domain-Specific Fault Injectors

`SATE AI` implements twelve specialized fault injectors categorized into three domains:

1. **Resource Pressure Injectors**:
   - `MemoryPressureInjector`: Allocates configurable memory buffers up to 800MB to verify low-memory warnings and prevent OS low-memory killer (LMK) aborts.
   - `ThermalThrottleSimulationInjector`: Emulates OS thermal throttling by spinning CPU threads and imposing artificial latency delays.
   - `GpuVramExhaustionInjector`: Satures GPU VRAM to validate graceful CPU fallback transitions.
2. **Data and Payload Injectors**:
   - `MalformedTensorInjector`: Injects NaNs, infinities, out-of-range floats, and dimensions mismatches.
   - `QuantizationDriftInjector`: Simulates edge quantization precision loss to detect catastrophic logits divergence.
   - `DataCorruptionInjector`: Injects bit-flips, sensor noise, and partial sensor frame dropouts.
   - `ModelVersionMismatchInjector`: Detects schema skew and tensor shape incompatibilities during over-the-air (OTA) updates.
3. **Execution and Chaos Dynamics**:
   - `NetworkLatencyDropInjector`: Simulates cellular drops and packet loss for hybrid edge-cloud workflows.
   - `LatencyModelSwapInjector`: Swaps high-precision models with fast quantized fallbacks under deadline pressure.
   - `ConfidenceDegradationValidator`: Asserts confidence score distributions under adversarial conditions.
   - `AdaptiveChaosInjector`: Continuously samples CPU load, thermal readings, and RAM headroom to dynamically modulate fault intensity, pushing models to their operating boundary without causing fatal kernel termination.

# Real-World Empirical Validation

To validate `SATE AI` in realistic operating environments, we conducted extensive physical hardware testing on an Android device (TECNO CH7n, MediaTek Helio G85 octa-core CPU, Mali-G52 GPU, 8GB RAM, Android 12) across four production models:

- **MobileNetV2 (TFLite INT8)**: Computer vision classification.
- **MobileNetV2 (ONNX FP32)**: Baseline full-precision vision model.
- **ResNet-18 (ONNX FP16)**: Half-precision deep residual network.
- **SmolLM-135M (GGUF Q4)**: Edge large language model running via llama.cpp.

The empirical findings demonstrated:
- Under simulated thermal throttling, inference latency increased from 42.1ms to 202.4ms (a 4.8x slowdown) for ONNX FP32, while TFLite INT8 showed resilience (rising from 28.4ms to 64.2ms).
- Unhandled memory pressure spikes exceeding 800MB caused abrupt process termination in uninstrumented baselines, whereas `SATE AI` protected pipelines maintained a 100% pass rate by triggering structured fallbacks.
- Adaptive chaos injection maintained continuous 100% operational survival under combined thermal and memory stress by throttling injection rate dynamically.
- Total instrumentation and telemetry overhead remained under 0.4% across all benchmarks.

# Availability and Documentation

`SATE AI` is licensed under the OSI-approved MIT License. Source code, documentation, interactive tutorials, and cookbooks are publicly available on GitHub at <https://github.com/assassinaj602/sate_ai>. Comprehensive online documentation is hosted at <https://assassinaj602.github.io/sate_ai/>.

# Acknowledgements

We thank the Department of Computer Engineering at the University of Engineering and Technology Taxila for laboratory facilities and access to testing hardware. We also thank the open-source contributors and maintainers of the Flutter, TensorFlow Lite, and ONNX Runtime ecosystems.

# References
