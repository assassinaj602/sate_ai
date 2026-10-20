# Video 3: Adding a Custom Adapter

> **Episode**: 03 of 05  
> **Target Duration**: 4 minutes 30 seconds  
> **Level**: Intermediate  
> **Topics**: The AIModelAdapter Contract, Wrapping Native Inference Engines, Integrating Custom Models with SATE AI  

---

## 📋 Production Script & Timeline

| Time | Segment | Visual On Screen | Audio / Narration |
| :---: | :--- | :--- | :--- |
| **00:00 - 00:30** | **Introduction** | Graphic comparing TensorFlow Lite, ONNX Runtime, and PyTorch Mobile. | "In Episode 3, we focus on the engine that drives your intelligence: the model. SATE AI ships with pre-configured adapters for TensorFlow Lite, ONNX Runtime, llama.cpp, Google ML Kit, and MediaPipe. But what if you are using PyTorch Mobile, ExecuTorch, or a proprietary in-house C++ runtime?" |
| **00:30 - 01:25** | **The Adapter Contract** | Interface definition of `AIModelAdapter` showing `initialize`, `predict`, and `dispose`. | "All inference engines in SATE AI implement the simple `AIModelAdapter` interface. By mapping your native runtime into this contract, SATE AI can stress-test any machine learning model without knowing its internal implementation details." |
| **01:25 - 03:00** | **Implementing PyTorchMobileAdapter** | Writing the adapter class, loading a `.pt` torchscript model, and handling input tensor conversion. | "Let us implement a `PyTorchMobileAdapter`. In `initialize`, we load our compiled TorchScript asset into memory. In `predict`, we unpack input tensors, execute the forward pass, and return the output logits. In `dispose`, we free native C++ memory buffers." |
| **03:00 - 03:55** | **Stress Testing the Adapter** | Running SATE AI against the custom adapter with `MalformedTensorInjector` and `QuantizationDriftInjector`. | "Once implemented, your custom model gains instant access to all 12 fault injectors. Here, we run `MalformedTensorInjector` and `QuantizationDriftInjector`. Notice how SATE AI catches boundary errors and validates fallback logic automatically." |
| **03:55 - 04:30** | **Outro & Next Episode** | Graphic card promoting Episode 4: CI/CD Integration & Automation. | "Now any model in your stack can be certified for edge reliability. In Episode 4, we take SATE AI into the cloud and automate our stress tests in GitHub Actions and continuous integration pipelines." |

---

## 💻 Code Example: Implementing a Custom Model Adapter

```dart
import 'dart:async';
import 'package:sate_core/sate_core.dart';

/// Adapter wrapping a custom or proprietary inference runtime.
class PyTorchMobileAdapter extends AIModelAdapter {
  final String modelPath;
  bool _isReady = false;

  PyTorchMobileAdapter({required this.modelPath});

  @override
  String get modelName => 'PyTorchMobile-${modelPath.split('/').last}';

  @override
  Future<void> initialize() async {
    // 1. Load model bytes or initialize native FFI/JNI pointers
    await Future<void>.delayed(const Duration(milliseconds: 50));
    _isReady = true;
  }

  @override
  Future<Map<String, dynamic>> predict(Map<String, dynamic> input) async {
    if (!_isReady) {
      throw StateError('Model adapter has not been initialized.');
    }

    // 2. Validate input format
    final tensorData = input['tensor'] as List<double>?;
    if (tensorData == null || tensorData.isEmpty) {
      throw ArgumentError('Missing required "tensor" input data.');
    }

    // 3. Check for malformed inputs (NaN or Infinity) injected by SATE AI
    if (tensorData.any((v) => v.isNaN || v.isInfinite)) {
      throw FormatException('Malformed float detected in input tensor.');
    }

    // 4. Simulate native forward pass execution
    await Future<void>.delayed(const Duration(milliseconds: 32));

    return {
      'confidence': 0.94,
      'label_index': 3,
      'probabilities': [0.01, 0.02, 0.03, 0.94],
    };
  }

  @override
  Future<void> dispose() async {
    // 5. Clean up native interpreter buffers
    _isReady = false;
  }
}
```

---

## 🎙️ Complete Voiceover Transcript

**[00:00]** Welcome to Episode 3. One of the strongest design features of SATE AI is runtime independence.

**[00:30]** The `AIModelAdapter` interface requires only three methods: `initialize` to load your weights, `predict` to execute inference and return a map of outputs, and `dispose` to free native memory handles.

**[01:25]** In this tutorial, we build a `PyTorchMobileAdapter`. We handle loading, input validation, and forward pass execution. If an injector introduces `NaN` or unhandled dimensions, our adapter surfaces a clean exception that SATE AI captures and aggregates.

**[03:00]** We can now pair this adapter with any combination of our 12 fault injectors to stress-test our model across hundreds of iterations.

**[03:55]** In Episode 4, we will take SATE AI into our continuous integration pipelines using the standalone CLI and GitHub composite action.
