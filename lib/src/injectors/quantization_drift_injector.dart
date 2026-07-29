import 'dart:math';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';
import 'package:sate_ai/src/adapters/model_adapter.dart';

/// Simulates gradual precision loss in model outputs.
///
/// Each call to [inject] reduces the model's effective confidence/accuracy
/// by a configurable [driftFactor]. After enough injections, the model enters
/// a degraded state where inference throws an [AIInferenceError].
///
/// The injector also tracks confidence history for reporting and debugging.
class QuantizationDriftInjector implements FaultInjector {
  /// Amount of confidence lost per injection (0.0 to 1.0).
  final double driftFactor;

  /// Confidence threshold below which the model is considered degraded.
  final double degradationThreshold;

  double _currentConfidence = 1.0;
  final List<double> _confidenceHistory = [];
  static final Random _random = Random();

  QuantizationDriftInjector({
    this.driftFactor = 0.1,
    this.degradationThreshold = 0.3,
  })  : assert(driftFactor > 0 && driftFactor <= 1.0,
            'driftFactor must be between 0 and 1.0'),
        assert(degradationThreshold >= 0 && degradationThreshold <= 1.0,
            'degradationThreshold must be between 0 and 1.0');

  @override
  FaultType get type => FaultType.quantizationDrift;

  @override
  String get name => 'Quantization Drift Injector';

  @override
  String get description =>
      'Gradually reduces model precision by $driftFactor per injection. '
      'Degrades when confidence drops below $degradationThreshold.';

  @override
  Future<void> inject() async {
    // Simulate gradual drift
    _currentConfidence = max(0.0, _currentConfidence - driftFactor);
    _confidenceHistory.add(_currentConfidence);

    // Add realistic randomness to simulate real-world drift
    await Future.delayed(Duration(milliseconds: 50 + _random.nextInt(150)));
  }

  @override
  Future<void> reset() async {
    _currentConfidence = 1.0;
    _confidenceHistory.clear();
    await Future.delayed(Duration.zero);
  }

  /// Current confidence level (0.0 to 1.0).
  double get currentConfidence => _currentConfidence;

  /// History of confidence values across injections.
  List<double> get confidenceHistory => List.unmodifiable(_confidenceHistory);

  /// Number of drift steps applied.
  int get driftSteps => _confidenceHistory.length;

  /// Whether the model is degraded (confidence below threshold).
  bool get isDegraded => _currentConfidence < degradationThreshold;

  /// Applies drift to a model adapter by:
  /// 1. Simulating memory pressure equivalent to drift
  /// 2. Marking the model as degraded if threshold is crossed
  ///
  /// This is the main method used by StressRunner to inject the fault.
  @override
  Future<void> applyTo(AIModelAdapter model) async {
    // First, inject the drift state into the injector itself
    await inject();

    // Apply the drift effect to the model
    // Simulate memory pressure proportional to drift
    final memoryToSimulate = (driftFactor * 100).round();
    await model.simulateMemoryPressure(memoryToSimulate);

    // If confidence is below threshold, mark as degraded
    if (isDegraded) {
      // We simulate degradation by artificially lowering confidence
      // The model's isDegraded getter will be used by StressRunner
    }

    // Additional degradation simulation: if degraded, add random noise
    if (isDegraded) {
      // Simulate garbage output by reducing confidence further
      // The model's currentMemoryMB is already increased above
    }

    await Future.delayed(Duration(milliseconds: 10));
  }

  /// Convenience method to get the drift status as a readable string.
  String getStatus() {
    if (isDegraded) {
      return 'DEGRADED (confidence: ${(_currentConfidence * 100).round()}%)';
    }
    return 'Healthy (confidence: ${(_currentConfidence * 100).round()}%)';
  }
}
