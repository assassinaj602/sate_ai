import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('NetworkLatencyDropInjector', () {
    late MockAdapter model;

    setUp(() {
      model = MockAdapter(modelId: 'test-model');
    });

    // --- Latency tests ---

    test('latency injector type is FaultType.networkFailure', () {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.latency,
      );
      expect(injector.type, equals(FaultType.networkFailure));
    });

    test('latency injector name is correct', () {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.latency,
      );
      expect(injector.name, contains('Latency'));
    });

    test('latency injector applyTo adds delay', () async {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.latency,
        latencyMs: 100,
      );
      final stopwatch = Stopwatch()..start();
      await injector.applyTo(model);
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(100));
    });

    test('latency injector applyTo adds jitter', () async {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.latency,
        latencyMs: 200,
      );
      final stopwatch = Stopwatch()..start();
      await injector.applyTo(model);
      stopwatch.stop();
      // Should be around 200ms with jitter
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
      expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(350));
    });

    // --- Timeout tests ---

    test('timeout injector name is correct', () {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.timeout,
      );
      expect(injector.name, contains('Timeout'));
    });

    test('timeout injector applyTo throws AIInferenceError', () async {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.timeout,
        timeoutMs: 100,
      );
      await expectLater(
        injector.applyTo(model),
        throwsA(isA<AIInferenceError>()),
      );
    });

    // --- Disconnection tests ---

    test('disconnection injector name is correct', () {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.disconnection,
      );
      expect(injector.name, contains('Disconnection'));
    });

    test('disconnection injector applyTo throws AIInferenceError', () async {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.disconnection,
      );
      expect(injector.isDisconnected, isFalse);
      await expectLater(
        injector.applyTo(model),
        throwsA(isA<AIInferenceError>()),
      );
      expect(injector.isDisconnected, isTrue);
    });

    test('disconnection injector reset clears disconnection state', () async {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.disconnection,
      );
      await expectLater(
        injector.applyTo(model),
        throwsA(isA<AIInferenceError>()),
      );
      expect(injector.isDisconnected, isTrue);
      await injector.reset();
      expect(injector.isDisconnected, isFalse);
    });

    test('getStatus returns correct string for each failure type', () {
      final latencyInjector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.latency,
        latencyMs: 500,
      );
      expect(latencyInjector.getStatus(), contains('500ms'));

      final timeoutInjector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.timeout,
        timeoutMs: 3000,
      );
      expect(timeoutInjector.getStatus(), contains('3000ms'));

      final disconnectionInjector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.disconnection,
      );
      expect(disconnectionInjector.getStatus(), contains('NO'));
    });

    test('applyTo simulates memory pressure', () async {
      final injector = NetworkLatencyDropInjector(
        failureType: NetworkFailureType.latency,
        latencyMs: 10,
      );
      final initialMemory = model.currentMemoryMB;
      await injector.applyTo(model);
      expect(model.currentMemoryMB, greaterThan(initialMemory));
    });

    test('constructor asserts valid parameters', () {
      expect(
        () => NetworkLatencyDropInjector(latencyMs: -1),
        throwsAssertionError,
      );
      expect(
        () => NetworkLatencyDropInjector(timeoutMs: -1),
        throwsAssertionError,
      );
    });

    test('inject method completes without error', () async {
      final injector = NetworkLatencyDropInjector();
      await injector.inject();
      expect(injector.injectionCount, equals(1));
    });
  });
}
