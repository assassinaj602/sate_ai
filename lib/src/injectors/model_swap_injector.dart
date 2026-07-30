import 'dart:async';
import 'dart:math';
import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Simulates model corruption or swapping to a degraded model version.
///
/// Each call to [inject] reduces the model quality by [qualityDegradation].
/// Once quality drops below [qualityThreshold], the model is marked as degraded.
/// The injector also applies random noise to outputs to simulate corruption.
class ModelSwapInjector implements FaultInjector {
  /// Initial quality (0.0 to 1.0).
  final double initialQuality;

  /// Quality degradation per injection (0.0 to 1.0).
  final double qualityDegradation;

  /// Quality threshold below which the model is degraded (0.0 to 1.0).
  final double qualityThreshold;

  /// The model adapter to stress.
  final AIModelAdapter model;

  double _currentQuality;
  bool _isDegraded = false;
  final List<double> _qualityHistory = [];
  static final Random _random = Random();

  /// Creates a [ModelSwapInjector].
  ///
  /// [model] is the model adapter instance to swap or corrupt quality on.
  /// [initialQuality] is the starting quality baseline (0.0 to 1.0).
  /// [qualityDegradation] is the quality drop per injection step.
  /// [qualityThreshold] is the limit below which the model degrades.
  ModelSwapInjector({
    required this.model,
    this.initialQuality = 1.0,
    this.qualityDegradation = 0.1,
    this.qualityThreshold = 0.3,
  })  : assert(initialQuality >= 0 && initialQuality <= 1.0,
            'initialQuality must be between 0 and 1.0'),
        assert(qualityDegradation > 0 && qualityDegradation <= 1.0,
            'qualityDegradation must be between 0 and 1.0'),
        assert(qualityThreshold >= 0 && qualityThreshold <= 1.0,
            'qualityThreshold must be between 0 and 1.0'),
        _currentQuality = initialQuality;

  @override
  FaultType get type => FaultType.modelSwap;

  @override
  String get name => 'Model Swap Injector';

  @override
  String get description =>
      'Simulates model corruption by degrading quality by $qualityDegradation '
      'per injection. Degrades when quality drops below $qualityThreshold.';

  @override
  Future<void> inject() async {
    // Reduce quality
    _currentQuality = max(0.0, _currentQuality - qualityDegradation);
    _qualityHistory.add(_currentQuality);

    // Simulate memory pressure based on quality loss
    final memoryToSimulate = ((1.0 - _currentQuality) * 100).round();
    await model.simulateMemoryPressure(memoryToSimulate);

    // Add some randomness to simulate realistic corruption
    await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(100)));

    // Check degradation
    if (_currentQuality < qualityThreshold - 1e-9) {
      _isDegraded = true;
      await model.simulateMemoryPressure(20);
    }
  }

  @override
  Future<void> reset() async {
    _currentQuality = initialQuality;
    _isDegraded = false;
    _qualityHistory.clear();
    await model.reset();
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Current quality level (0.0 to 1.0).
  double get currentQuality => _currentQuality;

  /// Whether the model is degraded.
  bool get isDegraded => _isDegraded;

  /// History of quality values.
  List<double> get qualityHistory => List.unmodifiable(_qualityHistory);

  /// Number of injections applied.
  int get injectionCount => _qualityHistory.length;

  /// Convenience method to get the status as a readable string.
  String getStatus() {
    if (_isDegraded) {
      return 'DEGRADED (quality: ${(_currentQuality * 100).round()}%)';
    }
    return 'Healthy (quality: ${(_currentQuality * 100).round()}%)';
  }
}
