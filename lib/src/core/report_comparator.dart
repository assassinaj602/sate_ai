import 'fault_type.dart';
import 'report.dart';

/// Status of a metric difference.
enum DiffStatus {
  /// No change detected.
  same,

  /// Value changed.
  changed,

  /// New metric added.
  added,

  /// Metric removed.
  removed,
}

/// Represents a difference between two reports for a single metric.
class MetricDiff {
  /// Name of the metric being compared.
  final String metric;

  /// Value string before change.
  final String before;

  /// Value string after change.
  final String after;

  /// Status of the diff (same, changed, added, removed).
  final DiffStatus status;

  /// Human-readable explanation of the difference.
  final String message;

  /// Constructs a [MetricDiff].
  MetricDiff({
    required this.metric,
    required this.before,
    required this.after,
    required this.status,
    required this.message,
  });

  /// Serialises to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'metric': metric,
        'before': before,
        'after': after,
        'status': status.name,
        'message': message,
      };
}

/// Result of comparing two stress reports.
class ReportDiff {
  /// Baseline / previous stress report.
  final StressReport report1;

  /// Current / new stress report.
  final StressReport report2;

  /// List of individual metric differences.
  final List<MetricDiff> diffs;

  /// Total count of differences found.
  final int totalDiffs;

  /// Whether any meaningful changes were detected beyond tolerance.
  final bool hasChanges;

  /// Tolerance percentage applied when comparing metrics.
  final double tolerancePercent;

  /// Constructs a [ReportDiff].
  ReportDiff({
    required this.report1,
    required this.report2,
    required this.diffs,
    required this.totalDiffs,
    required this.hasChanges,
    required this.tolerancePercent,
  });

