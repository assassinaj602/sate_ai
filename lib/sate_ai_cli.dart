/// CLI-safe library for SATE AI — no Flutter SDK dependency.
///
/// Use this import in Dart CLI executables (`bin/`) or pure-Dart tools
/// that must run with `dart run` (i.e., without the Flutter toolchain).
///
/// Flutter-specific adapters (`TFLiteAdapter`) are intentionally excluded
/// from this library. Import `package:sate_ai/sate_ai.dart` in your Flutter
/// app code to access the full API including TFLite support.
library sate_ai_cli;

export 'src/core/fault_type.dart';
export 'src/core/fault_injector.dart';
export 'src/core/stress_runner.dart';
export 'src/core/stress_scheduler.dart';
export 'src/core/batch_runner.dart';
export 'src/core/baseline_manager.dart';
export 'src/core/metric_deviation.dart';
export 'src/core/report_comparator.dart';
export 'src/core/benchmark_report.dart';
export 'src/core/event_stream.dart';
export 'src/core/report.dart';
export 'src/core/template_engine.dart';
export 'src/core/template_loader.dart';
export 'src/core/health_check_result.dart';
export 'src/core/model_type_detector.dart';
export 'src/core/model_factory.dart';
export 'src/adapters/model_adapter.dart';
export 'src/adapters/mock_adapter.dart';
// NOTE: OnnxAdapter and TFLiteAdapter are intentionally excluded — both
// transitively import Flutter (dart:ui) and cannot be used in dart run CLIs.
// Use `package:sate_ai/sate_ai.dart` in Flutter apps to access those adapters.
export 'src/injectors/memory_pressure_injector.dart';
export 'src/injectors/malformed_input_injector.dart';
export 'src/injectors/quantization_drift_injector.dart';
export 'src/injectors/thermal_throttle_injector.dart';
export 'src/injectors/latency_injector.dart';
export 'src/injectors/model_swap_injector.dart';
export 'src/injectors/confidence_threshold_injector.dart';

import 'src/adapters/model_adapter.dart';
import 'src/core/fault_injector.dart';
import 'src/core/health_check_result.dart';
import 'src/core/report.dart';
import 'src/core/stress_runner.dart';

/// Top-level convenience API for running SATE AI stress tests (CLI edition).
///
/// Identical to [SateAI] in the main library but importable without the
/// Flutter SDK, making it suitable for `dart run` CLI tools and CI scripts.
class SateAI {
  SateAI._();

  /// Runs a stress test against [model] using each of the [injectors].
  static Future<StressReport> stress({
    required AIModelAdapter model,
    required List<FaultInjector> injectors,
    Duration timeout = const Duration(seconds: 30),
    int retryCount = 1,
    int flakyThreshold = 0,
    bool benchmark = false,
  }) {
    return StressRunner(
      model: model,
      injectors: injectors,
      timeout: timeout,
      retryCount: retryCount,
      flakyThreshold: flakyThreshold,
      benchmark: benchmark,
    ).run();
  }

  /// Runs a quick health check on the given model adapter.
  ///
  /// Performs a single sanity inference to verify that the model is
  /// loaded correctly and can produce valid output. This is much faster
  /// than running a full stress test.
  ///
  /// Example:
  /// ```dart
  /// final result = await SateAI.healthCheck(model: myModel);
  /// if (result.passed) {
  ///   print('Model is healthy');
  /// }
  /// ```
  static Future<HealthCheckResult> healthCheck({
    required AIModelAdapter model,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final output = await model
          .runInference(AIInput(text: 'health-check-probe'))
          .timeout(timeout);

      stopwatch.stop();

      // Verify output is not empty
      if (output.text.isEmpty) {
        return HealthCheckResult.failed(
          modelId: model.modelId,
          duration: stopwatch.elapsed,
          errorMessage: 'Model returned empty output',
        );
      }

      return HealthCheckResult.passed(
        modelId: model.modelId,
        duration: stopwatch.elapsed,
        outputText: output.text,
        confidence: output.confidence,
        metadata: output.metadata ?? {},
      );
    } catch (e, st) {
      stopwatch.stop();
      return HealthCheckResult.failed(
        modelId: model.modelId,
        duration: stopwatch.elapsed,
        errorMessage: e.toString(),
        stackTrace: st,
      );
    }
  }
}
