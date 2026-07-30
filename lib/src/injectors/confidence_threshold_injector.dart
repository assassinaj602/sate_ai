import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Validates that the model's output confidence stays above a threshold.
///
/// This injector runs inference on [model] during [inject] and checks
/// the `confidence` field in the resulting [AIOutput].
/// If confidence is below [threshold], it throws an [AIInferenceError].
class ConfidenceThresholdInjector implements FaultInjector {
  /// The minimum acceptable confidence score (between 0.0 and 1.0).
  final double threshold;

  /// The model adapter to stress.
  final AIModelAdapter model;

  bool _failed = false;
  double _lastConfidence = 1.0;

  /// Creates a [ConfidenceThresholdInjector].
  ConfidenceThresholdInjector({
    required this.model,
    this.threshold = 0.5,
  }) : assert(threshold >= 0 && threshold <= 1.0,
            'threshold must be between 0 and 1.0');

  @override
  FaultType get type => FaultType.confidenceValidation;

  @override
  String get name => 'Confidence Threshold Validator';

  @override
  String get description => 'Fails if model confidence drops below $threshold';

  /// Runs probe inference, checks confidence, and throws if below threshold.
  @override
  Future<void> inject() async {
    final input = AIInput(text: 'confidence-validation-probe');
    final output = await model.runInference(input);
    _lastConfidence = output.confidence ?? 1.0;

    if (_lastConfidence < threshold) {
      _failed = true;
      throw AIInferenceError(
          'Confidence threshold breached: $_lastConfidence < $threshold');
    }
  }

  /// Resets the validator and model state.
  @override
  Future<void> reset() async {
    _failed = false;
    _lastConfidence = 1.0;
    await model.reset();
    await Future.delayed(Duration.zero);
  }

  /// Returns true if validation failed during [inject].
  bool get failed => _failed;

  /// The confidence score of the last run inference.
  double get lastConfidence => _lastConfidence;
}
