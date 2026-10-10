import '../adapters/model_adapter.dart';
import '../core/fault_injector.dart';
import '../core/fault_type.dart';

/// Simulates memory pressure to test how an AI model behaves near or beyond
/// its available RAM budget.
///
/// The injector delegates memory allocation to the [AIModelAdapter] via
/// [AIModelAdapter.simulateMemoryPressure], allowing adapters that wrap real
/// native models to trigger actual OS-level memory pressure if desired.
///
/// ## Usage
///
/// ```dart
/// final injector = MemoryPressureInjector(
///   model:   myAdapter,
///   limitMb: 150,
/// );
///
/// await injector.inject();   // allocates 150 MB
/// // … run inference …
/// await injector.reset();    // releases memory
/// ```
class MemoryPressureInjector implements FaultInjector {
  /// Creates a [MemoryPressureInjector].
  ///
  /// [limitMb] specifies how many megabytes to allocate during [inject].
  /// Defaults to 100 MB.
  const MemoryPressureInjector({
    required this.model,
    this.limitMb = 100,
  });

  /// The model adapter to stress.
  final AIModelAdapter model;

  /// Amount of memory (in MB) to allocate during [inject].
  final int limitMb;

  @override
  FaultType get type => FaultType.memoryPressure;

  @override
  String get name => 'Memory Pressure Injector';

  @override
  String get description =>
      'Allocates $limitMb MB to simulate memory pressure on the model.';

  @override
  Future<void> inject() => model.simulateMemoryPressure(limitMb);

  @override
  Future<void> reset() => model.reset();
}
