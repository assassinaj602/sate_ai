# Part 1: The Problem - Why On-Device AI Needs Chaos Engineering

> *This is Part 1 of a 5-part engineering series about building and launching SATE AI, the open-source fault injection engine for on-device machine learning.*

---

## The Illusion of the Greenfield Test Environment

When you train a machine learning model on an NVIDIA A100 GPU cluster, the execution environment is predictable. You have dedicated high-bandwidth VRAM, uniform cooling in climate-controlled server racks, fixed double or single precision IEEE-754 arithmetic, and reliable container orchestration. If inference fails in the cloud, an orchestrator records telemetry, captures logs, and transparently routes the request to another replica.

Now, take that same model, quantize its weights to 8-bit integers or 4-bit normal floats, export it to TensorFlow Lite or ONNX Runtime, and package it inside a consumer mobile application.

Suddenly, all environmental guarantees vanish.

In the wild, your model executes inside a pocket computer that is also handling background video downloads, navigating GPS coordinates in direct sunlight, and juggling aggressive battery preservation heuristics. In this world, standard unit tests and clean validation loss curves mean almost nothing.

---

## Real Failures Encountered in the Wild

When I began deploying on-device AI applications, the production crash logs told a very different story from our development benchmarks. Here are three critical failure modes that repeatedly surfaced:

### 1. Memory Pressure and the Silent Kernel Kill

Mobile operating systems such as Android and iOS enforce ruthless memory policies. On mobile devices without swap space, when foreground or background applications consume RAM, the OS invokes the Low Memory Killer (LMK) daemon.

During high-resolution computer vision inference or edge LLM prompt evaluation, memory allocations spike. When an inference pass attempts to allocate an intermediate activation tensor of 120MB while another app requests memory, the kernel terminates the host process immediately with signal 9 (`SIGKILL`).

The developer never receives an unhandled exception or stack trace in Sentry or Firebase Crashlytics. The user simply sees the application vanish to the home screen.

### 2. Malformed Tensor Inputs and Unhandled Pointer Exceptions

On-device models receive inputs directly from imperfect real-world hardware sensors: camera frames interrupted by rotation transitions, microphone PCM buffers containing clipped NaN values, or accelerometer streams dropping packets during CPU spikes.

When an unvalidated float tensor containing `+Inf`, `NaN`, or corrupted dimensions is passed into native C/C++ inference engines (such as TFLite or libonnxruntime), the native runtime often experiences a segmentation fault or memory corruption. In Dart or Kotlin, this crashes the entire process before application error handlers can catch it.

### 3. Quantization Drift and Confidence Degradation

To achieve acceptable frame rates on mobile hardware, FP32 neural network weights are quantized to INT8 or FP16. While average top-1 accuracy on static test sets might only drop by 1.2%, extreme edge-case inputs (e.g. low-light camera frames, unusual sensor noise distributions) trigger catastrophic logits collapse.

The model does not technically crash; instead, it outputs nonsensical bounding boxes or high-confidence false predictions while the application assumes inference succeeded.

---

## Why Existing Tools Do Not Work for Edge AI

When evaluating tools to safeguard on-device inference, we found a stark gap in the software engineering landscape:

| Tooling Class | Examples | Target Domain | Why It Fails for On-Device AI |
| :--- | :--- | :--- | :--- |
| **Cloud Chaos Engineering** | Chaos Monkey, Gremlin, ChaosBlade | Kubernetes, Microservices | Injects network latency and container kills in cloud clusters. Has zero awareness of mobile OS signals, JNI/FFI boundaries, or mobile thermal states. |
| **Academic ML Fuzzers** | DeepXplore, DeepTest, TensorFuzz | Offline Model Graphs | Focuses exclusively on algorithm coverage (neuron activation, branch testing) in isolated desktop Python runtimes. Ignores mobile hardware constraints and OS kills. |
| **Mobile APM & Profiling** | Android Studio Profiler, Xcode Instruments | General Mobile Apps | Purely observational. Measures what happened after the fact, but does not provide programmatic, reproducible fault injection during automated regression testing. |

None of these existing tools allow a mobile developer to write:

```dart
test('vision pipeline survives 400MB memory spike and thermal throttling', () async {
  final runner = StressRunner(
    model: visionAdapter,
    injectors: [
      MemoryPressureInjector(allocationSizeMB: 400),
      ThermalThrottleSimulationInjector(simulatedDelayMs: 150),
    ],
  );
  final report = await runner.run();
  expect(report.passRate, equals(1.0));
  expect(report.gracefulFallbacksTriggered, greaterThan(0));
});
```

---

## The Birth of SATE AI

To solve this dilemma, I started building **SATE AI** (Stress and Adversarial Testing Engine for AI). The vision was clear: provide a systematic, reproducible chaos engineering framework tailored specifically for on-device machine learning.

In [Part 2](part-2-architecture-and-injectors.md), we will explore the architecture of SATE AI: how its core interfaces decouple fault injection from runtime engines, how each of the 12 specialized injectors operates under the hood, and how we achieve cross-platform parity across Flutter, Android Native, and Web.
