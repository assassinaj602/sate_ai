import 'dart:convert';

import '../adapters/model_adapter.dart';
import 'fault_type.dart';

/// The result of a single fault injection + inference cycle.
class FaultResult {
  /// Constructs a [FaultResult].
  const FaultResult({
    required this.injectorType,
    required this.passed,
    this.inferenceTime,
    this.output,
    this.errorMessage,
    this.memoryUsageMB,
  });

  /// Which fault type was tested.
  final FaultType injectorType;

  /// Whether the model survived the fault without degradation.
  final bool passed;

  /// How long the inference took (null if inference was not reached).
  final Duration? inferenceTime;

  /// The raw output from the model (null if inference failed).
  final AIOutput? output;

  /// Error description when [passed] is `false`.
  final String? errorMessage;

  /// Model memory usage in megabytes at the time of this result.
  final double? memoryUsageMB;

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'injectorType': injectorType.name,
        'passed': passed,
        'inferenceTimeMs': inferenceTime?.inMilliseconds,
        'output': output?.toJson(),
        'errorMessage': errorMessage,
        'memoryUsageMB': memoryUsageMB,
      };

  /// Deserialises from a JSON map.
  factory FaultResult.fromJson(Map<String, dynamic> json) {
    return FaultResult(
      injectorType: FaultType.values.firstWhere(
        (e) => e.name == json['injectorType'],
      ),
      passed: json['passed'] as bool,
      inferenceTime: json['inferenceTimeMs'] != null
          ? Duration(milliseconds: json['inferenceTimeMs'] as int)
          : null,
      output: json['output'] != null
          ? AIOutput.fromJson(json['output'] as Map<String, dynamic>)
          : null,
      errorMessage: json['errorMessage'] as String?,
      memoryUsageMB: (json['memoryUsageMB'] as num?)?.toDouble(),
    );
  }

  /// Renders this result as a Markdown section.
  String toMarkdown() {
    final buf = StringBuffer()
      ..writeln(
        '### ${injectorType.icon} ${injectorType.displayName}',
      )
      ..writeln(
        '- **Status**: ${passed ? "✅ PASS" : "❌ FAIL"}',
      );
    if (inferenceTime != null) {
      buf.writeln('- **Inference time**: ${inferenceTime!.inMilliseconds} ms');
    }
    if (memoryUsageMB != null) {
      buf.writeln(
          '- **Memory usage**: ${memoryUsageMB!.toStringAsFixed(1)} MB');
    }
    if (errorMessage != null) {
      buf.writeln('- **Error**: `$errorMessage`');
    }
    return buf.toString();
  }
}

/// Records an unexpected exception that prevented a fault cycle from running.
class Failure {
  /// Constructs a [Failure].
  const Failure({
    required this.injectorType,
    required this.message,
    this.stackTrace,
  });

  /// The fault type whose injector threw the exception.
  final FaultType injectorType;

  /// The exception message.
  final String message;

  /// Stack trace, if captured.
  final StackTrace? stackTrace;

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'injectorType': injectorType.name,
        'message': message,
        'stackTrace': stackTrace?.toString(),
      };

  /// Deserialises from a JSON map.
  factory Failure.fromJson(Map<String, dynamic> json) {
    return Failure(
      injectorType: FaultType.values.firstWhere(
        (e) => e.name == json['injectorType'],
      ),
      message: json['message'] as String,
      stackTrace: json['stackTrace'] != null
          ? StackTrace.fromString(json['stackTrace'] as String)
          : null,
    );
  }
}

/// The aggregated result of a full SATE AI stress test run.
///
/// Obtain via `StressRunner.run` or `SateAI.stress`.
class StressReport {
  /// Constructs a [StressReport].
  const StressReport({
    required this.modelId,
    required this.passed,
    required this.results,
    required this.failures,
    required this.startTime,
    required this.endTime,
    required this.totalDuration,
  });

  /// Identifier of the model under test.
  final String modelId;

  /// `true` only when every injector left the model in a healthy state.
  final bool passed;

  /// Per-injector results (one per `FaultInjector` in the run).
  final List<FaultResult> results;

  /// Injectors that threw unexpected exceptions (not counted in [results]).
  final List<Failure> failures;

  /// When the run started.
  final DateTime startTime;

  /// When the run ended.
  final DateTime endTime;

  /// Wall-clock duration of the entire run.
  final Duration totalDuration;

  // ---------------------------------------------------------------------------
  // Derived metrics
  // ---------------------------------------------------------------------------

  /// Number of injectors where the model failed or degraded.
  int get failureCount => results.where((r) => !r.passed).length;

  /// Number of injectors the model survived successfully.
  int get passCount => results.where((r) => r.passed).length;

  /// Total number of fault cycles executed.
  int get totalTests => results.length;

  // ---------------------------------------------------------------------------
  // Serialisation
  // ---------------------------------------------------------------------------

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'passed': passed,
        'results': results.map((r) => r.toJson()).toList(),
        'failures': failures.map((f) => f.toJson()).toList(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'totalDurationMs': totalDuration.inMilliseconds,
        'summary': {
          'totalTests': totalTests,
          'passed': passCount,
          'failed': failureCount,
          'unexpectedErrors': failures.length,
        },
      };

  /// Deserialises from a JSON map.
  factory StressReport.fromJson(Map<String, dynamic> json) {
    return StressReport(
      modelId: json['modelId'] as String,
      passed: json['passed'] as bool,
      results: (json['results'] as List<dynamic>)
          .map((r) => FaultResult.fromJson(r as Map<String, dynamic>))
          .toList(),
      failures: (json['failures'] as List<dynamic>)
          .map((f) => Failure.fromJson(f as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      totalDuration: Duration(milliseconds: json['totalDurationMs'] as int),
    );
  }

  /// Serialises to a compact JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Renders a human-readable Markdown report.
  String toMarkdown() {
    final buf = StringBuffer()
      ..writeln('# SATE AI Stress Test Report')
      ..writeln()
      ..writeln('## Summary')
      ..writeln('| Key | Value |')
      ..writeln('|---|---|')
      ..writeln('| Model | `$modelId` |')
      ..writeln(
        '| Overall | ${passed ? "✅ PASSED" : "❌ FAILED"} |',
      )
      ..writeln('| Total tests | $totalTests |')
      ..writeln('| Passed | $passCount |')
      ..writeln('| Failed | $failureCount |')
      ..writeln('| Unexpected errors | ${failures.length} |')
      ..writeln('| Duration | ${totalDuration.inMilliseconds} ms |')
      ..writeln()
      ..writeln('## Test Results')
      ..writeln();
    for (final result in results) {
      buf
        ..writeln(result.toMarkdown())
        ..writeln();
    }
    if (failures.isNotEmpty) {
      buf
        ..writeln('## Unexpected Errors')
        ..writeln();
      for (final failure in failures) {
        buf
          ..writeln(
            '### ${failure.injectorType.icon} ${failure.injectorType.displayName}',
          )
          ..writeln('- **Error**: `${failure.message}`');
        if (failure.stackTrace != null) {
          buf
            ..writeln('```')
            ..writeln(failure.stackTrace)
            ..writeln('```');
        }
        buf.writeln();
      }
    }
    return buf.toString();
  }
}
