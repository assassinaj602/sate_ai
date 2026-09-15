/// Detects AI model types from file extensions.
///
/// Supports common on-device AI model formats:
/// - `.onnx` → ONNX Runtime
/// - `.tflite` → TensorFlow Lite
/// - `.gguf` → Fllama (Llama.cpp)
/// - `.mlmodel` → Apple Core ML
/// - Unknown → MockAdapter
class ModelTypeDetector {
  /// Detects the model type from a file path.
  ///
  /// Returns a [DetectedModelType] containing the model type and format.
  static DetectedModelType detect(String filePath) {
    final extension = _getExtension(filePath);

    switch (extension) {
      case 'onnx':
        return DetectedModelType.onnx;
      case 'tflite':
        return DetectedModelType.tflite;
      case 'gguf':
        return DetectedModelType.gguf;
      case 'mlmodel':
        return DetectedModelType.coreml;
      case 'bin':
      case 'pb':
        return DetectedModelType.tensorflow;
      default:
        return DetectedModelType.unknown;
    }
  }

  /// Extracts the file extension from a path (lowercase, without dot).
  static String _getExtension(String filePath) {
    final parts = filePath.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase();
  }

  /// Checks if a file extension is supported for auto-detection.
  static bool isSupported(String filePath) {
    return detect(filePath) != DetectedModelType.unknown;
  }

  /// Returns a list of supported file extensions.
  static List<String> get supportedExtensions => [
        'onnx',
        'tflite',
        'gguf',
        'mlmodel',
        'bin',
        'pb',
      ];
}

/// Detected model type from file extension.
enum DetectedModelType {
  /// ONNX Runtime model (.onnx)
  onnx,

  /// TensorFlow Lite model (.tflite)
  tflite,

  /// Llama.cpp GGUF model (.gguf)
  gguf,

  /// Apple Core ML model (.mlmodel)
  coreml,

  /// TensorFlow SavedModel (.pb, .bin)
  tensorflow,

  /// Unknown model type
  unknown,
}

/// Extension methods for [DetectedModelType].
extension DetectedModelTypeExtension on DetectedModelType {
  /// Human-readable name for the model type.
  String get displayName {
    switch (this) {
      case DetectedModelType.onnx:
        return 'ONNX Runtime';
      case DetectedModelType.tflite:
        return 'TensorFlow Lite';
      case DetectedModelType.gguf:
        return 'Fllama (llama.cpp)';
      case DetectedModelType.coreml:
        return 'Apple Core ML';
      case DetectedModelType.tensorflow:
        return 'TensorFlow';
      case DetectedModelType.unknown:
        return 'Unknown (MockAdapter)';
    }
  }

  /// Whether this model type is supported for auto-detection.
  bool get isSupported => this != DetectedModelType.unknown;
}
