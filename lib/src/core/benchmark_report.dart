import 'dart:math';

/// Performance benchmark report for AI model inference.
class BenchmarkReport {
  /// Model identifier under test.
  final String modelId;

  /// List of recorded inference times (in milliseconds).
  final List<double> inferenceTimes;

  /// List of recorded memory usages (in MB).
  final List<double> memoryUsages;

  /// Number of benchmark runs completed.
  final int numRuns;

  /// Timestamp when the benchmark run completed.
  final DateTime timestamp;

  /// Constructs a [BenchmarkReport].
  BenchmarkReport({
    required this.modelId,
    required this.inferenceTimes,
    required this.memoryUsages,
    required this.numRuns,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Calculates the p50 (median) percentile.
  double get p50 => _percentile(50);

  /// Calculates the p90 percentile.
  double get p90 => _percentile(90);

  /// Calculates the p99 percentile.
  double get p99 => _percentile(99);

  /// Calculates the minimum value.
  double get min =>
      inferenceTimes.isNotEmpty ? inferenceTimes.reduce(reduceMin) : 0.0;

  /// Calculates the maximum value.
  double get max =>
      inferenceTimes.isNotEmpty ? inferenceTimes.reduce(reduceMax) : 0.0;

  /// Helper for reduce min.
  static double reduceMin(double a, double b) => a < b ? a : b;

  /// Helper for reduce max.
  static double reduceMax(double a, double b) => a > b ? a : b;

  /// Calculates the average (mean) value.
  double get avg => inferenceTimes.isNotEmpty
      ? inferenceTimes.reduce((a, b) => a + b) / inferenceTimes.length
      : 0.0;

  /// Calculates the standard deviation.
  double get stdDev {
    if (inferenceTimes.length < 2) return 0.0;
    final mean = avg;
    final squaredDiffs = inferenceTimes.map((t) => pow(t - mean, 2)).toList();
    final variance =
        squaredDiffs.reduce((a, b) => a + b) / inferenceTimes.length;
    return sqrt(variance);
  }

  /// Calculates the specified percentile.
  double _percentile(int p) {
    if (inferenceTimes.isEmpty) return 0.0;
    final sorted = List<double>.from(inferenceTimes)..sort();
    final index = (p / 100.0) * (sorted.length - 1);
    if (index % 1 == 0) {
      return sorted[index.toInt()];
    }
    final lower = sorted[index.floor()];
    final upper = sorted[index.ceil()];
    return lower + (upper - lower) * (index - index.floor());
  }

  /// Memory usage stats.
  double get memoryP50 => _memoryPercentile(50);

  /// Memory usage p90.
  double get memoryP90 => _memoryPercentile(90);

  /// Memory usage p99.
  double get memoryP99 => _memoryPercentile(99);

  /// Minimum memory usage.
  double get memoryMin =>
      memoryUsages.isNotEmpty ? memoryUsages.reduce(reduceMin) : 0.0;

  /// Maximum memory usage.
  double get memoryMax =>
      memoryUsages.isNotEmpty ? memoryUsages.reduce(reduceMax) : 0.0;

  /// Average memory usage.
  double get memoryAvg => memoryUsages.isNotEmpty
      ? memoryUsages.reduce((a, b) => a + b) / memoryUsages.length
      : 0.0;

  double _memoryPercentile(int p) {
    if (memoryUsages.isEmpty) return 0.0;
    final sorted = List<double>.from(memoryUsages)..sort();
    final index = (p / 100.0) * (sorted.length - 1);
    if (index % 1 == 0) {
      return sorted[index.toInt()];
    }
    final lower = sorted[index.floor()];
    final upper = sorted[index.ceil()];
    return lower + (upper - lower) * (index - index.floor());
  }

  /// Generates a Markdown report.
  String toMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# SATE AI Benchmark Report');
    buffer.writeln();
    buffer.writeln('## Summary');
    buffer.writeln('- **Model:** $modelId');
    buffer.writeln('- **Number of Runs:** $numRuns');
    buffer.writeln('- **Timestamp:** ${timestamp.toIso8601String()}');
    buffer.writeln();
    buffer.writeln('## Inference Time (ms)');
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| Min | ${min.toStringAsFixed(2)} |');
    buffer.writeln('| Max | ${max.toStringAsFixed(2)} |');
    buffer.writeln('| Avg | ${avg.toStringAsFixed(2)} |');
    buffer.writeln('| Std Dev | ${stdDev.toStringAsFixed(2)} |');
    buffer.writeln('| p50 (Median) | ${p50.toStringAsFixed(2)} |');
    buffer.writeln('| p90 | ${p90.toStringAsFixed(2)} |');
    buffer.writeln('| p99 | ${p99.toStringAsFixed(2)} |');
    buffer.writeln();
    buffer.writeln('## Memory Usage (MB)');
    buffer.writeln('| Metric | Value |');
    buffer.writeln('|--------|-------|');
    buffer.writeln('| Min | ${memoryMin.toStringAsFixed(2)} |');
    buffer.writeln('| Max | ${memoryMax.toStringAsFixed(2)} |');
    buffer.writeln('| Avg | ${memoryAvg.toStringAsFixed(2)} |');
    buffer.writeln('| p50 (Median) | ${memoryP50.toStringAsFixed(2)} |');
    buffer.writeln('| p90 | ${memoryP90.toStringAsFixed(2)} |');
    buffer.writeln('| p99 | ${memoryP99.toStringAsFixed(2)} |');

    return buffer.toString();
  }

  /// Generates a JSON representation.
  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'numRuns': numRuns,
        'timestamp': timestamp.toIso8601String(),
        'inferenceTimes': inferenceTimes,
        'memoryUsages': memoryUsages,
        'stats': {
          'inferenceTime': {
            'min': min,
            'max': max,
            'avg': avg,
            'stdDev': stdDev,
            'p50': p50,
            'p90': p90,
            'p99': p99,
          },
          'memoryUsage': {
            'min': memoryMin,
            'max': memoryMax,
            'avg': memoryAvg,
            'p50': memoryP50,
            'p90': memoryP90,
            'p99': memoryP99,
          },
        },
      };

  /// Constructs a [BenchmarkReport] from a JSON map.
  factory BenchmarkReport.fromJson(Map<String, dynamic> json) {
    return BenchmarkReport(
      modelId: json['modelId'] as String,
      inferenceTimes: (json['inferenceTimes'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      memoryUsages: (json['memoryUsages'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      numRuns: json['numRuns'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
