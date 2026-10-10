import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Simulates GPU memory pressure by allocating GPU memory (or simulated).
///
/// This injector increases the simulated GPU memory usage by [limitMb].
/// When [AIModelAdapter.currentGPUMemoryMB] exceeds the threshold (150 MB), the model
/// is marked as degraded and the injector will fail the test.
class GpuMemoryPressureInjector implements FaultInjector {
  /// The amount of simulated GPU memory pressure to apply in megabytes.
  final int limitMb;

  /// Creates a [GpuMemoryPressureInjector].
  GpuMemoryPressureInjector({this.limitMb = 150});

  @override
  FaultType get type => FaultType.gpuMemoryPressure;

  @override
  String get name => 'GPU Memory Pressure Injector';

  @override
  String get description =>
      'Simulates GPU memory pressure up to $limitMb MB. Degrades when GPU memory exceeds 150 MB.';

  @override
  Future<void> inject() async {
    // No state change; actual injection happens in applyTo
  }

  @override
  Future<void> reset() async {
    // Nothing to reset; model reset is called separately
  }

  /// Applies the injector to a model adapter.
  ///
  /// Simulates GPU memory pressure and marks the model as degraded if the
  /// GPU memory exceeds 150 MB.
  Future<void> applyTo(AIModelAdapter model) async {
    await model.simulateGPUMemoryPressure(limitMb);
  }
}
