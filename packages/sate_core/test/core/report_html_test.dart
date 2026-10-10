import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('StressReport HTML Export', () {
    test('toHtml returns a non-empty string', () {
      final report = _createSampleReport();
      final html = report.toHtml();
      expect(html, isNotEmpty);
      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('SATE AI Stress Report'));
    });

    test('toHtml contains pass/fail status', () {
      final report = _createSampleReport();
      final html = report.toHtml();
      expect(html, contains('✅ All tests passed'));
      expect(html, contains('PASS'));
    });

    test('toHtml contains summary cards', () {
      final report = _createSampleReport();
      final html = report.toHtml();
      expect(html, contains('Total Tests'));
      expect(html, contains('Passed'));
      expect(html, contains('Failed'));
    });

    test('toHtml contains chart containers', () {
      final report = _createSampleReport();
      final html = report.toHtml();
      expect(html, contains('inferenceChart'));
      expect(html, contains('memoryChart'));
      expect(html, contains('chart.js'));
    });

    test('toHtml contains results table', () {
      final report = _createSampleReport();
      final html = report.toHtml();
      expect(html, contains('Injector Results'));
      expect(html, contains('Memory Pressure'));
      expect(html, contains('Malformed Input'));
    });

    test('toHtml contains failure section when failures exist', () {
      final report = _createFailingReport();
      final html = report.toHtml();
      expect(html, contains('Failures'));
      expect(html, contains('Memory Pressure'));
    });

    test('toHtml is valid HTML', () {
      final report = _createSampleReport();
      final html = report.toHtml();
      // Check for closing tags
      expect(html, contains('</html>'));
      expect(html, contains('</body>'));
      expect(html, contains('</div>'));
    });

    test('writeHtmlToFile writes a file', () async {
      final tempDir = await Directory.systemTemp.createTemp('sate_ai_test');
      final filePath = '${tempDir.path}/report.html';
      final report = _createSampleReport();
      await report.writeHtmlToFile(filePath);
      expect(await File(filePath).exists(), isTrue);
      final content = await File(filePath).readAsString();
      expect(content, contains('SATE AI Stress Report'));
      await tempDir.delete(recursive: true);
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

StressReport _createFailingReport() {
  final results = [
    const FaultResult(
      injectorType: FaultType.memoryPressure,
      passed: false,
      inferenceTime: Duration(milliseconds: 120),
      memoryUsageMB: 160.0,
      errorMessage: 'Memory limit exceeded',
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
