import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('ModelVersionMismatchInjector', () {
    late ModelVersionMismatchInjector injector;
    late MockAdapter model;

    setUp(() {
      injector = ModelVersionMismatchInjector(
        mismatchType: VersionMismatchType.olderVersion,
        expectedVersion: '2.0.0',
        actualVersion: '1.0.0',
        attemptFallback: false,
      );
      model = MockAdapter(modelId: 'test-model');
    });

    // --- Basic interface tests ---

    test('type is FaultType.modelVersionMismatch', () {
      expect(injector.type, equals(FaultType.modelVersionMismatch));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
    });

    test('description contains versions', () {
      expect(injector.description, contains('1.0.0'));
      expect(injector.description, contains('2.0.0'));
    });

    // --- Initial state tests ---

    test('injectionCount starts at 0', () {
      expect(injector.injectionCount, equals(0));
    });

    test('mismatchDetected starts as false', () {
      expect(injector.mismatchDetected, isFalse);
    });

    test('errorMessage starts as null', () {
      expect(injector.errorMessage, isNull);
    });

    // --- Injection tests ---

    test('inject increments injectionCount', () async {
      await injector.inject();
      expect(injector.injectionCount, equals(1));
    });

    test('reset resets all state', () async {
      await injector.inject();
      await injector.inject();
      expect(injector.injectionCount, equals(2));
      expect(injector.errorMessage, isNull);

      // Trigger a mismatch
      injector.detectMismatch();
      expect(injector.mismatchDetected, isTrue);

      await injector.reset();
      expect(injector.injectionCount, equals(0));
      expect(injector.mismatchDetected, isFalse);
      expect(injector.errorMessage, isNull);
    });

    // --- applyTo tests ---

    test('applyTo detects version mismatch and throws error', () async {
      await expectLater(
        injector.applyTo(model),
        throwsA(isA<AIInferenceError>()),
      );
      expect(injector.mismatchDetected, isTrue);
    });

    test('applyTo with fallback succeeds when enabled', () async {
      final fallbackInjector = ModelVersionMismatchInjector(
        mismatchType: VersionMismatchType.olderVersion,
        expectedVersion: '2.0.0',
        actualVersion: '1.0.0',
        attemptFallback: true,
      );
      // Should not throw
      await fallbackInjector.applyTo(model);
      expect(fallbackInjector.mismatchDetected, isFalse);
    });

    test('applyTo with incompatible version throws error even with fallback',
        () async {
      final incompatibleInjector = ModelVersionMismatchInjector(
        mismatchType: VersionMismatchType.incompatible,
        expectedVersion: '2.0.0',
        actualVersion: '1.0.0',
        attemptFallback: true,
      );
      await expectLater(
        incompatibleInjector.applyTo(model),
        throwsA(isA<AIInferenceError>()),
      );
    });

    test('applyTo simulates memory pressure', () async {
      final initialMemory = model.currentMemoryMB;
      // Use an injector that won't throw (no mismatch)
      final matchInjector = ModelVersionMismatchInjector(
        mismatchType: VersionMismatchType.olderVersion,
        expectedVersion: '1.0.0',
        actualVersion: '1.0.0',
        attemptFallback: false,
      );
      await matchInjector.applyTo(model);
      expect(model.currentMemoryMB, greaterThan(initialMemory));
    });

    // --- Version matching tests ---

    test('detectMismatch returns false when versions match', () {
      final matchInjector = ModelVersionMismatchInjector(
        mismatchType: VersionMismatchType.olderVersion,
        expectedVersion: '1.0.0',
        actualVersion: '1.0.0',
      );
      final mismatch = matchInjector.detectMismatch();
      expect(mismatch, isFalse);
      expect(matchInjector.mismatchDetected, isFalse);
    });

    test('detectMismatch returns true when versions differ', () {
      final mismatch = injector.detectMismatch();
      expect(mismatch, isTrue);
      expect(injector.mismatchDetected, isTrue);
      expect(injector.errorMessage, contains('1.0.0'));
    });

    // --- Status tests ---

    test('getStatus returns correct string', () {
      expect(injector.getStatus(), contains('1.0.0'));
      expect(injector.getStatus(), contains('2.0.0'));
    });

    test('getStatus returns correct string after mismatch', () {
      injector.detectMismatch();
      expect(injector.getStatus(), contains('MISMATCH'));
    });

    // --- Constructor asserts ---

    test('constructor asserts valid versions', () {
      expect(
        () => ModelVersionMismatchInjector(expectedVersion: ''),
        throwsAssertionError,
      );
      expect(
        () => ModelVersionMismatchInjector(actualVersion: ''),
        throwsAssertionError,
      );
    });

    test('applyTo with no mismatch does not throw', () async {
      final matchInjector = ModelVersionMismatchInjector(
        mismatchType: VersionMismatchType.olderVersion,
        expectedVersion: '1.0.0',
        actualVersion: '1.0.0',
      );
      // Should not throw
      await matchInjector.applyTo(model);
      expect(true, isTrue); // If we got here, it passed
    });
  });
}
