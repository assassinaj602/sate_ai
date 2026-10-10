import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('MalformedInputInjector', () {
    const injector = MalformedInputInjector();

    // ------------------------------------------------------------------
    // Interface compliance
    // ------------------------------------------------------------------

    test('type is FaultType.malformedInput', () {
      expect(injector.type, equals(FaultType.malformedInput));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
    });

    test('description is non-empty', () {
      expect(injector.description, isNotEmpty);
    });

    test('inject() completes without error', () async {
      await expectLater(injector.inject(), completes);
    });

    test('reset() completes without error', () async {
      await expectLater(injector.reset(), completes);
    });

    // ------------------------------------------------------------------
    // generate() factory
    // ------------------------------------------------------------------

    test('generate() returns an AIInput', () {
      final input = MalformedInputInjector.generate();
      expect(input, isA<AIInput>());
    });

    test('generate(empty) returns empty text input', () {
      final input =
          MalformedInputInjector.generateKind(MalformedInputKind.empty);
      expect(input.text, equals(''));
    });

    test('generate(oversized) returns a 1 MB text input', () {
      final input =
          MalformedInputInjector.generateKind(MalformedInputKind.oversized);
      expect(input.text!.length, equals(1024 * 1024));
    });

    test('generate(binaryGarbage) returns binary input with 1024 bytes', () {
      final input =
          MalformedInputInjector.generateKind(MalformedInputKind.binaryGarbage);
      expect(input.binary, isNotNull);
      expect(input.binary!.length, equals(1024));
    });

    // ------------------------------------------------------------------
    // isHandledGracefully()
    // ------------------------------------------------------------------

    test('isHandledGracefully returns true for normal output', () {
      const output = AIOutput(
        text: 'Hello world',
        inferenceTime: Duration(milliseconds: 100),
        confidence: 0.9,
      );
      expect(MalformedInputInjector.isHandledGracefully(output), isTrue);
    });

    test('isHandledGracefully returns false for empty output', () {
      const output = AIOutput(
        text: '',
        inferenceTime: Duration(milliseconds: 10),
      );
      expect(MalformedInputInjector.isHandledGracefully(output), isFalse);
    });

    test('isHandledGracefully returns false when output contains "exception"',
        () {
      const output = AIOutput(
        text: 'Unhandled exception in model',
        inferenceTime: Duration(milliseconds: 10),
      );
      expect(MalformedInputInjector.isHandledGracefully(output), isFalse);
    });

    // ------------------------------------------------------------------
    // Integration: run against MockAdapter
    // ------------------------------------------------------------------

    test('MockAdapter handles empty input gracefully', () async {
      final model = MockAdapter(
        inferenceDelay: const Duration(milliseconds: 10),
      );
      final input =
          MalformedInputInjector.generateKind(MalformedInputKind.empty);
      final output = await model.runInference(input);
      expect(MalformedInputInjector.isHandledGracefully(output), isTrue);
    });

    test('MockAdapter handles oversized input gracefully', () async {
      final model = MockAdapter(
        inferenceDelay: const Duration(milliseconds: 10),
      );
      final input =
          MalformedInputInjector.generateKind(MalformedInputKind.oversized);
      final output = await model.runInference(input);
      expect(MalformedInputInjector.isHandledGracefully(output), isTrue);
    });

    test('MockAdapter handles binary garbage gracefully', () async {
      final model = MockAdapter(
        inferenceDelay: const Duration(milliseconds: 10),
      );
      final input = MalformedInputInjector.generateKind(
        MalformedInputKind.binaryGarbage,
      );
      final output = await model.runInference(input);
      expect(output, isA<AIOutput>());
    });
  });
}
