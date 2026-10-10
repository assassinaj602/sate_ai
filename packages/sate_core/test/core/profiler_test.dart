import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('ProfileResult', () {
    ProfileResult sample() => ProfileResult(
          modelId: 'test',
          preProcessingTime: const Duration(milliseconds: 5),
          executionTime: const Duration(milliseconds: 90),
          postProcessingTime: const Duration(milliseconds: 5),
          preProcessingMemoryMB: 10,
          executionMemoryMB: 100,
          postProcessingMemoryMB: 105,
          peakMemoryMB: 105,
        );

    test('totalTime sums all stages', () {
      final p = sample();
      expect(p.totalTime.inMilliseconds, equals(100));
    });

    test('percentages sum to 100', () {
      final p = sample();
      final total =
          p.preProcessingPercent + p.executionPercent + p.postProcessingPercent;
      expect(total, closeTo(100.0, 0.01));
    });

    test('execution percent is dominant', () {
      final p = sample();
      expect(p.executionPercent, greaterThan(80));
    });

    test('toJson serializes all fields', () {
      final json = sample().toJson();
      expect(json['modelId'], equals('test'));
      expect(json['executionMs'], closeTo(90.0, 0.01));
      expect(json['peakMemoryMB'], equals(105));
    });

    test('fromJson round-trips', () {
      final original = sample();
      final restored = ProfileResult.fromJson(original.toJson());
      expect(restored.modelId, equals(original.modelId));
      expect(
        restored.totalTime.inMilliseconds,
        equals(original.totalTime.inMilliseconds),
      );
      expect(restored.peakMemoryMB, equals(original.peakMemoryMB));
    });

    test('toMarkdown contains stage names', () {
      final md = sample().toMarkdown();
      expect(md, contains('Pre-processing'));
      expect(md, contains('Execution'));
      expect(md, contains('Post-processing'));
      expect(md, contains('Peak memory'));
    });
  });

  group('InferenceProfiler', () {
    test('produces a ProfileResult', () async {
      final model = MockAdapter(modelId: 'profiled');
      final profiler = InferenceProfiler(model: model);
      final result = await profiler.profile();
      expect(result.modelId, equals('profiled'));
    });

    test('execution time is non-negative', () async {
      final model = MockAdapter(modelId: 'profiled');
      final profiler = InferenceProfiler(model: model);
      final result = await profiler.profile();
      expect(result.executionTime.inMicroseconds, greaterThanOrEqualTo(0));
    });

    test('total time is positive', () async {
      final model = MockAdapter(modelId: 'profiled');
      final profiler = InferenceProfiler(model: model);
      final result = await profiler.profile();
      expect(result.totalTime.inMicroseconds, greaterThan(0));
    });

    test('profileMany returns requested count', () async {
      final model = MockAdapter(modelId: 'profiled');
      final profiler = InferenceProfiler(model: model);
      final results = await profiler.profileMany(runs: 3);
      expect(results.length, equals(3));
    });

    test('profileMany uses fresh probe per run', () async {
      final model = MockAdapter(modelId: 'profiled');
      final profiler = InferenceProfiler(model: model);
      final results = await profiler.profileMany(runs: 2);
      expect(
        results.first.timestamp.isBefore(
          results.last.timestamp.add(const Duration(seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
