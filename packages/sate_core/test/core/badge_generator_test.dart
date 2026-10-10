import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('BadgeGenerator', () {
    late StressReport passReport;
    late StressReport failReport;

    setUp(() {
      passReport = StressReport(
        modelId: 'test-model',
        passed: true,
        results: [
          const FaultResult(
            injectorType: FaultType.memoryPressure,
            passed: true,
            inferenceTime: Duration(milliseconds: 120),
            memoryUsageMB: 100.0,
          ),
          const FaultResult(
            injectorType: FaultType.malformedInput,
            passed: true,
            inferenceTime: Duration(milliseconds: 200),
            memoryUsageMB: 150.0,
          ),
        ],
        failures: [],
        startTime: DateTime.parse('2026-09-24T10:00:00Z'),
        endTime: DateTime.parse('2026-09-24T10:00:02Z'),
        totalDuration: const Duration(seconds: 2),
      );

      failReport = StressReport(
        modelId: 'test-model-failing',
        passed: false,
        results: [
          const FaultResult(
            injectorType: FaultType.memoryPressure,
            passed: false,
            errorMessage: 'OOM',
          ),
        ],
        failures: [
          const Failure(
            injectorType: FaultType.memoryPressure,
            message: 'Out of memory',
          ),
        ],
        startTime: DateTime.parse('2026-09-24T10:00:00Z'),
        endTime: DateTime.parse('2026-09-24T10:00:01Z'),
        totalDuration: const Duration(seconds: 1),
      );
    });

    test('generates pass status badge', () {
      final svg = BadgeGenerator.generateStatusBadge(passReport);
      expect(svg, contains('<svg'));
      expect(svg, contains('SATE AI'));
      expect(svg, contains('PASS'));
      expect(svg, contains('#4c1'));
    });

    test('generates fail status badge', () {
      final svg = BadgeGenerator.generateStatusBadge(failReport);
      expect(svg, contains('<svg'));
      expect(svg, contains('SATE AI'));
      expect(svg, contains('FAIL'));
      expect(svg, contains('#e05d44'));
    });

    test('generates latency badge', () {
      final svg = BadgeGenerator.generateLatencyBadge(passReport);
      expect(svg, contains('stress duration'));
      expect(svg, contains('2000ms'));
      expect(svg, contains('#007ec6'));
    });

    test('generates memory badge with values', () {
      final svg = BadgeGenerator.generateMemoryBadge(passReport);
      expect(svg, contains('peak memory'));
      expect(svg, contains('150.0MB'));
    });

    test('generates memory badge when no memory data', () {
      final noMemReport = StressReport(
        modelId: 'no-mem',
        passed: true,
        results: [
          const FaultResult(
            injectorType: FaultType.malformedInput,
            passed: true,
          ),
        ],
        failures: [],
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        totalDuration: Duration.zero,
      );
      final svg = BadgeGenerator.generateMemoryBadge(noMemReport);
      expect(svg, contains('N/A'));
    });

    test('generates tests count badge', () {
      final svg = BadgeGenerator.generateTestsBadge(passReport);
      expect(svg, contains('stress tests'));
      expect(svg, contains('2/2 passed'));
    });

    test('generates badge by BadgeType enum', () {
      final statusSvg =
          BadgeGenerator.generateBadge(passReport, type: BadgeType.status);
      final latencySvg =
          BadgeGenerator.generateBadge(passReport, type: BadgeType.latency);
      expect(statusSvg, contains('PASS'));
      expect(latencySvg, contains('2000ms'));
    });

    test('generates custom badge with custom label and color', () {
      final svg = BadgeGenerator.generate(
        label: 'custom',
        value: 'active',
        color: '#ff9900',
      );
      expect(svg, contains('custom'));
      expect(svg, contains('active'));
      expect(svg, contains('#ff9900'));
    });

    test('BadgeTypeX.parse correctly parses string options', () {
      expect(BadgeTypeX.parse('status'), equals(BadgeType.status));
      expect(BadgeTypeX.parse('latency'), equals(BadgeType.latency));
      expect(BadgeTypeX.parse('duration'), equals(BadgeType.latency));
      expect(BadgeTypeX.parse('memory'), equals(BadgeType.memory));
      expect(BadgeTypeX.parse('mem'), equals(BadgeType.memory));
      expect(BadgeTypeX.parse('tests'), equals(BadgeType.tests));
      expect(BadgeTypeX.parse('unknown'), equals(BadgeType.status));
    });

    test('StressReport toBadge() generates badge', () {
      final svg = passReport.toBadge();
      expect(svg, contains('PASS'));
    });

    test('StressReport writeBadgeToFile() writes SVG file', () async {
      final tempDir = await Directory.systemTemp.createTemp('sate_badge_test');
      final badgeFile = File('${tempDir.path}/badge.svg');

      try {
        await passReport.writeBadgeToFile(badgeFile.path,
            type: BadgeType.status);
        expect(badgeFile.existsSync(), isTrue);
        final content = await badgeFile.readAsString();
        expect(content, contains('<svg'));
        expect(content, contains('PASS'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('BadgeGenerator saveBadge writes file to disk', () async {
      final tempDir = await Directory.systemTemp.createTemp('sate_badge_save');
      final badgeFile = File('${tempDir.path}/custom.svg');

      try {
        const svgContent = '<svg>test</svg>';
        await BadgeGenerator.saveBadge(badgeFile.path, svgContent);
        expect(badgeFile.existsSync(), isTrue);
        expect(await badgeFile.readAsString(), equals(svgContent));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
