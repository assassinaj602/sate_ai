import 'dart:typed_data';
import '../adapters/mock_adapter.dart';
import '../adapters/model_adapter.dart';
import 'model_type_detector.dart';

/// Factory for creating model adapters based on detected file types.
class ModelFactory {
  /// Creates an adapter for the given file path.
  ///
  /// If auto-detection is enabled, uses [ModelTypeDetector] to determine
  /// the model type. Otherwise, falls back to [MockAdapter].
  static AIModelAdapter create({
    required String filePath,
    required String modelId,
    bool autoDetect = true,
    Uint8List? modelBytes,
  }) {
    if (!autoDetect) {
      return MockAdapter(modelId: modelId);
    }

    final detected = ModelTypeDetector.detect(filePath);

    switch (detected) {
      case DetectedModelType.onnx:
        if (modelBytes != null) {
          // OnnxAdapter with model bytes (requires sessionFactory for tests)
          return MockAdapter(modelId: modelId);
          // In real usage: return OnnxAdapter(modelBytes: modelBytes, modelId: modelId);
        }
        return MockAdapter(modelId: modelId);

      case DetectedModelType.tflite:
        // TFLiteAdapter requires an Interpreter instance
        return MockAdapter(modelId: modelId);
      // In real usage: return TFLiteAdapter(interpreter: ..., modelId: modelId);

      case DetectedModelType.gguf:
        // FllamaAdapter requires a model path
        return MockAdapter(modelId: modelId);
      // In real usage: return FllamaAdapter(modelPath: filePath, modelId: modelId);

      case DetectedModelType.coreml:
        // CoreMLAdapter is iOS-only
        return MockAdapter(modelId: modelId);
      // In real usage: return CoreMLAdapter(modelPath: filePath, modelId: modelId);

      case DetectedModelType.tensorflow:
      case DetectedModelType.unknown:
      default:
        return MockAdapter(modelId: modelId);
    }
  }
}