  /// Generates a Markdown summary of the diff.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# SATE AI Report Comparison');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln(
        '- **Report 1:** ${report1.modelId} (${report1.startTime.toIso8601String()})');
    buffer.writeln(
        '- **Report 2:** ${report2.modelId} (${report2.startTime.toIso8601String()})');
    buffer.writeln('- **Total Changes:** $totalDiffs');
    buffer.writeln(
        '- **Status:** ${hasChanges ? "⚠️ Changes Detected" : "✅ No Changes"}');
    buffer.writeln('- **Tolerance:** $tolerancePercent%');
    buffer.writeln();

    if (diffs.isEmpty) {
      buffer.writeln('✅ No differences detected. Reports are identical.');
    } else {
      buffer.writeln('## Changes Detected');
      buffer.writeln();
      for (final diff in diffs) {
        final icon = diff.status == DiffStatus.same
            ? '✅'
            : diff.status == DiffStatus.changed
                ? '⚠️'
                : diff.status == DiffStatus.added
                    ? '➕'
                    : '➖';
        buffer.writeln('### $icon ${diff.metric}');
        buffer.writeln('- **Before:** ${diff.before}');
        buffer.writeln('- **After:** ${diff.after}');
        buffer.writeln('- **Message:** ${diff.message}');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Generates HTML for the diff report.
  String toHtml() {
    final buffer = StringBuffer();
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="en">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln(
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>SATE AI Report Comparison</title>');
    buffer.writeln('  <style>');
    buffer.writeln(_htmlStyles());
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="container">');
    buffer.writeln('    <h1>SATE AI Report Comparison</h1>');
    buffer.writeln('    <div class="summary">');
    buffer.writeln(
        '      <p><strong>Report 1:</strong> ${report1.modelId} (${report1.startTime.toIso8601String()})</p>');
    buffer.writeln(
        '      <p><strong>Report 2:</strong> ${report2.modelId} (${report2.startTime.toIso8601String()})</p>');
    buffer.writeln('      <p><strong>Total Changes:</strong> $totalDiffs</p>');
    buffer.writeln(
        '      <p><strong>Status:</strong> ${hasChanges ? "⚠️ Changes Detected" : "✅ No Changes"}</p>');
    buffer.writeln('    </div>');
    buffer.writeln('    <div class="diffs">');
    if (diffs.isEmpty) {
      buffer.writeln(
          '      <p>✅ No differences detected. Reports are identical.</p>');
    } else {
      for (final diff in diffs) {
        final color = diff.status == DiffStatus.same
            ? '#34d399'
            : diff.status == DiffStatus.changed
                ? '#fbbf24'
                : diff.status == DiffStatus.added
                    ? '#60a5fa'
                    : '#f87171';
        buffer.writeln(
            '      <div class="diff-item" style="border-left: 4px solid $color;">');
        buffer.writeln('        <h3>${diff.metric}</h3>');
        buffer
            .writeln('        <p><strong>Before:</strong> ${diff.before}</p>');
        buffer.writeln('        <p><strong>After:</strong> ${diff.after}</p>');
        buffer.writeln(
            '        <p><strong>Message:</strong> ${diff.message}</p>');
        buffer.writeln('      </div>');
      }
    }
    buffer.writeln('    </div>');
    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');
    return buffer.toString();
  }

  String _htmlStyles() {
    return '''
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: 'Segoe UI', sans-serif; background: #0f1117; color: #e4e6ed; padding: 20px; }
.container { max-width: 900px; margin: 0 auto; }
h1 { color: #60a5fa; margin-bottom: 20px; }
.summary { background: #1a1d27; padding: 20px; border-radius: 8px; border: 1px solid #2e3345; margin-bottom: 20px; }
.summary p { margin: 4px 0; }
.diffs { display: flex; flex-direction: column; gap: 12px; }
.diff-item { background: #1a1d27; padding: 16px; border-radius: 8px; border: 1px solid #2e3345; }
.diff-item h3 { color: #e4e6ed; margin-bottom: 8px; }
.diff-item p { color: #a0a5b5; margin: 2px 0; }
''';
  }
}

/// Compares two stress reports and generates a diff.
class ReportComparator {
  /// Tolerance percentage for numeric metric comparisons.
  final double tolerancePercent;

  /// Constructs a [ReportComparator].
  ReportComparator({this.tolerancePercent = 10.0});

  /// Compares two reports and returns a [ReportDiff].
  ReportDiff compare(StressReport report1, StressReport report2) {
    final diffs = <MetricDiff>[];
    var totalDiffs = 0;

    // Compare pass/fail status
    if (report1.passed != report2.passed) {
      totalDiffs++;
      diffs.add(MetricDiff(
        metric: 'Overall Status',
        before: report1.passed ? 'PASS' : 'FAIL',
        after: report2.passed ? 'PASS' : 'FAIL',
        status: DiffStatus.changed,
        message:
            'Status changed from ${report1.passed ? "PASS" : "FAIL"} to ${report2.passed ? "PASS" : "FAIL"}',
      ));
    }

    // Compare number of results
    if (report1.results.length != report2.results.length) {
      totalDiffs++;
      diffs.add(MetricDiff(
        metric: 'Test Count',
        before: '${report1.results.length}',
        after: '${report2.results.length}',
        status: DiffStatus.changed,
        message:
            'Test count changed from ${report1.results.length} to ${report2.results.length}',
      ));
    }

    // Compare individual injector results
    final maxLength = report1.results.length > report2.results.length
        ? report2.results.length
        : report1.results.length;

    for (var i = 0; i < maxLength; i++) {
      final r1 = report1.results[i];
      final r2 = report2.results[i];

      // Compare injector type (should match)
      if (r1.injectorType != r2.injectorType) {
        totalDiffs++;
        diffs.add(MetricDiff(
          metric: 'Injector Type',
          before: r1.injectorType.displayName,
          after: r2.injectorType.displayName,
          status: DiffStatus.changed,
          message:
              'Injector type changed from ${r1.injectorType.displayName} to ${r2.injectorType.displayName}',
        ));
        continue;
      }

      // Compare pass/fail
      if (r1.passed != r2.passed) {
        totalDiffs++;
        diffs.add(MetricDiff(
          metric: '${r1.injectorType.displayName} Status',
          before: r1.passed ? 'PASS' : 'FAIL',
          after: r2.passed ? 'PASS' : 'FAIL',
          status: DiffStatus.changed,
          message:
              '${r1.injectorType.displayName} status changed from ${r1.passed ? "PASS" : "FAIL"} to ${r2.passed ? "PASS" : "FAIL"}',
        ));
      }

      // Compare inference time
      if (r1.inferenceTime != null && r2.inferenceTime != null) {
        final diffMs =
            r2.inferenceTime!.inMilliseconds - r1.inferenceTime!.inMilliseconds;
        final diffPercent = r1.inferenceTime!.inMilliseconds > 0
            ? (diffMs / r1.inferenceTime!.inMilliseconds) * 100
            : 0.0;

        final status = diffPercent.abs() > tolerancePercent
            ? DiffStatus.changed
            : DiffStatus.same;

        if (status == DiffStatus.changed) {
          totalDiffs++;
          diffs.add(MetricDiff(
            metric: '${r1.injectorType.displayName} Inference Time',
            before: '${r1.inferenceTime!.inMilliseconds}ms',
            after: '${r2.inferenceTime!.inMilliseconds}ms',
            status: status,
            message:
                'Inference time changed by ${diffPercent.round()}% (${diffMs > 0 ? "+" : ""}${diffMs}ms)',
          ));
        }
      } else if (r1.inferenceTime != null || r2.inferenceTime != null) {
        totalDiffs++;
        diffs.add(MetricDiff(
          metric: '${r1.injectorType.displayName} Inference Time',
          before: r1.inferenceTime != null
              ? '${r1.inferenceTime!.inMilliseconds}ms'
              : 'N/A',
          after: r2.inferenceTime != null
              ? '${r2.inferenceTime!.inMilliseconds}ms'
              : 'N/A',
          status: DiffStatus.changed,
          message:
              'Inference time changed from ${r1.inferenceTime != null ? "${r1.inferenceTime!.inMilliseconds}ms" : "N/A"} to ${r2.inferenceTime != null ? "${r2.inferenceTime!.inMilliseconds}ms" : "N/A"}',
        ));
      }

      // Compare memory usage
      if (r1.memoryUsageMB != null && r2.memoryUsageMB != null) {
        final diffMB = r2.memoryUsageMB! - r1.memoryUsageMB!;
        final diffPercent =
            r1.memoryUsageMB! > 0 ? (diffMB / r1.memoryUsageMB!) * 100 : 0.0;

        final status = diffPercent.abs() > tolerancePercent
            ? DiffStatus.changed
            : DiffStatus.same;

        if (status == DiffStatus.changed) {
          totalDiffs++;
          diffs.add(MetricDiff(
            metric: '${r1.injectorType.displayName} Memory',
            before: '${r1.memoryUsageMB!.toStringAsFixed(1)}MB',
            after: '${r2.memoryUsageMB!.toStringAsFixed(1)}MB',
            status: status,
            message:
                'Memory usage changed by ${diffPercent.round()}% (${diffMB > 0 ? "+" : ""}${diffMB.toStringAsFixed(1)}MB)',
          ));
        }
      } else if (r1.memoryUsageMB != null || r2.memoryUsageMB != null) {
        totalDiffs++;
        diffs.add(MetricDiff(
          metric: '${r1.injectorType.displayName} Memory',
          before: r1.memoryUsageMB != null
              ? '${r1.memoryUsageMB!.toStringAsFixed(1)}MB'
              : 'N/A',
          after: r2.memoryUsageMB != null
              ? '${r2.memoryUsageMB!.toStringAsFixed(1)}MB'
              : 'N/A',
          status: DiffStatus.changed,
          message:
              'Memory usage changed from ${r1.memoryUsageMB != null ? "${r1.memoryUsageMB!.toStringAsFixed(1)}MB" : "N/A"} to ${r2.memoryUsageMB != null ? "${r2.memoryUsageMB!.toStringAsFixed(1)}MB" : "N/A"}',
        ));
      }
    }

    // Check for added or removed injectors
    if (report1.results.length < report2.results.length) {
      for (var i = report1.results.length; i < report2.results.length; i++) {
        final added = report2.results[i];
        totalDiffs++;
        diffs.add(MetricDiff(
          metric: 'Added Injector',
          before: '—',
          after: added.injectorType.displayName,
          status: DiffStatus.added,
          message: 'New injector added: ${added.injectorType.displayName}',
        ));
      }
    } else if (report1.results.length > report2.results.length) {
      for (var i = report2.results.length; i < report1.results.length; i++) {
        final removed = report1.results[i];
        totalDiffs++;
        diffs.add(MetricDiff(
          metric: 'Removed Injector',
          before: removed.injectorType.displayName,
          after: '—',
          status: DiffStatus.removed,
          message: 'Injector removed: ${removed.injectorType.displayName}',
        ));
      }
    }

    return ReportDiff(
      report1: report1,
      report2: report2,
      diffs: diffs,
      totalDiffs: totalDiffs,
      hasChanges: totalDiffs > 0,
      tolerancePercent: tolerancePercent,
    );
  }
}
