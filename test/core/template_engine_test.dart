import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('TemplateEngine', () {
    late StressReport sampleReport;

    setUp(() {
      sampleReport = StressReport(
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
            passed: false,
            inferenceTime: Duration(milliseconds: 200),
            memoryUsageMB: 150.0,
            errorMessage: 'Bad input',
          ),
        ],
        failures: [
          const Failure(
            injectorType: FaultType.malformedInput,
            message: 'Bad input',
          ),
        ],
        startTime: DateTime.parse('2026-09-22T10:00:00Z'),
        endTime: DateTime.parse('2026-09-22T10:00:02Z'),
        totalDuration: const Duration(seconds: 2),
      );
    });

    test('renders simple placeholders', () {
      final out = TemplateEngine.render('Model: {{ model }}', sampleReport);
      expect(out, equals('Model: test-model'));
    });

    test('renders pass/fail emoji', () {
      final out =
          TemplateEngine.render('Status: {{ passed_emoji }}', sampleReport);
      expect(out, equals('Status: PASS'));
    });

    test('renders counts', () {
      final out = TemplateEngine.render(
        '{{ passed_count }}/{{ total_tests }}',
        sampleReport,
      );
      expect(out, equals('1/2'));
    });

    test('renders duration', () {
      final out = TemplateEngine.render('{{ duration_ms }}ms', sampleReport);
      expect(out, equals('2000ms'));
    });

    test('renders memory peak', () {
      final out = TemplateEngine.render('{{ memory_mb }}', sampleReport);
      expect(out, equals('150.0'));
    });

    test('renders failures list', () {
      final out = TemplateEngine.render('{{ failures }}', sampleReport);
      expect(out, contains('Bad input'));
    });

    test('renders results list', () {
      final out = TemplateEngine.render('{{ results }}', sampleReport);
      expect(out, contains('Memory Pressure'));
    });

    test('unknown placeholders become empty', () {
      final out = TemplateEngine.render('{{ unknown_key }}', sampleReport);
      expect(out, isEmpty);
    });

    test('handles templates without placeholders', () {
      final out = TemplateEngine.render('Static text', sampleReport);
      expect(out, equals('Static text'));
    });
  });

  group('TemplateLoader', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sate_tpl');
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('loads JSON templates', () async {
      final file = File('${tempDir.path}/tpl.json');
      await file.writeAsString('{"body": "Hello {{ model }}"}');
      final tpl = TemplateLoader.load(file.path);
      expect(tpl['body'], contains('model'));
    });

    test('loads YAML templates', () async {
      final file = File('${tempDir.path}/tpl.yaml');
      await file.writeAsString('body: |\n  Hello {{ model }}');
      final tpl = TemplateLoader.load(file.path);
      expect(tpl['body'], contains('model'));
    });

    test('throws for missing files', () {
      expect(
        () => TemplateLoader.load('/nonexistent/file.yaml'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('throws for unsupported extensions', () async {
      final file = File('${tempDir.path}/tpl.txt');
      await file.writeAsString('hello');
      expect(
        () => TemplateLoader.load(file.path),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
