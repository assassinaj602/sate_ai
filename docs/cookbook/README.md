# SATE AI Cookbook & Recipes

A curated guide of practical fault injection and resilience testing recipes for Flutter on-device machine learning.

---

## 📖 Overview

Deploying machine learning models locally on edge devices (smartphones, tablets, IoT, edge compute) requires handling non-deterministic operating environments:
- Background apps consuming physical RAM causing abrupt OOM kills
- Extended compute bursts inducing thermal throttling and 5–10x latency spikes
- Corrupted camera frames, malformed audio buffers, or malformed user text
- Quantization drift degrading outputs below safety thresholds

This cookbook demonstrates hands-on testing recipes using **SATE AI** injectors and model adapters.

---

## 🍳 Recipe Index

| Recipe | Description | Primary Fault Injectors | Target Models & Adapters |
|---|---|---|---|
| [**Recipe 1: Testing a Chatbot Model**](recipe-1-chatbot-testing.md) | Conversational AI stress testing with context window limits and memory exhaustion | `MemoryPressureInjector`, `MalformedInputInjector`, `QuantizationDriftInjector` | Llama 3, Phi-3, Gemma (`FllamaAdapter`, `MockAdapter`) |
| [**Recipe 2: Testing an Image Classifier**](recipe-2-image-classifier-testing.md) | Vision models under thermal heat and inference latency spikes | `ThermalThrottleInjector`, `LatencyInjector`, `ModelSwapInjector` | MobileNet, ResNet, EfficientNet |
| [**Recipe 3: Testing a Speech-to-Text Model**](recipe-3-speech-to-text-testing.md) | Audio preprocessing, empty/noisy signals, and confidence thresholding | `MalformedInputInjector`, `LatencyInjector`, `ConfidenceThresholdInjector` | Whisper, Vosk, Speech recognition pipelines |
| [**Recipe 4: Testing with ONNX Runtime**](recipe-4-onnx-runtime-testing.md) | End-to-end testing with cross-platform ONNX format | All core injectors | ONNX Runtime (`OnnxAdapter`) |
| [**Recipe 5: Testing with TensorFlow Lite**](recipe-5-tflite-testing.md) | Mobile inference validation with TFLite models and delegates | All core injectors | TensorFlow Lite (`TFLiteAdapter`) |

---

## 🛠️ Prerequisites & Installation

Add SATE AI to your `pubspec.yaml`:

```yaml
dependencies:
  sate_ai: ^0.11.0
  flutter:
    sdk: flutter
```

Import the package in your Dart code or tests:

```dart
import 'package:sate_ai/sate_ai.dart';
```

See [Common Setup & Utilities](common-setup.md) for shared helper fixtures.
