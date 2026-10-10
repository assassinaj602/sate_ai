/// Result of a model health check.
///
/// A health check runs a quick sanity test on a model adapter to verify
/// that it can perform basic inference and produce valid output.
class HealthCheckResult {
  /// The model identifier.
  final String modelId;

  /// Whether the health check passed.
  final bool passed;

  /// Timestamp when the check was performed.
  final DateTime timestamp;

  /// Duration of the health check.
  final Duration duration;

  /// Output text from the sanity inference (if successful).
  final String? outputText;

  /// Confidence score from the sanity inference (if available).
  final double? confidence;

  /// Error message if the check failed.
  final String? errorMessage;

  /// Stack trace if the check failed with an exception.
  final StackTrace? stackTrace;

  /// Additional diagnostic metadata.
  final Map<String, dynamic> metadata;

  /// Creates a [HealthCheckResult] with the given diagnostics.
  HealthCheckResult({
    required this.modelId,
    required this.passed,
    required this.timestamp,
    required this.duration,
    this.outputText,
    this.confidence,
    this.errorMessage,
    this.stackTrace,
    this.metadata = const {},
  });

  /// Creates a successful health check result.
  factory HealthCheckResult.passed({
    required String modelId,
    required Duration duration,
    required String outputText,
    double? confidence,
    Map<String, dynamic> metadata = const {},
  }) {
    return HealthCheckResult(
      modelId: modelId,
      passed: true,
      timestamp: DateTime.now(),
      duration: duration,
      outputText: outputText,
      confidence: confidence,
      metadata: metadata,
    );
  }

  /// Creates a failed health check result.
  factory HealthCheckResult.failed({
    required String modelId,
    required Duration duration,
    required String errorMessage,
    StackTrace? stackTrace,
  }) {
    return HealthCheckResult(
      modelId: modelId,
      passed: false,
      timestamp: DateTime.now(),
      duration: duration,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'passed': passed,
        'timestamp': timestamp.toIso8601String(),
        'durationMs': duration.inMilliseconds,
        'outputText': outputText,
        'confidence': confidence,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace?.toString(),
        'metadata': metadata,
      };

  /// Deserializes from JSON.
  factory HealthCheckResult.fromJson(Map<String, dynamic> json) {
    return HealthCheckResult(
      modelId: json['modelId'] as String,
      passed: json['passed'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int),
      outputText: json['outputText'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      errorMessage: json['errorMessage'] as String?,
      stackTrace: json['stackTrace'] != null
          ? StackTrace.fromString(json['stackTrace'] as String)
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    );
  }

  /// Returns a human-readable Markdown summary.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Model Health Check: $modelId');
    buffer.writeln();
    buffer.writeln('- **Status**: ${passed ? "PASSED" : "FAILED"}');
    buffer.writeln('- **Timestamp**: ${timestamp.toIso8601String()}');
    buffer.writeln('- **Duration**: ${duration.inMilliseconds} ms');
    if (outputText != null) {
      buffer.writeln('- **Output**: `$outputText`');
    }
    if (confidence != null) {
      buffer.writeln('- **Confidence**: ${confidence!.toStringAsFixed(2)}');
    }
    if (errorMessage != null) {
      buffer.writeln('- **Error**: `$errorMessage`');
    }
    return buffer.toString();
  }

  @override
  String toString() =>
      'HealthCheckResult($modelId, passed: $passed, ${duration.inMilliseconds}ms)';
}
