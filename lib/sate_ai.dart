/// SATE AI — Fault Injection Framework for On-Device AI.
///
/// Import this library to access all public APIs:
///
/// ```dart
/// import 'package:sate_ai/sate_ai.dart';
///
/// final report = await SateAI.stress(
///   model: MockAdapter(),
///   injectors: [
///     MemoryPressureInjector(model: MockAdapter(), limitMb: 100),
///     MalformedInputInjector(),
///   ],
/// );
/// print(report.toMarkdown());
/// ```
library sate_ai;

// Explicit imports so the SateAI class body can reference these types.
// (Exports alone are not visible to the file's own code in Dart.)
import 'src/adapters/model_adapter.dart';
import 'src/core/fault_injector.dart';
import 'src/core/report.dart';
import 'src/core/stress_runner.dart';

export 'src/core/fault_type.dart';
export 'src/core/fault_injector.dart';
export 'src/core/stress_runner.dart';
export 'src/core/report.dart';
export 'src/adapters/model_adapter.dart';
export 'src/adapters/mock_adapter.dart';
export 'src/injectors/memory_pressure_injector.dart';
export 'src/injectors/malformed_input_injector.dart';

/// Top-level convenience API for running SATE AI stress tests.
///
/// This is a thin wrapper around [StressRunner] and is the recommended
/// entry point for most users.
class SateAI {
  SateAI._(); // prevent instantiation

  /// Runs a stress test against [model] using each of the [injectors].
  ///
  /// Returns a [StressReport] with per-injector results, timing data,
  /// and Markdown/JSON serialisation helpers.
  ///
  /// ```dart
  /// final report = await SateAI.stress(
  ///   model: MockAdapter(),
  ///   injectors: [
  ///     MemoryPressureInjector(model: MockAdapter(), limitMb: 100),
  ///   ],
  /// );
  /// assert(report.passed);
  /// ```
  static Future<StressReport> stress({
    required AIModelAdapter model,
    required List<FaultInjector> injectors,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return StressRunner(
      model: model,
      injectors: injectors,
      timeout: timeout,
    ).run();
  }
}
