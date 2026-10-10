import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('BatchRunner', () {
    late MockAdapter model1;
    late MockAdapter model2;
    late List<BatchItem> items;

    setUp(() {
      model1 = MockAdapter(modelId: 'model-1');
      model2 = MockAdapter(modelId: 'model-2');
      items = [
        BatchItem(
          modelId: 'model-1',
          modelType: 'mock',
          model: model1,
          injectors: [
            MemoryPressureInjector(model: model1, limitMb: 100),
          ],
        ),
        BatchItem(
          modelId: 'model-2',
          modelType: 'mock',
          model: model2,
          injectors: [
            MemoryPressureInjector(model: model2, limitMb: 100),
          ],
        ),
      ];
    });

    test('runs batch sequentially', () async {
      final runner = BatchRunner(
        items: items,
        parallel: false,
      );
      final report = await runner.run();
      expect(report.totalCount, equals(2));
      expect(report.passedCount, equals(2));
      expect(report.failedCount, equals(0));
      expect(report.allPassed, isTrue);
    });

    test('runs batch in parallel', () async {
      final runner = BatchRunner(
        items: items,
        parallel: true,
      );
      final report = await runner.run();
      expect(report.totalCount, equals(2));
      expect(report.allPassed, isTrue);
    });

    test('parallel flag is correctly set in report', () async {
      final runner = BatchRunner(
        items: items,
        parallel: true,
      );
      final report = await runner.run();
      expect(report.parallel, isTrue);
    });

    test('batch handles failures', () async {
      // Force a failure by using a high memory limit
      final failingItems = [
        BatchItem(
          modelId: 'failing-model',
          modelType: 'mock',
          model: model1,
          injectors: [
            MemoryPressureInjector(model: model1, limitMb: 200),
          ],
        ),
      ];
      final runner = BatchRunner(
        items: failingItems,
        parallel: false,
      );
      final report = await runner.run();
      expect(report.failedCount, greaterThan(0));
    });

    test('toMarkdown returns non-empty string', () async {
      final runner = BatchRunner(items: items);
      final report = await runner.run();
      final markdown = report.toMarkdown();
      expect(markdown, isNotEmpty);
      expect(markdown, contains('Batch Stress Test Report'));
      expect(markdown, contains('model-1'));
      expect(markdown, contains('model-2'));
    });

    test('BatchResult toJson returns correct map', () {
      final result = BatchResult(
        modelId: 'test-model',
        modelType: 'mock',
        report: null,
        passed: true,
        duration: const Duration(milliseconds: 100),
        error: null,
        injectors: ['MemoryPressure'],
      );
      final json = result.toJson();
      expect(json['modelId'], equals('test-model'));
      expect(json['passed'], isTrue);
      expect(json['durationMs'], equals(100));
    });

    test('batch respects timeout', () async {
      final longItems = [
        BatchItem(
          modelId: 'slow-model',
          modelType: 'mock',
          model: model1,
          injectors: [],
        ),
      ];
      final runner = BatchRunner(
        items: longItems,
        timeout: const Duration(seconds: 1),
        batchTimeout: const Duration(seconds: 5),
      );
      final report = await runner.run();
      expect(report.totalCount, equals(1));
    });

    test('progress callback works', () async {
      var progressCalled = false;
      final runner = BatchRunner(
        items: items,
        onProgress: (progress) {
          progressCalled = true;
          expect(progress.completed, greaterThan(0));
          expect(progress.total, equals(2));
        },
      );
      await runner.run();
      expect(progressCalled, isTrue);
    });

    test('constructor with empty items works', () async {
      final runner = BatchRunner(items: []);
      final report = await runner.run();
      expect(report.totalCount, equals(0));
      expect(report.allPassed, isTrue);
    });
  });
}
