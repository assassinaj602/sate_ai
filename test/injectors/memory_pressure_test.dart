import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('MemoryPressureInjector', () {
    late MockAdapter model;
    late MemoryPressureInjector injector;

    setUp(() {
      model = MockAdapter(
        inferenceDelay: const Duration(milliseconds: 10),
      );
      injector = MemoryPressureInjector(model: model, limitMb: 50);
    });

    test('type is FaultType.memoryPressure', () {
      expect(injector.type, equals(FaultType.memoryPressure));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
    });

    test('description mentions limitMb', () {
      expect(injector.description, contains('50'));
    });

    test('inject() increases model currentMemoryMB', () async {
      final before = model.currentMemoryMB;
      await injector.inject();
      expect(model.currentMemoryMB, greaterThan(before));
    });

    test('inject() with limitMb > 150 triggers model degradation', () async {
      final highPressure = MemoryPressureInjector(model: model, limitMb: 200);
      await highPressure.inject();
      expect(model.isDegraded, isTrue);
    });

    test('reset() clears model memory and degradation', () async {
      await injector.inject();
      await injector.reset();
      expect(model.currentMemoryMB, equals(0.0));
      expect(model.isDegraded, isFalse);
    });

    test('reset() is idempotent (safe to call twice)', () async {
      await injector.reset();
      await expectLater(injector.reset(), completes);
    });

    test('inject() followed by reset() leaves model healthy', () async {
      await injector.inject();
      await injector.reset();
      final healthy = await model.isHealthy();
      expect(healthy, isTrue);
    });
  });
}
