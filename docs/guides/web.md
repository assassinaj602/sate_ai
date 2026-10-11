# Web Builds

> Web builds are not supported when the TFLite adapter is active. The
> tflite_flutter package relies on native FFI bindings that cannot be
> transpiled to JavaScript. Web projects should use MockAdapter or a
> web-compatible adapter.

## Overview

SATE AI provides fault injection and stress testing across multiple AI runtimes. While pure Dart logic and `MockAdapter` run seamlessly across all platforms (including web browsers), machine learning runtimes that depend on native C/C++ libraries via `dart:ffi` (such as `tflite_flutter`, `onnxruntime`, or `fllama`) are designed for mobile and desktop environments.

## Running Tests on Web

To run stress tests or use SATE AI in a Flutter Web project:

1. Use `MockAdapter` for UI and pipeline verification:
```dart
final model = MockAdapter(modelId: 'web-model');
final report = await SateAI.stress(
  model: model,
  injectors: [
    MemoryPressureInjector(limitMb: 50),
    MalformedInputInjector(),
  ],
);
```

2. When using native mobile adapters (such as `TFLiteAdapter`), ensure those calls are scoped to native platforms (`Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isLinux || Platform.isWindows`) and avoid referencing `tflite_flutter` in web entrypoints.
