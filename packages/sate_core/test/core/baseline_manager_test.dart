import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('BaselineManager', () {
    late BaselineManager manager;
    late StressReport sampleReport;
    late String testDir;

    setUp(() async {
      testDir = await Directory.systemTemp
          .createTemp('baseline_test')
          .then((d) => d.path);
      manager = BaselineManager(
        baselineDirectory: '$testDir/baselines',
        tolerancePercent: 10.0,
      );
      sampleReport = _createSampleReport();
    });

    tearDown(() async {
      await Directory(testDir).delete(recursive: true);
    });

    test('saves baseline successfully', () async {
      final path = await manager.saveBaseline(sampleReport);
      expect(path, contains('baseline_${sampleReport.modelId}_'));
      expect(path, endsWith('.json'));
      expect(await File(path).exists(), isTrue);
    });

    test('loads baseline successfully', () async {
      await manager.saveBaseline(sampleReport);
      final loaded = await manager.loadBaseline(sampleReport.modelId);
      expect(loaded, isNotNull);
      expect(loaded!.modelId, equals(sampleReport.modelId));
    });

    test('returns null when no baseline exists', () async {
      final loaded = await manager.loadBaseline('nonexistent');
      expect(loaded, isNull);
    });

    test('compares identical reports passes', () async {
      await manager.saveBaseline(sampleReport);
      final comparison = await manager.checkAgainstBaseline(sampleReport);
      expect(comparison, isNotNull);
      expect(comparison!.passed, isTrue);
      expect(comparison.deviations, isEmpty);
    });

    test('compares different reports detects regressions', () async {
      await manager.saveBaseline(sampleReport);
      final differentReport = _createDifferentReport();
      final comparison = await manager.checkAgainstBaseline(differentReport);
      expect(comparison, isNotNull);
      expect(comparison!.passed, isFalse);
      expect(comparison.deviations, isNotEmpty);
    });

    test('deletes baselines for a model', () async {
      await manager.saveBaseline(sampleReport);
      expect(await manager.loadBaseline(sampleReport.modelId), isNotNull);
      await manager.deleteBaselines(sampleReport.modelId);
      expect(await manager.loadBaseline(sampleReport.modelId), isNull);
    });

    test('lists available baselines', () async {
      await manager.saveBaseline(sampleReport);
      final list = await manager.listBaselines();
      expect(list, isNotEmpty);
      expect(list.first, contains('baseline_${sampleReport.modelId}_'));
    });

    test('toMarkdown returns non-empty string', () {
      final comparison = manager.compare(sampleReport, sampleReport);
      final markdown = comparison.toMarkdown();
      expect(markdown, isNotEmpty);
      expect(markdown, contains('Golden Baseline Comparison Report'));
      expect(markdown, contains(sampleReport.modelId));
    });

    test('toJson returns valid map', () {
      final comparison = manager.compare(sampleReport, sampleReport);
      final json = comparison.toJson();
      expect(json, isNotNull);
      expect(json['passed'], isTrue);
      expect(json['comparisonTime'], isNotNull);
    });
  });
}

StressReport _createSampleReport() {
  final results = [
    const FaultResult(
      injectorType: FaultType.memoryPressure,
      passed: true,
      inferenceTime: Duration(milliseconds: 120),
      memoryUsageMB: 120.0,
    ),
    const FaultResult(
      injectorType: FaultType.malformedInput,
      passed: true,
      inferenceTime: Duration(milliseconds: 80),
      memoryUsageMB: 0.0,
    ),
  ];
  return StressReport(
    modelId: 'test-model',
    passed: true,
    results: results,
    failures: const [],
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(seconds: 1)),
    totalDuration: const Duration(seconds: 1),
  );
}

StressReport _createDifferentReport() {
  final results = [
    const FaultResult(
      injectorType: FaultType.memoryPressure,
      passed: false,
      inferenceTime: Duration(milliseconds: 250),
      memoryUsageMB: 180.0,
      errorMessage: 'Memory limit exceeded',
    ),
    const FaultResult(
      injectorType: FaultType.malformedInput,
      passed: true,
      inferenceTime: Duration(milliseconds: 90),
      memoryUsageMB: 0.0,
    ),
  ];
  return StressReport(
    modelId: 'test-model',
    passed: false,
    results: results,
    failures: const [
      Failure(
        injectorType: FaultType.memoryPressure,
        message: 'Memory limit exceeded',
      ),
    ],
    startTime: DateTime.now(),
    endTime: DateTime.now().add(const Duration(seconds: 1)),
    totalDuration: const Duration(seconds: 1),
  );
}
