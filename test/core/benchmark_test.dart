import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('Benchmark Mode', () {
    late MockAdapter model;

    setUp(() {
      model = MockAdapter(modelId: 'test-model');
    });

    test('benchmark mode runs without injectors', () async {
      final report = await SateAI.stress(
        model: model,
        injectors: [],
        benchmark: true,
      );
      expect(report.passed, isTrue);
      expect(report.benchmarkReport, isNotNull);
    });

    test('benchmark report contains inference times', () async {
      final report = await SateAI.stress(
        model: model,
        injectors: [],
        benchmark: true,
      );
      final benchmark = report.benchmarkReport!;
      expect(benchmark.inferenceTimes, isNotEmpty);
      expect(benchmark.numRuns, greaterThan(0));
    });

    test('benchmark report contains memory usages', () async {
      final report = await SateAI.stress(
        model: model,
        injectors: [],
        benchmark: true,
      );
      final benchmark = report.benchmarkReport!;
      expect(benchmark.memoryUsages, isNotEmpty);
    });

    test('benchmark report calculates percentiles', () async {
      final report = await SateAI.stress(
        model: model,
        injectors: [],
        benchmark: true,
      );
      final benchmark = report.benchmarkReport!;
      expect(benchmark.p50, greaterThanOrEqualTo(0));
      expect(benchmark.p90, greaterThanOrEqualTo(benchmark.p50));
      expect(benchmark.p99, greaterThanOrEqualTo(benchmark.p90));
    });

    test('benchmark report toMarkdown returns non-empty string', () async {
      final report = await SateAI.stress(
        model: model,
        injectors: [],
        benchmark: true,
      );
      final markdown = report.benchmarkReport!.toMarkdown();
      expect(markdown, isNotEmpty);
      expect(markdown, contains('SATE AI Benchmark Report'));
      expect(markdown, contains('test-model'));
    });

    test('benchmark report toJson returns correct map', () async {
      final report = await SateAI.stress(
        model: model,
        injectors: [],
        benchmark: true,
      );
      final json = report.benchmarkReport!.toJson();
      expect(json['modelId'], equals('test-model'));
      expect(json['numRuns'], greaterThan(0));
      final stats = json['stats'] as Map<String, dynamic>;
      expect(stats.containsKey('inferenceTime'), isTrue);
      expect(stats.containsKey('memoryUsage'), isTrue);
    });

    test('StressRunner with benchmark flag uses benchmark mode', () async {
      final runner = StressRunner(
        model: model,
        injectors: [],
        benchmark: true,
      );
      final report = await runner.run();
      expect(report.benchmarkReport, isNotNull);
    });

    test(
        'StressRunner without benchmark flag does not create benchmark report',
        () async {
      final runner = StressRunner(
        model: model,
        injectors: [
          MemoryPressureInjector(model: model, limitMb: 100),
        ],
        benchmark: false,
      );
      final report = await runner.run();
      expect(report.benchmarkReport, isNull);
    });
  });
}
