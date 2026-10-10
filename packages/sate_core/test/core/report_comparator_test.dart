import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('ReportComparator', () {
    late StressReport report1;
    late StressReport report2;

    setUp(() {
      report1 = _createReport(
        modelId: 'model-v1',
        passed: true,
        results: [
          _createResult(FaultType.memoryPressure, true, 120, 100.0),
          _createResult(FaultType.malformedInput, true, 80, 0.0),
        ],
      );
      report2 = _createReport(
        modelId: 'model-v2',
        passed: true,
        results: [
          _createResult(FaultType.memoryPressure, true, 130, 110.0),
          _createResult(FaultType.malformedInput, true, 85, 0.0),
        ],
      );
    });

    test('compare returns ReportDiff', () {
      final comparator = ReportComparator();
      final diff = comparator.compare(report1, report2);
      expect(diff, isA<ReportDiff>());
    });

    test('compare detects inference time changes', () {
      final comparator = ReportComparator(tolerancePercent: 5.0);
      final diff = comparator.compare(report1, report2);
      expect(diff.hasChanges, isTrue);
      expect(diff.totalDiffs, greaterThan(0));
    });

    test('compare with high tolerance detects no changes', () {
      final comparator = ReportComparator(tolerancePercent: 20.0);
      final diff = comparator.compare(report1, report2);
      // With 20% tolerance, 10ms change on 120ms is ~8.3%, should be within tolerance
      expect(diff.hasChanges, isFalse);
    });

    test('compare detects pass/fail changes', () {
      final failingReport = _createReport(
        modelId: 'model-fail',
        passed: false,
        results: [
          _createResult(FaultType.memoryPressure, false, 120, 100.0),
        ],
      );
      final comparator = ReportComparator();
      final diff = comparator.compare(report1, failingReport);
      expect(diff.hasChanges, isTrue);
      expect(diff.diffs.any((d) => d.metric.contains('Status')), isTrue);
    });

    test('compare detects added injectors', () {
      final reportWithMore = _createReport(
        modelId: 'model-more',
        passed: true,
        results: [
          _createResult(FaultType.memoryPressure, true, 120, 100.0),
          _createResult(FaultType.malformedInput, true, 80, 0.0),
          _createResult(FaultType.thermalThrottle, true, 150, 50.0),
        ],
      );
      final comparator = ReportComparator();
      final diff = comparator.compare(report1, reportWithMore);
      expect(diff.hasChanges, isTrue);
      expect(diff.diffs.any((d) => d.metric == 'Added Injector'), isTrue);
    });

    test('toMarkdown returns non-empty string', () {
      final comparator = ReportComparator();
      final diff = comparator.compare(report1, report2);
      final markdown = diff.toMarkdown();
      expect(markdown, isNotEmpty);
      expect(markdown, contains('SATE AI Report Comparison'));
      expect(markdown, contains('model-v1'));
    });

    test('toHtml returns non-empty string', () {
      final comparator = ReportComparator();
      final diff = comparator.compare(report1, report2);
      final html = diff.toHtml();
      expect(html, isNotEmpty);
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('SATE AI Report Comparison'));
    });

    test('MetricDiff toJson returns correct map', () {
      final diff = MetricDiff(
        metric: 'test',
        before: '100ms',
        after: '120ms',
        status: DiffStatus.changed,
        message: 'Changed',
      );
      final json = diff.toJson();
      expect(json['metric'], equals('test'));
      expect(json['status'], equals('changed'));
    });

    test('compare with identical reports returns no changes', () {
      final comparator = ReportComparator();
      final diff = comparator.compare(report1, report1);
      expect(diff.hasChanges, isFalse);
      expect(diff.totalDiffs, equals(0));
    });

    test('compare with removed injectors detects removal', () {
      final reportWithLess = _createReport(
        modelId: 'model-less',
        passed: true,
        results: [
          _createResult(FaultType.memoryPressure, true, 120, 100.0),
        ],
      );
      final comparator = ReportComparator();
      final diff = comparator.compare(report1, reportWithLess);
      expect(diff.hasChanges, isTrue);
      expect(diff.diffs.any((d) => d.metric == 'Removed Injector'), isTrue);
    });

    test('compare handles missing fields gracefully', () {
      final report1Simple = StressReport(
        modelId: 'simple-v1',
        passed: true,
        results: const [
          FaultResult(
            injectorType: FaultType.memoryPressure,
            passed: true,
          ),
        ],
        failures: const [],
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        totalDuration: Duration.zero,
      );
      final report2Simple = StressReport(
        modelId: 'simple-v2',
        passed: true,
        results: const [
          FaultResult(
            injectorType: FaultType.memoryPressure,
            passed: true,
            inferenceTime: Duration(milliseconds: 120),
            memoryUsageMB: 100.0,
          ),
        ],
        failures: const [],
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        totalDuration: Duration.zero,
      );
      final comparator = ReportComparator();
      final diff = comparator.compare(report1Simple, report2Simple);
      // Should not crash, and should detect changes
      expect(diff.totalDiffs, greaterThan(0));
    });
  });
}

FaultResult _createResult(
    FaultType type, bool passed, int timeMs, double memoryMB) {
  return FaultResult(
    injectorType: type,
    passed: passed,
    inferenceTime: Duration(milliseconds: timeMs),
    memoryUsageMB: memoryMB,
  );
}

StressReport _createReport({
  required String modelId,
  required bool passed,
  required List<FaultResult> results,
}) {
  return StressReport(
    modelId: modelId,
    passed: passed,
    results: results,
    failures: const [],
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(seconds: 1)),
    totalDuration: const Duration(seconds: 1),
  );
}
