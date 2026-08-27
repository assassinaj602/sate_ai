import 'report.dart';

/// Represents a deviation in a metric during baseline comparison.
class MetricDeviation {
  /// Name of the metric that deviated.
  final String metric;

  /// Expected value from baseline.
  final dynamic expected;

  /// Actual value from current report.
  final dynamic actual;

  /// Percentage deviation.
  final double deviationPercent;

  /// Human-readable message describing deviation.
  final String message;

  /// Constructs a [MetricDeviation].
  MetricDeviation({
    required this.metric,
    required this.expected,
    required this.actual,
    required this.deviationPercent,
    required this.message,
  });

  /// Converts metric deviation to JSON map.
  Map<String, dynamic> toJson() => {
        'metric': metric,
        'expected': expected,
        'actual': actual,
        'deviationPercent': deviationPercent,
        'message': message,
      };
}

/// Result of comparing a report against a baseline.
class BaselineComparison {
  /// Current stress report under evaluation.
  final StressReport report;

  /// Golden baseline report used for comparison.
  final StressReport baseline;

  /// Overall pass/fail result based on deviations and tolerance.
  final bool passed;

  /// List of detected metric deviations.
  final List<MetricDeviation> deviations;

  /// Timestamp when comparison was performed.
  final DateTime comparisonTime;

  /// Constructs a [BaselineComparison].
  BaselineComparison({
    required this.report,
    required this.baseline,
    required this.passed,
    required this.deviations,
    required this.comparisonTime,
  });

  /// Converts baseline comparison into a Markdown document.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Golden Baseline Comparison Report');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln('- **Model:** ${report.modelId}');
    buffer.writeln('- **Status:** ${passed ? "✅ PASSED" : "❌ FAILED"}');
    buffer
        .writeln('- **Comparison Time:** ${comparisonTime.toIso8601String()}');
    buffer.writeln(
        '- **Tolerance:** ${deviations.isEmpty ? "N/A" : "Deviations detected"}');
    buffer.writeln();

    if (deviations.isEmpty) {
      buffer.writeln(
          '✅ No deviations detected. All metrics are within tolerance.');
    } else {
      buffer.writeln('## Deviations Detected');
      buffer.writeln();
      for (final dev in deviations) {
        buffer.writeln('### ${dev.metric}');
        buffer.writeln('- **Expected:** ${dev.expected}');
        buffer.writeln('- **Actual:** ${dev.actual}');
        buffer.writeln('- **Deviation:** ${dev.deviationPercent.round()}%');
        buffer.writeln('- **Message:** ${dev.message}');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Converts comparison result to JSON map.
  Map<String, dynamic> toJson() => {
        'passed': passed,
        'comparisonTime': comparisonTime.toIso8601String(),
        'deviations': deviations.map((d) => d.toJson()).toList(),
      };
}
