# SATE AI Roadmap

This document outlines the architectural evolution, release milestones, and future plans for the SATE AI fault injection and reliability framework.

---

## 🎯 Vision

SATE AI is an open standard and cross-platform framework for validating the resilience, performance, and failure modes of on-device AI models before they reach production. What originated as a Flutter testing package has expanded into a multi-language ecosystem supporting native mobile, desktop, web, and serverless edge runtimes.

---

## 🏁 Milestones & Releases

### Phase 1: Core Decoupling & Monorepo Foundation (Completed)

- **Pure Dart Core Extraction (Issue #118)**
  - Decoupled business logic, fault injectors, and stress reports from Flutter into `packages/sate_core`.
  - Zero Flutter or GUI dependencies in the core logic layer.
- **CLI Independence (Issue #119)**
  - Converted CLI to depend directly on `sate_core` in `packages/sate_cli`.
  - Enabled installation and execution via `dart pub global activate sate_cli` without requiring Flutter SDK.
- **Monorepo Restructure (Issue #120)**
  - Migrated the repository into a proper monorepo orchestrated with Melos.
  - Relocated Flutter package to `packages/sate_ai/`.
  - Configured independent CI test jobs for core, cli, and ai packages.

### Phase 2: Multi-Language Native SDK Expansion (Completed)

- **Native Android / Kotlin SDK (Issue #121)**
  - Standalone Kotlin library at `packages/sate_android/` for JVM and native Android applications.
  - Native fault injection interfaces (`FaultInjector`, `StressRunner`, `StressReport`).
  - Native TensorFlow Lite adapter (`TFLiteAdapter`) for Android on-device inference without Flutter.
- **TypeScript / npm Web SDK (Issue #122)**
  - Standalone npm workspace at `packages/sate_web/` targeting modern browsers and Node.js.
  - `@sate-ai/core`: Framework-agnostic fault injection runner, reporter, and 11 injectors.
  - `@sate-ai/tfjs`: Adapter for TensorFlow.js models (`tf.LayersModel`, `tf.GraphModel`).
  - `@sate-ai/onnx`: Adapter for ONNX Runtime Web (`ort.InferenceSession`).

---

## 🚀 Current Milestone: v1.0.0 (Unified Cross-Platform Core)

Targeting formal stabilization of cross-platform APIs, baseline report compatibility, and documentation:

- [x] Cross-platform architecture and roadmap documentation (Issue #123)
- [x] Adaptive chaos injection schedule based on live resource telemetry (Issue #98)
- [x] Stress test cost and resource estimation for edge, mobile, and server profiles (Issue #97)
- [x] Interactive onboarding tutorial inside Flutter example app (Issue #40)
- [x] Real-world project showcase gallery and submission guide (Issue #43)
- [ ] Standardized JSON Stress Report schema specification (v1.0.0 JSON schema)
- [ ] Cross-platform report export compatibility between Dart, Kotlin, and TypeScript SDKs
- [ ] Centralized documentation site with cross-language API guides
- [ ] Initial release on pub.dev, Maven Central, and npm

---

## 🔭 Future Milestones

### Phase 3: v1.1.0 - Native Apple Ecosystem (iOS / macOS)

- **Native Swift SDK (`packages/sate_ios`)**:
  - Idiomatic Swift package with Swift Concurrency (`async`/`await`).
  - Native Core ML adapter (`CoreMLAdapter`) with Apple Neural Engine (ANE) memory and thermal state probing.
  - Support for iOS, iPadOS, macOS, and visionOS on-device models.

### Phase 4: v1.2.0 - Python Evaluation & ML Pipeline Integration

- **Python SDK (`packages/sate_python`)**:
  - Python package installable via `pip install sate-ai`.
  - Support for PyTorch Mobile, ONNX Runtime, and llama.cpp.
  - Direct integration into CI evaluation pipelines, pytest, and MLflow/Weights & Biases logging.

### Phase 5: v2.0.0 - Native C/C++ Embedded Engine

- **High-Performance C++ Core Engine**:
  - Embedded C++17/20 core engine for resource-constrained IoT and embedded hardware.
  - Direct bindings to GGML, ExecuTorch, and LiteRT.
  - Uniform FFI layer consumable by any programming language.

---

## 🤝 Community Feedback & Contributions

Roadmap priorities are shaped by developer needs across mobile, edge, and web AI. If there is a runtime or language you would like prioritized, please open a discussion or proposal in [GitHub Issues](https://github.com/assassinaj602/sate_ai/issues).
