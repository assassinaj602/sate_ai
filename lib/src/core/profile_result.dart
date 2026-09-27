/// Detailed profiling result for a single inference pass.
///
/// Breaks down total inference time into three stages:
/// - Pre-processing (input preparation)
/// - Execution (model forward pass)
/// - Post-processing (output parsing)
///
/// Also captures memory usage at each stage boundary.
class ProfileResult {
  /// The model identifier.
  final String modelId;

  /// Duration of the pre-processing stage.
  final Duration preProcessingTime;

  /// Duration of the model execution stage.
  final Duration executionTime;

  /// Duration of the post-processing stage.
  final Duration postProcessingTime;

  /// Memory usage after pre-processing (MB).
  final double preProcessingMemoryMB;

  /// Memory usage after execution (MB).
  final double executionMemoryMB;

  /// Memory usage after post-processing (MB).
  final double postProcessingMemoryMB;

  /// Peak memory observed across all stages (MB).
  final double peakMemoryMB;

  /// Timestamp when the profile was captured.
  final DateTime timestamp;

  ProfileResult({
    required this.modelId,
    required this.preProcessingTime,
    required this.executionTime,
    required this.postProcessingTime,
    required this.preProcessingMemoryMB,
    required this.executionMemoryMB,
    required this.postProcessingMemoryMB,
    required this.peakMemoryMB,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Total inference time across all stages.
  Duration get totalTime =>
      preProcessingTime + executionTime + postProcessingTime;

  /// Percentage of total time spent in pre-processing.
  double get preProcessingPercent => _percent(preProcessingTime);

  /// Percentage of total time spent in model execution.
  double get executionPercent => _percent(executionTime);

  /// Percentage of total time spent in post-processing.
  double get postProcessingPercent => _percent(postProcessingTime);

  double _percent(Duration d) {
    final total = totalTime.inMicroseconds;
    if (total == 0) return 0.0;
    return (d.inMicroseconds / total) * 100.0;
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'timestamp': timestamp.toIso8601String(),
        'preProcessingMs': preProcessingTime.inMicroseconds / 1000.0,
        'executionMs': executionTime.inMicroseconds / 1000.0,
        'postProcessingMs': postProcessingTime.inMicroseconds / 1000.0,
        'totalMs': totalTime.inMicroseconds / 1000.0,
        'preProcessingMemoryMB': preProcessingMemoryMB,
        'executionMemoryMB': executionMemoryMB,
        'postProcessingMemoryMB': postProcessingMemoryMB,
        'peakMemoryMB': peakMemoryMB,
        'preProcessingPercent': preProcessingPercent,
        'executionPercent': executionPercent,
        'postProcessingPercent': postProcessingPercent,
      };

  /// Deserializes from JSON.
  factory ProfileResult.fromJson(Map<String, dynamic> json) {
    return ProfileResult(
      modelId: json['modelId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      preProcessingTime: Duration(
        microseconds: ((json['preProcessingMs'] as num) * 1000).round(),
      ),
      executionTime: Duration(
        microseconds: ((json['executionMs'] as num) * 1000).round(),
      ),
      postProcessingTime: Duration(
        microseconds: ((json['postProcessingMs'] as num) * 1000).round(),
      ),
      preProcessingMemoryMB:
          (json['preProcessingMemoryMB'] as num?)?.toDouble() ?? 0.0,
      executionMemoryMB:
          (json['executionMemoryMB'] as num?)?.toDouble() ?? 0.0,
      postProcessingMemoryMB:
          (json['postProcessingMemoryMB'] as num?)?.toDouble() ?? 0.0,
      peakMemoryMB: (json['peakMemoryMB'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Renders a human-readable Markdown report.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Profile: $modelId');
    buffer.writeln();
    buffer.writeln('- Captured at: ${timestamp.toIso8601String()}');
    buffer.writeln('- Total: ${totalTime.inMilliseconds} ms');
    buffer.writeln();
    buffer.writeln('## Stage Breakdown');
    buffer.writeln();
    buffer.writeln('| Stage | Time (ms) | % | Memory (MB) |');
    buffer.writeln('|-------|-----------|---|-------------|');
    buffer.writeln(
      '| Pre-processing | ${preProcessingTime.inMilliseconds} | '
      '${preProcessingPercent.toStringAsFixed(1)} | '
      '${preProcessingMemoryMB.toStringAsFixed(1)} |',
    );
    buffer.writeln(
      '| Execution | ${executionTime.inMilliseconds} | '
      '${executionPercent.toStringAsFixed(1)} | '
      '${executionMemoryMB.toStringAsFixed(1)} |',
    );
    buffer.writeln(
      '| Post-processing | ${postProcessingTime.inMilliseconds} | '
      '${postProcessingPercent.toStringAsFixed(1)} | '
      '${postProcessingMemoryMB.toStringAsFixed(1)} |',
    );
    buffer.writeln();
    buffer.writeln('Peak memory: ${peakMemoryMB.toStringAsFixed(1)} MB');
    return buffer.toString();
  }

  @override
  String toString() =>
      'ProfileResult($modelId, ${totalTime.inMilliseconds}ms, peak ${peakMemoryMB.toStringAsFixed(1)}MB)';
}
