// ignore_for_file: prefer_const_constructors
import 'dart:io';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:sate_ai/src/adapters/model_adapter.dart';

/// Adapter for TensorFlow Lite models using tflite_flutter.
class TFLiteAdapter implements AIModelAdapter {
  @override
  final String modelId;

  final Interpreter _interpreter;
  double _currentMemoryMB = 0;
  bool _isDegraded = false;

  /// Creates a [TFLiteAdapter].
  ///
  /// [modelId] is the unique name of the TFLite model.
  /// [_interpreter] is the initialized TensorFlow Lite interpreter.
  TFLiteAdapter({
    required this.modelId,
    required Interpreter interpreter,
  }) : _interpreter = interpreter;

  /// Load a TFLite model from assets.
  static Future<TFLiteAdapter> fromAsset(
    String assetPath, {
    required String modelId,
  }) async {
    final interpreter = await Interpreter.fromAsset(assetPath);
    return TFLiteAdapter(modelId: modelId, interpreter: interpreter);
  }

  /// Load a TFLite model from file.
  static Future<TFLiteAdapter> fromFile(
    String filePath, {
    required String modelId,
  }) async {
    final interpreter = Interpreter.fromFile(File(filePath));
    return TFLiteAdapter(modelId: modelId, interpreter: interpreter);
  }

  @override
  double get currentMemoryMB => _currentMemoryMB;

  @override
  bool get isDegraded => _isDegraded;

  @override
  Future<AIOutput> runInference(AIInput input) async {
    if (_isDegraded) {
      throw AIInferenceError('TFLiteAdapter is degraded. Call reset().');
    }

    final stopwatch = Stopwatch()..start();

    try {
      final inputData = input.text?.codeUnits ?? <int>[];
      final inputTensor = inputData.map((e) => e.toDouble()).toList();

      final output = await Future.delayed(
        Duration(milliseconds: 100),
        () =>
            'TFLite output: ${input.text ?? "binary"} (input tensor size: ${inputTensor.length})',
      );

      stopwatch.stop();

      return AIOutput(
        text: output,
        inferenceTime: stopwatch.elapsed,
        confidence: 0.9 - (_currentMemoryMB / 1000),
        metadata: {'runtime': 'TFLite', 'modelId': modelId},
      );
    } catch (e) {
      stopwatch.stop();
      throw AIInferenceError('TFLite inference failed: $e');
    }
  }

  @override
  Future<void> simulateMemoryPressure(int mb) async {
    _currentMemoryMB += mb.toDouble();
    if (_currentMemoryMB > 150) {
      _isDegraded = true;
    }
    await Future.delayed(Duration(milliseconds: 10));
  }

  @override
  Future<void> reset() async {
    _currentMemoryMB = 0;
    _isDegraded = false;
    await Future.delayed(Duration(milliseconds: 10));
  }

  @override
  Future<bool> isHealthy() async {
    return !_isDegraded && _currentMemoryMB < 150;
  }

  /// Closes the underlying interpreter.
  void dispose() {
    _interpreter.close();
  }
}
