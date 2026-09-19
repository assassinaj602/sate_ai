import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('HealthCheckResult', () {
    test('passed factory creates a passing result', () {
      final result = HealthCheckResult.passed(
        modelId: 'test',
        duration: const Duration(milliseconds: 100),
        outputText: 'hello',
        confidence: 0.9,
      );
      expect(result.passed, isTrue);
      expect(result.outputText, equals('hello'));
      expect(result.confidence, equals(0.9));
      expect(result.errorMessage, isNull);
    });

    test('failed factory creates a failing result', () {
      final result = HealthCheckResult.failed(
        modelId: 'test',
        duration: const Duration(milliseconds: 50),
        errorMessage: 'boom',
      );
      expect(result.passed, isFalse);
      expect(result.errorMessage, equals('boom'));
      expect(result.outputText, isNull);
    });

    test('toJson serializes all fields', () {
      final result = HealthCheckResult.passed(
        modelId: 'test',
        duration: const Duration(milliseconds: 100),
        outputText: 'hello',
        confidence: 0.9,
      );
      final json = result.toJson();
      expect(json['modelId'], equals('test'));
      expect(json['passed'], isTrue);
      expect(json['durationMs'], equals(100));
      expect(json['outputText'], equals('hello'));
    });

    test('fromJson round-trips correctly', () {
      final original = HealthCheckResult.passed(
        modelId: 'test',
        duration: const Duration(milliseconds: 100),
        outputText: 'hello',
        confidence: 0.9,
      );
      final restored = HealthCheckResult.fromJson(original.toJson());
      expect(restored.modelId, equals(original.modelId));
      expect(restored.passed, equals(original.passed));
      expect(
        restored.duration.inMilliseconds,
        equals(original.duration.inMilliseconds),
      );
      expect(restored.outputText, equals(original.outputText));
    });

    test('toMarkdown contains status', () {
      final result = HealthCheckResult.passed(
        modelId: 'test',
        duration: const Duration(milliseconds: 100),
        outputText: 'hello',
      );
      expect(result.toMarkdown(), contains('PASSED'));
      expect(result.toMarkdown(), contains('test'));
    });

    test('failed toMarkdown contains FAILED and error', () {
      final result = HealthCheckResult.failed(
        modelId: 'err-test',
        duration: const Duration(milliseconds: 50),
        errorMessage: 'something went wrong',
      );
      expect(result.toMarkdown(), contains('FAILED'));
      expect(result.toMarkdown(), contains('something went wrong'));
    });

    test('toString is readable', () {
      final result = HealthCheckResult.passed(
        modelId: 'test',
        duration: const Duration(milliseconds: 100),
        outputText: 'hello',
      );
      expect(result.toString(), contains('test'));
      expect(result.toString(), contains('passed: true'));
    });
  });

  group('SateAI.healthCheck', () {
    test('passes for a healthy MockAdapter', () async {
      final model = MockAdapter(modelId: 'healthy-model');
      final result = await SateAI.healthCheck(model: model);
      expect(result.passed, isTrue);
      expect(result.outputText, isNotEmpty);
    });

    test('fails when model throws during inference', () async {
      final model = MockAdapter(
        modelId: 'failing-model',
        shouldFail: true,
        failureMessage: 'forced failure',
      );
      final result = await SateAI.healthCheck(model: model);
      expect(result.passed, isFalse);
      expect(result.errorMessage, contains('forced failure'));
    });

    test('returns duration', () async {
      final model = MockAdapter(modelId: 'test');
      final result = await SateAI.healthCheck(model: model);
      expect(result.duration, greaterThan(Duration.zero));
    });

    test('includes confidence when available', () async {
      final model = MockAdapter(modelId: 'test');
      final result = await SateAI.healthCheck(model: model);
      expect(result.confidence, isNotNull);
      expect(result.confidence, greaterThan(0.0));
    });

    test('includes output metadata', () async {
      final model = MockAdapter(modelId: 'test');
      final result = await SateAI.healthCheck(model: model);
      expect(result.metadata, isNotEmpty);
    });

    test('times out for very slow model', () async {
      final model = MockAdapter(
        modelId: 'slow-model',
        inferenceDelay: const Duration(seconds: 5),
      );
      final result = await SateAI.healthCheck(
        model: model,
        timeout: const Duration(milliseconds: 50),
      );
      expect(result.passed, isFalse);
      expect(result.errorMessage, isNotNull);
    });
  });
}
