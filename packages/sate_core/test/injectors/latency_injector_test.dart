import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('LatencyInjector', () {
    late LatencyInjector injector;
    late MockAdapter model;

    setUp(() {
      model = MockAdapter(modelId: 'test-model');
      injector = LatencyInjector(
        model: model,
        baseDelayMs: 10,
        incrementMs: 5,
        maxLatencyMs: 50,
      );
    });

    test('type is FaultType.latency', () {
      expect(injector.type, equals(FaultType.latency));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
    });

    test('description contains parameters', () {
      expect(injector.description, contains('5'));
      expect(injector.description, contains('50'));
    });

    test('totalLatencyMs starts at 0', () {
      expect(injector.totalLatencyMs, equals(0));
    });

    test('isDegraded starts as false', () {
      expect(injector.isDegraded, isFalse);
    });

    test('inject() increases latency cumulatively', () async {
      await injector.inject(); // 10+0*5=10, total=10
      await injector.inject(); // 10+1*5=15, total=25
      await injector.inject(); // 10+2*5=20, total=45
      expect(injector.totalLatencyMs, equals(45));
      expect(injector.latencyHistory, hasLength(3));
      expect(injector.latencyHistory[2], equals(45));
    });

    test('inject() marks degraded when totalLatencyMs >= maxLatencyMs',
        () async {
      // 3 injections: total=45 (not degraded yet)
      for (var i = 0; i < 3; i++) {
        await injector.inject();
      }
      expect(injector.isDegraded, isFalse);
      // 4th injection: adds 10+3*5=25, total=70 >=50
      await injector.inject();
      expect(injector.isDegraded, isTrue);
    });

    test('reset() resets all state', () async {
      for (var i = 0; i < 4; i++) {
        await injector.inject();
      }
      expect(injector.totalLatencyMs, greaterThan(0));
      expect(injector.isDegraded, isTrue);

      await injector.reset();
      expect(injector.totalLatencyMs, equals(0));
      expect(injector.isDegraded, isFalse);
      expect(injector.latencyHistory, isEmpty);
    });

    test('inject() simulates memory pressure', () async {
      final initialMemory = model.currentMemoryMB;
      await injector.inject();
      expect(model.currentMemoryMB, greaterThan(initialMemory));
    });

    test('inject() marks model as degraded on MockAdapter', () async {
      // Need enough injections to reach MockAdapter degradation threshold (>150MB)
      // Latency memory pressure is roughly totalLatencyMs / 20.
      // 1: delay 10 -> memory 0
      // 2: delay 15 -> memory 25 / 20 = 1
      // 3: delay 20 -> memory 45 / 20 = 2
      // 4: delay 25 -> memory 70 / 20 = 3
      // 5: delay 30 -> memory 100 / 20 = 5 (+30 extra) = 35 MB
      // To push MockAdapter beyond 150MB:
      for (var i = 0; i < 15; i++) {
        await injector.inject();
      }
      expect(model.isDegraded, isTrue);
    });

    test('getStatus() returns correct string', () {
      expect(injector.getStatus(), contains('Normal'));
      expect(injector.getStatus(), contains('0ms'));
    });

    test('constructor assertions work', () {
      expect(
        () => LatencyInjector(model: model, baseDelayMs: -1),
        throwsAssertionError,
      );
      expect(
        () => LatencyInjector(model: model, incrementMs: -1),
        throwsAssertionError,
      );
      expect(
        () => LatencyInjector(model: model, maxLatencyMs: 0),
        throwsAssertionError,
      );
    });
  });
}
