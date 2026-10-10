import 'package:sate_core/src/adapters/model_adapter.dart';
import 'package:sate_core/src/core/profile_result.dart';

/// Profiles a single inference call on an [AIModelAdapter].
///
/// Breaks the total call into three logical stages even though the adapter
/// interface does not expose them separately. The profiler measures:
/// - Pre-processing: time to build the input object
/// - Execution: time inside [AIModelAdapter.runInference]
/// - Post-processing: time to inspect the returned output
///
/// Memory is sampled before and after each stage via [AIModelAdapter.currentMemoryMB].
class InferenceProfiler {
  /// The target model adapter.
  final AIModelAdapter model;

  /// Creates a new [InferenceProfiler] for the target [model].
  InferenceProfiler({required this.model});

  /// Runs one inference with stage-level profiling.
  Future<ProfileResult> profile({String probe = 'profile-probe'}) async {
    // Pre-processing
    final preStart = DateTime.now();
    final input = AIInput(text: probe);
    final preEnd = DateTime.now();
    final preMem = model.currentMemoryMB;

    // Execution
    final execStart = DateTime.now();
    final output = await model.runInference(input);
    final execEnd = DateTime.now();
    final execMem = model.currentMemoryMB;

    // Post-processing
    final postStart = DateTime.now();
    if (output.text.isEmpty || (output.confidence ?? 0.0) < 0) {
      // touch properties to force evaluation
    }
    final postEnd = DateTime.now();
    final postMem = model.currentMemoryMB;

    final peak = [
      preMem,
      execMem,
      postMem,
    ].reduce((a, b) => a > b ? a : b);

    return ProfileResult(
      modelId: model.modelId,
      preProcessingTime: preEnd.difference(preStart),
      executionTime: execEnd.difference(execStart),
      postProcessingTime: postEnd.difference(postStart),
      preProcessingMemoryMB: preMem,
      executionMemoryMB: execMem,
      postProcessingMemoryMB: postMem,
      peakMemoryMB: peak,
    );
  }

  /// Runs multiple profiled inferences and returns the list.
  Future<List<ProfileResult>> profileMany({int runs = 5}) async {
    final results = <ProfileResult>[];
    for (var i = 0; i < runs; i++) {
      results.add(await profile(probe: 'profile-probe-$i'));
    }
    return results;
  }
}
