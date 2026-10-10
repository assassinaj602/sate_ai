import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

/// A no-op injector that always succeeds.
class _PassInjector implements FaultInjector {
  @override
  FaultType get type => FaultType.latency;
  @override
  String get name => 'Pass Injector';
  @override
  String get description => 'Never causes degradation';
  @override
  Future<void> inject() async {}
  @override
  Future<void> reset() async {}
}

/// An injector that throws during inject().
class _ThrowingInjector implements FaultInjector {
  @override
  FaultType get type => FaultType.networkFailure;
  @override
  String get name => 'Throwing Injector';
  @override
  String get description => 'Throws during inject()';
  @override
  Future<void> inject() async => throw StateError('Simulated inject failure');
  @override
  Future<void> reset() async {}
}

/// An injector that forces the MockAdapter into a degraded state.
class _DegradingInjector implements FaultInjector {
  _DegradingInjector(this._model);
  final MockAdapter _model;

  @override
  FaultType get type => FaultType.thermalThrottle;
  @override
  String get name => 'Degrading Injector';
  @override
  String get description => 'Forces the model into a degraded state';
  @override
  Future<void> inject() async => _model.degraded = true;
  @override
  Future<void> reset() async => _model.reset();
}

void main() {
  group('StressRunner', () {
    late MockAdapter model;

    setUp(() {
      model = MockAdapter(
        inferenceDelay: const Duration(milliseconds: 10),
      );
    });

    // ------------------------------------------------------------------
    // Basic run behaviour
    // ------------------------------------------------------------------

    test('run() returns a StressReport', () async {
      final runner = StressRunner(model: model, injectors: [_PassInjector()]);
      final report = await runner.run();
      expect(report, isA<StressReport>());
    });

    test('run() with zero injectors returns empty report', () async {
      final runner = StressRunner(model: model, injectors: []);
      final report = await runner.run();
      expect(report.results, isEmpty);
      expect(report.failures, isEmpty);
      expect(report.passed, isTrue);
    });

    test('run() with passing injector marks report as passed', () async {
      final runner = StressRunner(model: model, injectors: [_PassInjector()]);
      final report = await runner.run();
      expect(report.passed, isTrue);
      expect(report.results.length, equals(1));
      expect(report.results.first.passed, isTrue);
    });

    test('run() with degrading injector marks report as failed', () async {
      final degrading = _DegradingInjector(model);
      final runner = StressRunner(model: model, injectors: [degrading]);
      final report = await runner.run();
      expect(report.passed, isFalse);
      expect(report.failureCount, greaterThanOrEqualTo(1));
    });

    // ------------------------------------------------------------------
    // Error handling
    // ------------------------------------------------------------------

    test('run() captures unexpected inject() exception in failures list',
        () async {
      final runner = StressRunner(
        model: model,
        injectors: [_ThrowingInjector()],
      );
      final report = await runner.run();
      expect(report.passed, isFalse);
      expect(report.failures.length, equals(1));
      expect(report.failures.first.message, contains('Simulated inject'));
    });

    test('run() continues after one injector throws', () async {
      final runner = StressRunner(
        model: model,
        injectors: [_ThrowingInjector(), _PassInjector()],
      );
      final report = await runner.run();
      // One failure (from throwing), one result (from passing)
      expect(report.failures.length, equals(1));
      expect(report.results.length, equals(1));
    });

    test('run() records modelId from adapter', () async {
      final runner = StressRunner(model: model, injectors: [_PassInjector()]);
      final report = await runner.run();
      expect(report.modelId, equals('mock-model-v1'));
    });

    // ------------------------------------------------------------------
    // Report contents
    // ------------------------------------------------------------------

    test('report totalDuration is positive', () async {
      final runner = StressRunner(model: model, injectors: [_PassInjector()]);
      final report = await runner.run();
      expect(report.totalDuration.inMilliseconds, greaterThan(0));
    });

    test('report startTime is before endTime', () async {
      final runner = StressRunner(model: model, injectors: [_PassInjector()]);
      final report = await runner.run();
      expect(report.startTime.isBefore(report.endTime), isTrue);
    });

    test('report passCount + failureCount == totalTests', () async {
      final runner = StressRunner(
        model: model,
        injectors: [_PassInjector(), _DegradingInjector(model)],
      );
      final report = await runner.run();
      expect(
        report.passCount + report.failureCount,
        equals(report.totalTests),
      );
    });

    test('FaultResult contains inferenceTime when inference succeeds',
        () async {
      final runner = StressRunner(model: model, injectors: [_PassInjector()]);
      final report = await runner.run();
      expect(report.results.first.inferenceTime, isNotNull);
    });

    // ------------------------------------------------------------------
    // Timeout
    // ------------------------------------------------------------------

    test('run() with very short timeout produces failed result', () async {
      final slowModel = MockAdapter(
        inferenceDelay: const Duration(seconds: 5),
      );
      final runner = StressRunner(
        model: slowModel,
        injectors: [_PassInjector()],
        timeout: const Duration(milliseconds: 50),
      );
      final report = await runner.run();
      expect(report.passed, isFalse);
    });
  });
}
