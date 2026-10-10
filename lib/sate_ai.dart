/// SATE AI: Fault Injection Framework for On-Device AI.
///
/// Import this library to access all public APIs:
///
/// ```dart
/// import 'package:sate_ai/sate_ai.dart';
///
/// final report = await SateAI.stress(
///   model: MockAdapter(),
///   injectors: [
///     MemoryPressureInjector(model: MockAdapter(), limitMb: 100),
///     MalformedInputInjector(),
///   ],
/// );
/// print(report.toMarkdown());
/// ```
library sate_ai;

// Re-export the entire pure Dart core
export 'package:sate_core/sate_core.dart';

// Flutter-only adapters (require native plugins)
export 'src/adapters/onnx_adapter.dart';
export 'src/adapters/tflite_adapter.dart';
export 'src/adapters/fllama_adapter.dart';

// Simulation adapters
export 'src/adapters/mediapipe_adapter.dart';
export 'src/adapters/coreml_adapter.dart';
export 'src/adapters/google_mlkit_adapter.dart';
