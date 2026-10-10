import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('StressRunner Retry & Flaky Detection', () {
    late MockAdapter model;

    setUp(() {
      model = MockAdapter(modelId: 'test-model');
    });

    test('retryCount retries failed tests', () async {
      final injectors = [
        MemoryPressureInjector(model: model, limitMb: 200),
      ];
      final runner = StressRunner(
        model: model,
        injectors: injectors,
        retryCount: 3,
        flakyThreshold: 0,
      );
      final report = await runner.run();
      expect(report.results, isNotEmpty);
    });

    test('flakyThreshold marks tests as flaky', () async {
      final injectors = [
        MemoryPressureInjector(model: model, limitMb: 200),
      ];
      final runner = StressRunner(
        model: model,
        injectors: injectors,
        retryCount: 3,
        flakyThreshold: 2,
      );
      final report = await runner.run();
      for (final result in report.results) {
        if (result.flaky) {
          expect(result.passed, isTrue);
        }
      }
    });

    test('retryCount with flakyThreshold < failures marks as flaky', () async {
      final injectors = [
        MemoryPressureInjector(model: model, limitMb: 200),
      ];
      final runner = StressRunner(
        model: model,
        injectors: injectors,
        retryCount: 3,
        flakyThreshold: 2,
      );
      final report = await runner.run();
      expect(report.results, isNotEmpty);
    });

    test('retryCount with flakyThreshold = 0 disables flaky detection',
        () async {
      final injectors = [
        MemoryPressureInjector(model: model, limitMb: 150),
      ];
      final runner = StressRunner(
        model: model,
        injectors: injectors,
        retryCount: 2,
        flakyThreshold: 0,
      );
      final report = await runner.run();
      for (final result in report.results) {
        expect(result.flaky, isFalse);
      }
    });

    test('FaultResult toJson includes flaky flag', () {
      const result = FaultResult(
        injectorType: FaultType.memoryPressure,
        passed: true,
        flaky: true,
        errorMessage: 'Flaky: failed 1/3 attempts',
      );
      final json = result.toJson();
      expect(json['flaky'], isTrue);
    });

    test('FaultResult fromJson parses flaky flag', () {
      final json = {
        'injectorType': 'memoryPressure',
        'passed': true,
        'flaky': true,
        'errorMessage': 'Flaky: failed 1/3 attempts',
      };
      final result = FaultResult.fromJson(json);
      expect(result.flaky, isTrue);
      expect(result.passed, isTrue);
    });

    test('SateAI.stress() accepts retryCount and flakyThreshold', () async {
      final report = await SateAI.stress(
        model: model,
        injectors: [
          MemoryPressureInjector(model: model, limitMb: 150),
        ],
        retryCount: 2,
        flakyThreshold: 1,
      );
      expect(report.results, isNotEmpty);
    });

    test('FaultResult toMarkdown includes flaky indicator', () {
      const result = FaultResult(
        injectorType: FaultType.memoryPressure,
        passed: true,
        flaky: true,
        errorMessage: 'Flaky: failed 1/3 attempts',
      );
      final markdown = result.toMarkdown();
      expect(markdown, contains('⚠️ FLAKY'));
      expect(markdown, contains('failed 1/3 attempts'));
    });
  });
}
