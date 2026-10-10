import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

/// Concrete implementation used only in tests to verify the interface.
class _ConcreteInjector implements FaultInjector {
  int injectCalls = 0;
  int resetCalls = 0;

  @override
  FaultType get type => FaultType.latency;

  @override
  String get name => 'Test Injector';

  @override
  String get description => 'Used to verify FaultInjector interface compliance';

  @override
  Future<void> inject() async => injectCalls++;

  @override
  Future<void> reset() async => resetCalls++;
}

void main() {
  group('FaultInjector', () {
    late _ConcreteInjector injector;

    setUp(() => injector = _ConcreteInjector());

    test('type returns the declared FaultType', () {
      expect(injector.type, equals(FaultType.latency));
    });

    test('name returns a non-empty string', () {
      expect(injector.name, isNotEmpty);
    });

    test('description returns a non-empty string', () {
      expect(injector.description, isNotEmpty);
    });

    test('inject() can be called without error', () async {
      await expectLater(injector.inject(), completes);
    });

    test('reset() can be called without error', () async {
      await expectLater(injector.reset(), completes);
    });

    test('inject() increments call counter', () async {
      await injector.inject();
      await injector.inject();
      expect(injector.injectCalls, equals(2));
    });

    test('reset() increments call counter', () async {
      await injector.reset();
      expect(injector.resetCalls, equals(1));
    });

    test('inject() and reset() are independent', () async {
      await injector.inject();
      await injector.inject();
      await injector.reset();
      expect(injector.injectCalls, equals(2));
      expect(injector.resetCalls, equals(1));
    });
  });

  group('FaultType', () {
    test('displayName returns non-empty string for each value', () {
      for (final type in FaultType.values) {
        expect(type.displayName, isNotEmpty,
            reason: 'displayName missing for $type');
      }
    });

    test('icon returns non-empty string for each value', () {
      for (final type in FaultType.values) {
        expect(type.icon, isNotEmpty, reason: 'icon missing for $type');
      }
    });

    test('memoryPressure has correct display name', () {
      expect(FaultType.memoryPressure.displayName, equals('Memory Pressure'));
    });

    test('malformedInput has correct display name', () {
      expect(
        FaultType.malformedInput.displayName,
        equals('Malformed Input'),
      );
    });
  });
}
