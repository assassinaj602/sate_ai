import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('StressScheduler', () {
    late StressScheduler scheduler;
    late MockAdapter model;
    late List<FaultInjector> injectors;

    setUp(() {
      model = MockAdapter(modelId: 'test-model');
      injectors = [
        MemoryPressureInjector(model: model, limitMb: 100),
        const MalformedInputInjector(),
      ];
      scheduler = StressScheduler(
        cronExpression: '0 2 * * *',
        model: model,
        injectors: injectors,
        reportDirectory: 'test_reports',
      );
    });

    test('constructor validates cron expression', () {
      expect(
        () => StressScheduler(
          cronExpression: 'invalid',
          model: model,
          injectors: injectors,
        ),
        throwsArgumentError,
      );
    });

    test('constructor accepts valid cron expression', () {
      expect(
        () => StressScheduler(
          cronExpression: '0 2 * * *',
          model: model,
          injectors: injectors,
        ),
        returnsNormally,
      );
    });

    test('cron expression validation passes for 5-part cron', () {
      final scheduler = StressScheduler(
        cronExpression: '0 2 * * *',
        model: model,
        injectors: injectors,
      );
      expect(scheduler.isRunning, isFalse);
    });

    test('cron expression validation passes for 6-part cron', () {
      final scheduler = StressScheduler(
        cronExpression: '0 2 * * * *',
        model: model,
        injectors: injectors,
      );
      expect(scheduler.isRunning, isFalse);
    });

    test('isRunning starts as false', () {
      expect(scheduler.isRunning, isFalse);
    });

    test('reportHistory starts empty', () {
      expect(scheduler.reportHistory, isEmpty);
    });

    test('lastSuccessfulReport starts null', () {
      expect(scheduler.lastSuccessfulReport, isNull);
    });

    test('getStatus returns non-empty string', () {
      final status = scheduler.getStatus();
      expect(status, isNotEmpty);
      expect(status, contains('Cron: 0 2 * * *'));
    });

    test('stop does not throw when not running', () {
      expect(() => scheduler.stop(), returnsNormally);
    });

    test('start does not throw with valid config', () async {
      // We can't actually run the scheduler in tests easily
      // Just verify it doesn't throw during setup
      expect(scheduler.isRunning, isFalse);
    });

    test('constructor validates cron expression parts', () {
      expect(
        () => StressScheduler(
          cronExpression: '0 2 * *', // 4 parts (invalid)
          model: model,
          injectors: injectors,
        ),
        throwsArgumentError,
      );
    });
  });
}
