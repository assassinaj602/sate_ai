import 'dart:convert';
import 'dart:io';

import 'fault_type.dart';
import 'metric_deviation.dart';
import 'report.dart';

/// Manages golden baseline comparisons for stress test reports.
///
/// A golden baseline is a previous passing run that serves as a reference
/// for detecting regressions. This class handles:
/// - Saving reports as baselines
/// - Comparing new reports against baselines
/// - Detecting deviations in metrics (inference time, memory usage)
class BaselineManager {
  /// Directory where baselines are stored.
  final String baselineDirectory;

  /// Tolerance for metric deviations (percentage).
  final double tolerancePercent;

  /// Constructs a [BaselineManager].
  BaselineManager({
    this.baselineDirectory = 'baselines',
    this.tolerancePercent = 10.0,
  });

  /// Ensures the baseline directory exists.
  Future<void> _ensureDirectory() async {
    final dir = Directory(baselineDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Saves a report as a golden baseline.
  Future<String> saveBaseline(StressReport report) async {
    await _ensureDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'baseline_${report.modelId}_$timestamp.json';
    final path = '$baselineDirectory/$filename';
    await File(path).writeAsString(report.toJsonString());
    return path;
  }

  /// Loads the most recent baseline for a given model.
  Future<StressReport?> loadBaseline(String modelId) async {
    await _ensureDirectory();
    final dir = Directory(baselineDirectory);
    final files = await dir
        .list()
        .where((entity) =>
            entity is File &&
            entity.path.contains('baseline_${modelId}_') &&
            entity.path.endsWith('.json'))
        .toList();

    if (files.isEmpty) {
      return null;
    }

    // Get the most recent file
    files.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    final latestFile = files.last as File;
    final content = await latestFile.readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;
    return StressReport.fromJson(json);
  }

  /// Compares a report against a baseline.
  ///
  /// Returns a [BaselineComparison] with results.
  BaselineComparison compare(StressReport report, StressReport baseline) {
    final deviations = <MetricDeviation>[];
    var passed = true;

    // Compare pass/fail status
    if (report.passed != baseline.passed) {
      passed = false;
      deviations.add(MetricDeviation(
        metric: 'overall_status',
        expected: baseline.passed,
        actual: report.passed,
        deviationPercent: 100.0,
        message:
            'Overall status changed from ${baseline.passed ? "PASS" : "FAIL"} to ${report.passed ? "PASS" : "FAIL"}',
      ));
    }

    // Compare total tests count
    if (report.results.length != baseline.results.length) {
      passed = false;
      final diff = ((report.results.length - baseline.results.length) /
              baseline.results.length *
              100)
          .abs();
      deviations.add(MetricDeviation(
        metric: 'test_count',
        expected: baseline.results.length,
        actual: report.results.length,
        deviationPercent: diff,
        message:
            'Test count changed from ${baseline.results.length} to ${report.results.length}',
      ));
    }

    // Compare individual injector results
    for (var i = 0;
        i < report.results.length && i < baseline.results.length;
        i++) {
      final current = report.results[i];
      final previous = baseline.results[i];

      // Compare inference time
      if (current.inferenceTime != null && previous.inferenceTime != null) {
        final diffMs = (current.inferenceTime!.inMilliseconds -
                previous.inferenceTime!.inMilliseconds)
            .abs();
        final diffPercent =
            (diffMs / previous.inferenceTime!.inMilliseconds) * 100;
        if (diffPercent > tolerancePercent) {
          passed = false;
          deviations.add(MetricDeviation(
            metric: 'inference_time_${current.injectorType.name}',
            expected: previous.inferenceTime!.inMilliseconds,
            actual: current.inferenceTime!.inMilliseconds,
            deviationPercent: diffPercent,
            message:
                'Inference time for ${current.injectorType.displayName} increased by ${diffPercent.round()}%',
          ));
        }
      }

      // Compare memory usage
      if (current.memoryUsageMB != null && previous.memoryUsageMB != null) {
        final diffMB =
            (current.memoryUsageMB! - previous.memoryUsageMB!).abs();
        final diffPercent = previous.memoryUsageMB! > 0
            ? (diffMB / previous.memoryUsageMB!) * 100
            : 0.0;
        if (diffPercent > tolerancePercent) {
          passed = false;
          deviations.add(MetricDeviation(
            metric: 'memory_usage_${current.injectorType.name}',
            expected: previous.memoryUsageMB!,
            actual: current.memoryUsageMB!,
            deviationPercent: diffPercent,
            message:
                'Memory usage for ${current.injectorType.displayName} increased by ${diffPercent.round()}%',
          ));
        }
      }

      // Compare pass/fail status per injector
      if (current.passed != previous.passed) {
        passed = false;
        deviations.add(MetricDeviation(
          metric: 'status_${current.injectorType.name}',
          expected: previous.passed,
          actual: current.passed,
          deviationPercent: 100.0,
          message:
              '${current.injectorType.displayName} status changed from ${previous.passed ? "PASS" : "FAIL"} to ${current.passed ? "PASS" : "FAIL"}',
        ));
      }
    }

    return BaselineComparison(
      report: report,
      baseline: baseline,
      passed: passed,
      deviations: deviations,
      comparisonTime: DateTime.now(),
    );
  }

  /// Runs a full baseline check for a report.
  ///
  /// Loads the baseline, compares, and returns the comparison.
  /// If no baseline exists, saves the report as baseline and returns null.
  Future<BaselineComparison?> checkAgainstBaseline(StressReport report) async {
    final baseline = await loadBaseline(report.modelId);
    if (baseline == null) {
      // No baseline exists, save this report as baseline
      await saveBaseline(report);
      return null;
    }
    return compare(report, baseline);
  }

  /// Deletes all baselines for a given model.
  Future<void> deleteBaselines(String modelId) async {
    await _ensureDirectory();
    final dir = Directory(baselineDirectory);
    final files = await dir
        .list()
        .where((entity) =>
            entity is File &&
            entity.path.contains('baseline_${modelId}_') &&
            entity.path.endsWith('.json'))
        .toList();

    for (final file in files) {
      await (file as File).delete();
    }
  }

  /// Lists all available baselines.
  Future<List<String>> listBaselines() async {
    await _ensureDirectory();
    final dir = Directory(baselineDirectory);
    final files = await dir
        .list()
        .where((entity) => entity is File && entity.path.endsWith('.json'))
        .toList();
    return files.map((f) => f.path.split(Platform.pathSeparator).last).toList();
  }
}
