import 'dart:async';

import '../adapters/model_adapter.dart';
import 'benchmark_report.dart';
import 'event_stream.dart';
import 'fault_injector.dart';
import 'fault_type.dart';
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
    this.retryCount = 1,
    this.flakyThreshold = 0,
    this.benchmark = false,
    this.onEvent,
  }) : _eventController =
            onEvent != null ? null : StreamController<StressEvent>.broadcast();

  /// The model under test.
  final AIModelAdapter model;

  /// Ordered list of fault injectors to execute.
  final List<FaultInjector> injectors;

  /// Maximum time allowed per injector cycle before it is aborted.
  final Duration timeout;

  /// Number of retry attempts per injector cycle.
  final int retryCount;

  /// Number of failures allowed to mark a test as flaky.
  final int flakyThreshold;

  /// Whether to run in performance benchmarking mode without fault injection.
  final bool benchmark;

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
    if (benchmark) {
      return _runBenchmark();
    }
    return _runStressTest();
  }

  Future<StressReport> _runBenchmark() async {
    final startTime = DateTime.now();
    final inferenceTimes = <double>[];
    final memoryUsages = <double>[];
    final results = <FaultResult>[];
    final failures = <Failure>[];

    const numRuns = 10;
    for (var i = 0; i < numRuns; i++) {
      final inferenceStart = DateTime.now();
      final output = await model
          .runInference(AIInput(text: 'benchmark-probe'))
          .timeout(timeout);
      final inferenceTime = DateTime.now().difference(inferenceStart);
      inferenceTimes.add(inferenceTime.inMilliseconds.toDouble());
      memoryUsages.add(model.currentMemoryMB);

      results.add(FaultResult(
        injectorType: FaultType.benchmark,
        passed: true,
        inferenceTime: inferenceTime,
        output: output,
        memoryUsageMB: model.currentMemoryMB,
      ));
    }

    final endTime = DateTime.now();
    final totalDuration = endTime.difference(startTime);

    final benchmarkReport = BenchmarkReport(
      modelId: model.modelId,
      inferenceTimes: inferenceTimes,
      memoryUsages: memoryUsages,
      numRuns: numRuns,
    );

    return StressReport(
      modelId: model.modelId,
      passed: true,
      results: results,
      failures: failures,
      startTime: startTime,
      endTime: endTime,
      totalDuration: totalDuration,
      benchmarkReport: benchmarkReport,
    );
  }

  Future<StressReport> _runStressTest() async {
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

  /// Runs one or more inject → infer → check cycles with retry and flaky detection logic.
  Future<FaultResult> _runCycle(FaultInjector injector) async {
    var attempts = 0;
    var failures = 0;
    FaultResult? lastResult;

    final maxAttempts = retryCount > 0 ? retryCount : 1;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        await injector.inject().timeout(timeout);
      } on TimeoutException {
        failures++;
        lastResult = FaultResult(
          injectorType: injector.type,
          passed: false,
          errorMessage:
              'Timeout after ${timeout.inSeconds}s (attempt $attempts)',
        );
        continue;
      }

      try {
        final inferenceStart = DateTime.now();
        final output = await model
            .runInference(AIInput(text: 'stress-test-probe'))
            .timeout(timeout);
        final inferenceTime = DateTime.now().difference(inferenceStart);

        final degraded = model.isDegraded;
        final memoryMB = model.currentMemoryMB;

        final result = FaultResult(
          injectorType: injector.type,
          passed: !degraded,
          inferenceTime: inferenceTime,
          output: output,
          errorMessage: degraded ? 'Model entered degraded state' : null,
          memoryUsageMB: memoryMB > 0 ? memoryMB : null,
        );

        if (result.passed) {
          lastResult = result;
          break;
        } else {
          failures++;
          lastResult = result;
        }
      } on TimeoutException {
        failures++;
        lastResult = FaultResult(
          injectorType: injector.type,
          passed: false,
          errorMessage:
              'Timeout after ${timeout.inSeconds}s (attempt $attempts)',
        );
      } on AIInferenceError catch (e) {
        failures++;
        lastResult = FaultResult(
          injectorType: injector.type,
          passed: false,
          errorMessage: e.toString(),
        );
      } finally {
        try {
          await injector.reset();
        } catch (_) {}
      }
    }

    if (flakyThreshold > 0 && failures > 0 && failures <= flakyThreshold) {
      return FaultResult(
        injectorType: injector.type,
        passed: true,
        inferenceTime: lastResult?.inferenceTime,
        output: lastResult?.output,
        errorMessage: 'Flaky: failed $failures/$attempts attempts',
        memoryUsageMB: lastResult?.memoryUsageMB,
        flaky: true,
      );
    }

    return lastResult ??
        FaultResult(
          injectorType: injector.type,
          passed: false,
          errorMessage: 'All $maxAttempts attempts failed',
        );
  }
}
