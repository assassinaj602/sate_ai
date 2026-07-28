import 'dart:async';

import '../adapters/model_adapter.dart';
import 'fault_injector.dart';
import 'report.dart';

/// Orchestrates a sequence of [FaultInjector] runs against an [AIModelAdapter].
///
/// For each injector the runner:
/// 1. Calls [FaultInjector.inject] to activate the fault.
/// 2. Calls [AIModelAdapter.runInference] to measure impact.
/// 3. Calls [FaultInjector.reset] (always, even on error) to restore state.
/// 4. Records the result in a [StressReport].
///
/// ## Usage
///
/// ```dart
/// final runner = StressRunner(
///   model: MockAdapter(),
///   injectors: [
///     MemoryPressureInjector(model: myModel, limitMb: 100),
///     MalformedInputInjector(),
///   ],
/// );
/// final report = await runner.run();
/// ```
class StressRunner {
  /// Creates a [StressRunner].
  const StressRunner({
    required this.model,
    required this.injectors,
    this.timeout = const Duration(seconds: 30),
  });

  /// The model under test.
  final AIModelAdapter model;

  /// Ordered list of fault injectors to execute.
  final List<FaultInjector> injectors;

  /// Maximum time allowed per injector cycle before it is aborted.
  final Duration timeout;

  /// Executes every injector and returns the aggregated [StressReport].
  ///
  /// Injectors run sequentially. Each injector's [FaultInjector.reset] is
  /// always called in a `finally` block so subsequent injectors start clean.
  Future<StressReport> run() async {
    final startTime = DateTime.now();
    final results = <FaultResult>[];
    final failures = <Failure>[];
    var allPassed = true;

    for (final injector in injectors) {
      try {
        final result = await _runCycle(injector);
        results.add(result);
        if (!result.passed) allPassed = false;
      } catch (e, st) {
        allPassed = false;
        failures.add(
          Failure(
            injectorType: injector.type,
            message: e.toString(),
            stackTrace: st,
          ),
        );
      } finally {
        // Always reset so state doesn't bleed into the next injector.
        try {
          await injector.reset();
        } catch (_) {
          // Ignore reset errors to keep the run going.
        }
      }
    }

    final endTime = DateTime.now();

    return StressReport(
      modelId: model.modelId,
      passed: allPassed,
      results: results,
      failures: failures,
      startTime: startTime,
      endTime: endTime,
      totalDuration: endTime.difference(startTime),
    );
  }

  /// Runs one inject → infer → check cycle with a timeout guard.
  Future<FaultResult> _runCycle(FaultInjector injector) async {
    try {
      // Activate fault
      await injector.inject().timeout(timeout);

      // Measure inference under fault conditions
      final inferenceStart = DateTime.now();
      final output = await model
          .runInference(AIInput(text: 'stress-test-probe'))
          .timeout(timeout);
      final inferenceTime = DateTime.now().difference(inferenceStart);

      final degraded = model.isDegraded;

      return FaultResult(
        injectorType: injector.type,
        passed: !degraded,
        inferenceTime: inferenceTime,
        output: output,
        errorMessage: degraded ? 'Model entered degraded state' : null,
      );
    } on TimeoutException {
      return FaultResult(
        injectorType: injector.type,
        passed: false,
        errorMessage: 'Timed out after ${timeout.inSeconds}s',
      );
    } on AIInferenceError catch (e) {
      return FaultResult(
        injectorType: injector.type,
        passed: false,
        errorMessage: e.toString(),
      );
    }
  }
}
