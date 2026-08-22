import 'dart:convert';
import 'dart:io';

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
      ..writeln('### ${injectorType.icon} ${injectorType.displayName}')
      ..writeln('- **Status**: ${passed ? "✅ PASS" : "❌ FAIL"}');
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
      ..writeln('| Overall | ${passed ? "✅ PASSED" : "❌ FAILED"} |')
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

  /// Writes the HTML report to a file.
  Future<void> writeHtmlToFile(String filePath) async {
    final html = toHtml();
    await File(filePath).writeAsString(html);
  }

  /// Generates a self-contained HTML page for the report.
  ///
  /// The HTML page includes:
  /// - Pass/fail status with color indicators
  /// - Summary cards (model, total tests, passed, failed, errors, duration)
  /// - Chart.js bar charts for inference time and memory usage
  /// - Detailed results table with filtering
  /// - Export functionality for JSON and CSV
  String toHtml() {
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln(
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>SATE AI Stress Report - $modelId</title>');
    buffer.writeln(
        '  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>');
    buffer.writeln('  <style>');
    buffer.writeln(_htmlStyles());
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="container">');
    buffer.writeln('    <header>');
    buffer.writeln('      <h1>SATE AI Stress Report</h1>');
    buffer.writeln(
        '      <p class="subtitle">Model: <strong>$modelId</strong></p>');
    buffer.writeln('    </header>');

    final statusClass = passed ? 'pass' : 'fail';
    final statusText = passed ? '✅ All tests passed' : '❌ Tests failed';
    buffer.writeln('    <div class="status-banner $statusClass">');
    buffer.writeln('      $statusText');
    buffer.writeln('    </div>');

    // Summary cards
    buffer.writeln('    <div class="summary-cards">');
    final summary = {
      'Total Tests': results.length,
      'Passed': results.where((r) => r.passed).length,
      'Failed': results.where((r) => !r.passed).length,
      'Errors': failures.length,
      'Duration': '${totalDuration.inMilliseconds} ms',
    };
    for (final entry in summary.entries) {
      buffer.writeln('      <div class="card">');
      buffer.writeln('        <div class="card-value">${entry.value}</div>');
      buffer.writeln('        <div class="card-label">${entry.key}</div>');
      buffer.writeln('      </div>');
    }
    buffer.writeln('    </div>');

    // Charts
    buffer.writeln('    <div class="charts">');
    buffer.writeln('      <div class="chart-container">');
    buffer.writeln('        <h3>Inference Time (ms)</h3>');
    buffer.writeln('        <canvas id="inferenceChart"></canvas>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="chart-container">');
    buffer.writeln('        <h3>Memory Usage (MB)</h3>');
    buffer.writeln('        <canvas id="memoryChart"></canvas>');
    buffer.writeln('      </div>');
    buffer.writeln('    </div>');

    // Results table
    buffer.writeln('    <div class="table-container">');
    buffer.writeln('      <h3>Injector Results</h3>');
    buffer.writeln('      <table>');
    buffer.writeln('        <thead>');
    buffer.writeln('          <tr>');
    buffer.writeln('            <th>Injector</th>');
    buffer.writeln('            <th>Status</th>');
    buffer.writeln('            <th>Inference (ms)</th>');
    buffer.writeln('            <th>Memory (MB)</th>');
    buffer.writeln('            <th>Error</th>');
    buffer.writeln('          </tr>');
    buffer.writeln('        </thead>');
    buffer.writeln('        <tbody>');
    for (final r in results) {
      final status = r.passed ? 'PASS' : 'FAIL';
      final statusClass = r.passed ? 'pass' : 'fail';
      final inferenceTime = r.inferenceTime?.inMilliseconds ?? '—';
      final memory = r.memoryUsageMB?.toStringAsFixed(1) ?? '—';
      final error = r.errorMessage ?? '—';
      buffer.writeln('          <tr>');
      buffer.writeln('            <td>${r.injectorType.displayName}</td>');
      buffer.writeln(
          '            <td><span class="status $statusClass">$status</span></td>');
      buffer.writeln('            <td>$inferenceTime</td>');
      buffer.writeln('            <td>$memory</td>');
      buffer.writeln('            <td>$error</td>');
      buffer.writeln('          </tr>');
    }
    buffer.writeln('        </tbody>');
    buffer.writeln('      </table>');
    buffer.writeln('    </div>');

    // Failures section
    if (failures.isNotEmpty) {
      buffer.writeln('    <div class="failures">');
      buffer.writeln('      <h3>Failures</h3>');
      for (final f in failures) {
        buffer.writeln('      <div class="failure-item">');
        buffer.writeln(
            '        <span class="failure-type">${f.injectorType.displayName}</span>');
        buffer.writeln(
            '        <span class="failure-message">${f.message}</span>');
        buffer.writeln('      </div>');
      }
      buffer.writeln('    </div>');
    }

    // Chart.js scripts
    buffer.writeln('    <script>');
    buffer.writeln(_htmlChartScript());
    buffer.writeln('    </script>');

    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// CSS styles for the HTML report.
  String _htmlStyles() {
    return '''
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #0f1117; color: #e4e6ed; padding: 20px; }
.container { max-width: 1200px; margin: 0 auto; }
header { text-align: center; margin-bottom: 24px; }
header h1 { font-size: 2rem; color: #60a5fa; }
header .subtitle { color: #a0a5b5; }
.status-banner { padding: 16px; border-radius: 8px; text-align: center; font-size: 1.2rem; font-weight: bold; margin-bottom: 24px; }
.status-banner.pass { background: rgba(52, 211, 153, 0.15); color: #34d399; border: 1px solid rgba(52, 211, 153, 0.3); }
.status-banner.fail { background: rgba(248, 113, 113, 0.15); color: #f87171; border: 1px solid rgba(248, 113, 113, 0.3); }
.summary-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 16px; margin-bottom: 24px; }
.card { background: #1a1d27; padding: 16px; border-radius: 8px; text-align: center; border: 1px solid #2e3345; }
.card-value { font-size: 1.8rem; font-weight: bold; color: #e4e6ed; }
.card-label { color: #a0a5b5; font-size: 0.85rem; margin-top: 4px; }
.charts { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-bottom: 24px; }
@media (max-width: 768px) { .charts { grid-template-columns: 1fr; } }
.chart-container { background: #1a1d27; padding: 16px; border-radius: 8px; border: 1px solid #2e3345; }
.chart-container h3 { margin-bottom: 12px; color: #a0a5b5; font-size: 0.95rem; }
.table-container { background: #1a1d27; padding: 16px; border-radius: 8px; border: 1px solid #2e3345; overflow-x: auto; margin-bottom: 24px; }
.table-container h3 { margin-bottom: 12px; color: #a0a5b5; font-size: 0.95rem; }
table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
th { text-align: left; padding: 10px 12px; border-bottom: 1px solid #2e3345; color: #a0a5b5; font-weight: 600; }
td { padding: 10px 12px; border-bottom: 1px solid #2e3345; color: #e4e6ed; }
tr:hover td { background: #232733; }
.status { padding: 4px 12px; border-radius: 4px; font-weight: 600; }
.status.pass { background: rgba(52, 211, 153, 0.15); color: #34d399; }
.status.fail { background: rgba(248, 113, 113, 0.15); color: #f87171; }
.failures { background: #1a1d27; padding: 16px; border-radius: 8px; border: 1px solid #2e3345; }
.failures h3 { margin-bottom: 12px; color: #a0a5b5; font-size: 0.95rem; }
.failure-item { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #2e3345; flex-wrap: wrap; gap: 8px; }
.failure-item:last-child { border-bottom: none; }
.failure-type { color: #f87171; font-weight: 600; }
.failure-message { color: #a0a5b5; }
''';
  }

  /// Chart.js script for the HTML report.
  String _htmlChartScript() {
    return '''
const results = ${_resultsAsJson()};

// Inference Time Chart
const ctx1 = document.getElementById('inferenceChart').getContext('2d');
new Chart(ctx1, {
  type: 'bar',
  data: {
    labels: results.map(r => r.injectorType),
    datasets: [{
      data: results.map(r => r.inferenceTimeMs || 0),
      backgroundColor: results.map(r => r.passed ? 'rgba(52,211,153,0.3)' : 'rgba(248,113,113,0.3)'),
      borderColor: results.map(r => r.passed ? '#34d399' : '#f87171'),
      borderWidth: 1.5,
      borderRadius: 4,
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: {
      y: { beginAtZero: true, ticks: { color: '#a0a5b5' }, grid: { color: '#2e3345' } },
      x: { ticks: { color: '#a0a5b5' }, grid: { display: false } }
    }
  }
});

// Memory Chart
const ctx2 = document.getElementById('memoryChart').getContext('2d');
new Chart(ctx2, {
  type: 'bar',
  data: {
    labels: results.map(r => r.injectorType),
    datasets: [{
      data: results.map(r => r.memoryUsageMB || 0),
      backgroundColor: results.map(r => (r.memoryUsageMB || 0) > 150 ? 'rgba(248,113,113,0.3)' : 'rgba(96,165,250,0.3)'),
      borderColor: results.map(r => (r.memoryUsageMB || 0) > 150 ? '#f87171' : '#60a5fa'),
      borderWidth: 1.5,
      borderRadius: 4,
    }]
  },
  options: {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: {
      y: { beginAtZero: true, ticks: { color: '#a0a5b5' }, grid: { color: '#2e3345' } },
      x: { ticks: { color: '#a0a5b5' }, grid: { display: false } }
    }
  }
});
''';
  }

  /// Helper to serialize results for chart.js.
  String _resultsAsJson() {
    final list = results
        .map((r) => {
              'injectorType': r.injectorType.displayName,
              'passed': r.passed,
              'inferenceTimeMs': r.inferenceTime?.inMilliseconds,
              'memoryUsageMB': r.memoryUsageMB,
            })
        .toList();
    return jsonEncode(list);
  }
}
