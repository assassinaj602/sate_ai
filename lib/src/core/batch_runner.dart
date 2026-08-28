import 'dart:async';
import 'dart:io';

import '../adapters/model_adapter.dart';
import 'fault_injector.dart';
import 'report.dart';
import 'stress_runner.dart';

/// A single batch item to run.
class BatchItem {
  /// Unique identifier for the model under test.
  final String modelId;

  /// Type/framework of the model (e.g. tflite, onnx, fllama).
  final String modelType;

  /// The model adapter instance.
  final AIModelAdapter model;

  /// List of fault injectors to execute.
  final List<FaultInjector> injectors;

  /// Constructs a [BatchItem].
  BatchItem({
    required this.modelId,
    required this.modelType,
    required this.model,
    required this.injectors,
  });
}

/// Result of a single batch item execution.
class BatchResult {
  /// Model ID evaluated.
  final String modelId;

  /// Model type evaluated.
  final String modelType;

  /// Stress report resulting from the test run, if any.
  final StressReport? report;

  /// Whether all stress test injectors passed for this model.
  final bool passed;

  /// Duration of the test execution for this model.
  final Duration duration;

  /// Error message string if an unhandled exception occurred.
  final String? error;

  /// Names of injectors executed.
  final List<String> injectors;

  /// Constructs a [BatchResult].
  BatchResult({
    required this.modelId,
    required this.modelType,
    this.report,
    required this.passed,
    required this.duration,
    this.error,
    required this.injectors,
  });

  /// Converts the batch result into a JSON map.
  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'modelType': modelType,
        'passed': passed,
        'durationMs': duration.inMilliseconds,
        'error': error,
        'injectors': injectors,
        'report': report?.toJson(),
      };
}

/// Progress update for batch execution.
class BatchProgress {
  /// Number of completed batch items.
  final int completed;

  /// Total number of batch items.
  final int total;

  /// Result of the most recently completed batch item.
  final BatchResult currentResult;

  /// Constructs a [BatchProgress].
  BatchProgress({
    required this.completed,
    required this.total,
    required this.currentResult,
  });

  /// Fraction of progress completed (0.0 to 1.0).
  double get progress => total > 0 ? completed / total : 0.0;
}

/// Complete batch report summarizing results across all models tested.
class BatchReport {
  /// Results for individual models.
  final List<BatchResult> items;

  /// Number of models that passed stress testing.
  final int passedCount;

  /// Number of models that failed stress testing.
  final int failedCount;

  /// Total number of models tested.
  final int totalCount;

  /// Timestamp when batch run started.
  final DateTime startTime;

  /// Timestamp when batch run ended.
  final DateTime endTime;

  /// Total duration of the batch run.
  final Duration totalDuration;

  /// Whether items were executed in parallel.
  final bool parallel;

  /// Constructs a [BatchReport].
  BatchReport({
    required this.items,
    required this.passedCount,
    required this.failedCount,
    required this.totalCount,
    required this.startTime,
    required this.endTime,
    required this.totalDuration,
    required this.parallel,
  });

  /// True if all model stress tests passed without failures.
  bool get allPassed => failedCount == 0;

  /// Converts the batch report to a Markdown document.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# SATE AI Batch Stress Test Report');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln('- **Total Models:** $totalCount');
    buffer.writeln('- **Passed:** $passedCount');
    buffer.writeln('- **Failed:** $failedCount');
    buffer.writeln('- **Parallel:** ${parallel ? "Yes" : "No"}');
    buffer.writeln('- **Duration:** ${totalDuration.inSeconds}s');
    buffer.writeln();

    buffer.writeln('## Results');
    buffer.writeln();
    buffer.writeln('| Model | Type | Status | Duration (ms) | Injectors |');
    buffer.writeln('|-------|------|--------|---------------|-----------|');
    for (final item in items) {
      final status = item.passed ? '✅ PASS' : '❌ FAIL';
      final duration = item.duration.inMilliseconds;
      final injectors = item.injectors.join(', ');
      buffer.writeln(
          '| ${item.modelId} | ${item.modelType} | $status | $duration | $injectors |');
    }
    buffer.writeln();

    // Add detailed failures
    final failures = items.where((i) => !i.passed).toList();
    if (failures.isNotEmpty) {
      buffer.writeln('## Failures');
      buffer.writeln();
      for (final failure in failures) {
        buffer.writeln('### ${failure.modelId} (${failure.modelType})');
        buffer.writeln('- **Error:** ${failure.error ?? "Unknown error"}');
        if (failure.report != null) {
          buffer.writeln(
              '- **Details:** ${failure.report!.failures.map((f) => f.message).join(", ")}');
        }
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}

/// Runs stress tests on multiple models in batch mode.
///
/// Supports sequential or parallel execution of stress tests
/// across multiple models or model versions.
class BatchRunner {
  /// Batch items to run.
  final List<BatchItem> items;

  /// Whether to run model tests concurrently.
  final bool parallel;

  /// Timeout per individual injector run.
  final Duration timeout;

  /// Overall timeout per model batch item.
  final Duration batchTimeout;

  /// Optional callback invoked as progress updates occur.
  final Function(BatchProgress)? onProgress;

  /// Constructs a [BatchRunner].
  BatchRunner({
    required this.items,
    this.parallel = false,
    this.timeout = const Duration(seconds: 30),
    this.batchTimeout = const Duration(minutes: 30),
    this.onProgress,
  });

  /// Runs all batch items and returns a batch report.
  Future<BatchReport> run() async {
    final startTime = DateTime.now();
    final results = <BatchResult>[];
    var passedCount = 0;
    var failedCount = 0;

    if (parallel) {
      // Run in parallel
      final futures = items.map((item) => _runItem(item)).toList();
      final itemResults = await Future.wait(futures);
      for (final result in itemResults) {
        results.add(result);
        if (result.passed) {
          passedCount++;
        } else {
          failedCount++;
        }
      }
    } else {
      // Run sequentially
      for (var i = 0; i < items.length; i++) {
        final result = await _runItem(items[i]);
        results.add(result);
        if (result.passed) {
          passedCount++;
        } else {
          failedCount++;
        }

        // Emit progress
        onProgress?.call(BatchProgress(
          completed: i + 1,
          total: items.length,
          currentResult: result,
        ));
      }
    }

    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);

    return BatchReport(
      items: results,
      passedCount: passedCount,
      failedCount: failedCount,
      totalCount: items.length,
      startTime: startTime,
      endTime: endTime,
      totalDuration: totalDuration,
      parallel: parallel,
    );
  }

  /// Runs a single batch item with timeout.
  Future<BatchResult> _runItem(BatchItem item) async {
    final itemStart = DateTime.now();
    String? error;
    StressReport? report;

    try {
      // Run the stress test with timeout
      final runner = StressRunner(
        model: item.model,
        injectors: item.injectors,
        timeout: timeout,
      );
      report = await runner.run().timeout(batchTimeout);
    } catch (e) {
      error = e.toString();
    }

    final itemEnd = DateTime.now();
    final duration = itemEnd.difference(itemStart);

    return BatchResult(
      modelId: item.modelId,
      modelType: item.modelType,
      report: report,
      passed: report?.passed ?? false,
      duration: duration,
      error: error,
      injectors: item.injectors.map((i) => i.name).toList(),
    );
  }
}
