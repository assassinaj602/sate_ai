import 'dart:convert';

/// Text or binary input payload for an AI model inference call.
///
/// At least one of [text] or [binary] must be provided.
///
/// ```dart
/// final textInput  = AIInput(text: 'Translate: Hello');
/// final binaryInput = AIInput(binary: Uint8List.fromList([...]));
/// ```
class AIInput {
  /// Plain-text input for language models.
  final String? text;

  /// Raw binary input (e.g. tokenized ids, audio frames).
  final List<int>? binary;

  /// Optional key-value metadata passed alongside the payload.
  final Map<String, dynamic>? metadata;

  /// Constructs an [AIInput].
  ///
  /// Throws [ArgumentError] if both [text] and [binary] are null.
  AIInput({
    this.text,
    this.binary,
    this.metadata,
  }) {
    if (text == null && binary == null) {
      throw ArgumentError('AIInput: either text or binary must be provided.');
    }
  }

  /// Deserialises from a JSON map.
  factory AIInput.fromJson(Map<String, dynamic> json) {
    return AIInput(
      text: json['text'] as String?,
      binary: json['binary'] != null
          ? base64Decode(json['binary'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'text': text,
        'binary': binary != null ? base64Encode(binary!) : null,
        'metadata': metadata,
      };
}

/// Output produced by an AI model inference call.
class AIOutput {
  /// The model's textual response.
  final String text;

  /// Wall-clock time taken for this inference call.
  final Duration inferenceTime;

  /// Optional confidence score in the range [0, 1].
  final double? confidence;

  /// Additional metadata returned by the model (e.g. token counts).
  final Map<String, dynamic>? metadata;

  /// Constructs an [AIOutput].
  const AIOutput({
    required this.text,
    required this.inferenceTime,
    this.confidence,
    this.metadata,
  });

  /// Deserialises from a JSON map.
  factory AIOutput.fromJson(Map<String, dynamic> json) {
    return AIOutput(
      text: json['text'] as String,
      inferenceTime: Duration(milliseconds: json['inferenceTimeMs'] as int),
      confidence: (json['confidence'] as num?)?.toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'text': text,
        'inferenceTimeMs': inferenceTime.inMilliseconds,
        'confidence': confidence,
        'metadata': metadata,
      };
}

/// Thrown when an AI model inference call fails.
class AIInferenceError implements Exception {
  /// Constructs an [AIInferenceError].
  const AIInferenceError(this.message, [this.originalStackTrace]);

  /// Human-readable description of the failure.
  final String message;

  /// The original stack trace, if available.
  final StackTrace? originalStackTrace;

  @override
  String toString() => 'AIInferenceError: $message';
}

/// Abstract interface that wraps any on-device AI model.
///
/// Implement this to connect SATE AI to a real model backend
/// (e.g. TFLite, ONNX Runtime, Fllama).
///
/// ## Example
///
/// ```dart
/// class TFLiteAdapter implements AIModelAdapter {
///   @override
///   String get modelId => 'mobilenet-v3';
///
///   @override
///   Future<AIOutput> runInference(AIInput input) async {
///     // delegate to tflite_flutter
///   }
///   // ...
/// }
/// ```
abstract class AIModelAdapter {
  /// Stable identifier for this model (used in reports).
  String get modelId;

  /// Estimated memory currently consumed by the model in megabytes.
  double get currentMemoryMB;

  /// Whether the model is in a degraded / unreliable state.
  bool get isDegraded;

  /// Run a single inference call and return the result.
  ///
  /// Throws [AIInferenceError] on failure.
  Future<AIOutput> runInference(AIInput input);

  /// Simulate [mb] megabytes of additional memory allocation.
  ///
  /// Used by `MemoryPressureInjector` to stress the model.
  Future<void> simulateMemoryPressure(int mb);

  /// Restore the model to a clean, non-degraded state.
  Future<void> reset();

  /// Returns `true` when the model can accept inference calls safely.
  Future<bool> isHealthy();
}
