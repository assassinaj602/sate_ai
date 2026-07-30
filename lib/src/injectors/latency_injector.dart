import 'dart:async';
import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Simulates increasing inference latency over repeated calls.
///
/// Each call to [inject] increases the cumulative latency by [incrementMs].
/// Once the total latency exceeds [maxLatencyMs], the model is marked as degraded.
/// The [baseDelayMs] is the minimum delay applied on each injection.
class LatencyInjector implements FaultInjector {
  /// Base delay added on each injection (milliseconds).
  final int baseDelayMs;

  /// Additional delay added per injection (milliseconds).
  final int incrementMs;

  /// Maximum total latency before degradation (milliseconds).
  final int maxLatencyMs;

  /// The model adapter to stress.
  final AIModelAdapter model;

  int _totalLatencyMs = 0;
  bool _isDegraded = false;
  final List<int> _latencyHistory = [];

  /// Creates a [LatencyInjector].
  ///
  /// [model] is the model adapter instance to apply the latency delay to.
  /// [baseDelayMs] is the baseline delay (in milliseconds) added on each injection.
  /// [incrementMs] is the additional delay added per injection step.
  /// [maxLatencyMs] is the threshold above which the system degrades.
  LatencyInjector({
    required this.model,
    this.baseDelayMs = 100,
    this.incrementMs = 50,
    this.maxLatencyMs = 1000,
  })  : assert(baseDelayMs >= 0, 'baseDelayMs must be >= 0'),
        assert(incrementMs >= 0, 'incrementMs must be >= 0'),
        assert(maxLatencyMs > 0, 'maxLatencyMs must be > 0');

  @override
  FaultType get type => FaultType.latency;

  @override
  String get name => 'Latency Injector';

  @override
  String get description =>
      'Simulates increasing inference latency by $incrementMs ms per injection. '
      'Degrades when total latency exceeds ${maxLatencyMs}ms.';

  @override
  Future<void> inject() async {
    // Calculate current delay
    final delay = baseDelayMs + (_latencyHistory.length * incrementMs);
    _totalLatencyMs += delay;
    _latencyHistory.add(_totalLatencyMs);

    // Apply the delay
    await Future.delayed(Duration(milliseconds: delay));

    // Simulate memory pressure proportional to latency (roughly)
    final memoryToSimulate = (_totalLatencyMs / 20).round();
    await model.simulateMemoryPressure(memoryToSimulate);

    // Check degradation
    if (_totalLatencyMs >= maxLatencyMs) {
      _isDegraded = true;
      // Additional memory pressure when degraded
      await model.simulateMemoryPressure(30);
    }
  }

  @override
  Future<void> reset() async {
    _totalLatencyMs = 0;
    _isDegraded = false;
    _latencyHistory.clear();
    await model.reset();
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Total accumulated latency in milliseconds.
  int get totalLatencyMs => _totalLatencyMs;

  /// Whether the model is degraded (latency exceeds max).
  bool get isDegraded => _isDegraded;

  /// History of accumulated latency after each injection.
  List<int> get latencyHistory => List.unmodifiable(_latencyHistory);

  /// Number of injections applied.
  int get injectionCount => _latencyHistory.length;

  /// Convenience method to get the status as a readable string.
  String getStatus() {
    if (_isDegraded) {
      return 'DEGRADED (total latency: ${_totalLatencyMs}ms)';
    }
    return 'Normal (total latency: ${_totalLatencyMs}ms)';
  }
}
