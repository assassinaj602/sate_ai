import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('StressEvent', () {
    test('StartedEvent toJson returns correct map', () {
      final event = StartedEvent(
        modelId: 'test-model',
        injectorNames: ['MemoryPressure', 'MalformedInput'],
        totalInjectors: 2,
      );
      final json = event.toJson();
      expect(json['type'], equals('started'));
      expect(json['modelId'], equals('test-model'));
      expect(json['totalInjectors'], equals(2));
    });

    test('InjectorStartingEvent toJson returns correct map', () {
      final event = InjectorStartingEvent(
        injectorName: 'MemoryPressure',
        index: 0,
        total: 2,
      );
      final json = event.toJson();
      expect(json['type'], equals('injectorStarting'));
      expect(json['injectorName'], equals('MemoryPressure'));
      expect(json['index'], equals(0));
    });

    test('InjectorCompleteEvent toJson returns correct map', () {
      final event = InjectorCompleteEvent(
        injectorName: 'MemoryPressure',
        passed: true,
        inferenceTimeMs: 150,
        memoryUsageMB: 120.0,
      );
      final json = event.toJson();
      expect(json['type'], equals('injectorComplete'));
      expect(json['passed'], isTrue);
      expect(json['inferenceTimeMs'], equals(150));
    });

    test('InjectorErrorEvent toJson returns correct map', () {
      final event = InjectorErrorEvent(
        injectorName: 'MemoryPressure',
        error: 'Out of memory',
      );
      final json = event.toJson();
      expect(json['type'], equals('injectorError'));
      expect(json['error'], equals('Out of memory'));
    });

    test('FinishedEvent toJson returns correct map', () {
      final event = FinishedEvent(
        passed: true,
        totalTests: 2,
        passedCount: 2,
        failedCount: 0,
        durationMs: 1200,
      );
      final json = event.toJson();
      expect(json['type'], equals('finished'));
      expect(json['passed'], isTrue);
      expect(json['totalTests'], equals(2));
    });

    test('StressRunner emits events during run', () async {
      final events = <StressEvent>[];
      final runner = StressRunner(
        model: MockAdapter(),
        injectors: [
          MemoryPressureInjector(model: MockAdapter(), limitMb: 100),
        ],
        onEvent: (event) => events.add(event),
      );

      await runner.run();

      expect(events, isNotEmpty);
      expect(events.any((e) => e is StartedEvent), isTrue);
      expect(events.any((e) => e is InjectorStartingEvent), isTrue);
      expect(events.any((e) => e is InjectorCompleteEvent), isTrue);
      expect(events.any((e) => e is FinishedEvent), isTrue);
    });
  });
}
