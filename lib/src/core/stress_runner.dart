import 'dart:async';

import '../adapters/model_adapter.dart';
import 'event_stream.dart';
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
  StressRunner({
    required this.model,
    required this.injectors,
    this.timeout = const Duration(seconds: 30),
    this.onEvent,
  }) : _eventController =
            onEvent != null ? null : StreamController<StressEvent>.broadcast();

  /// The model under test.
  final AIModelAdapter model;

  /// Ordered list of fault injectors to execute.
  final List<FaultInjector> injectors;

  /// Maximum time allowed per injector cycle before it is aborted.
  final Duration timeout;

  /// Optional event callback.
  final EventCallback? onEvent;

  /// Stream controller for events.
  final StreamController<StressEvent>? _eventController;

  /// Stream of events emitted during the stress test.
  Stream<StressEvent> get events => _eventController!.stream;

  /// Executes every injector and returns the aggregated [StressReport].
  ///
  /// Injectors run sequentially. Each injector's [FaultInjector.reset] is
  /// always called in a `finally` block so subsequent injectors start clean.
  Future<StressReport> run() async {
    final startTime = DateTime.now();
    final results = <FaultResult>[];
    final failures = <Failure>[];
    var allPassed = true;

    // Emit started event
    final startedEvent = StartedEvent(
      modelId: model.modelId,
      injectorNames: injectors.map((i) => i.name).toList(),
      totalInjectors: injectors.length,
    );
    _emitEvent(startedEvent);

    for (var i = 0; i < injectors.length; i++) {
      final injector = injectors[i];

      // Emit injector starting event
      final startingEvent = InjectorStartingEvent(
        injectorName: injector.name,
        index: i,
        total: injectors.length,
      );
      _emitEvent(startingEvent);

      try {
        final result = await _runCycle(injector);
        results.add(result);
        if (!result.passed) allPassed = false;

        // Emit injector complete event
        final completeEvent = InjectorCompleteEvent(
          injectorName: injector.name,
          passed: result.passed,
          inferenceTimeMs: result.inferenceTime?.inMilliseconds,
          memoryUsageMB: result.memoryUsageMB,
          errorMessage: result.errorMessage,
        );
        _emitEvent(completeEvent);
      } catch (e, st) {
        allPassed = false;
        failures.add(
          Failure(
            injectorType: injector.type,
            message: e.toString(),
            stackTrace: st,
          ),
        );

        // Emit error event
        final errorEvent = InjectorErrorEvent(
          injectorName: injector.name,
          error: e.toString(),
        );
        _emitEvent(errorEvent);
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
    final totalDuration = endTime.difference(startTime);

    final report = StressReport(
      modelId: model.modelId,
      passed: allPassed,
      results: results,
      failures: failures,
      startTime: startTime,
      endTime: endTime,
      totalDuration: totalDuration,
    );

    // Emit finished event
    final finishedEvent = FinishedEvent(
      passed: report.passed,
      totalTests: results.length,
      passedCount: results.where((r) => r.passed).length,
      failedCount: results.where((r) => !r.passed).length,
      durationMs: totalDuration.inMilliseconds,
    );
    _emitEvent(finishedEvent);

    await _eventController?.close();
    return report;
  }

  /// Emits an event to the callback and/or stream controller.
  void _emitEvent(StressEvent event) {
    onEvent?.call(event);
    _eventController?.add(event);
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
      final memoryMB = model.currentMemoryMB;

      return FaultResult(
        injectorType: injector.type,
        passed: !degraded,
        inferenceTime: inferenceTime,
        output: output,
        errorMessage: degraded ? 'Model entered degraded state' : null,
        memoryUsageMB: memoryMB > 0 ? memoryMB : null,
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
