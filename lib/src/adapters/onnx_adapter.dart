import 'dart:typed_data';

import 'package:onnxruntime/onnxruntime.dart';
import 'package:sate_ai/src/adapters/model_adapter.dart';

/// Signature for a factory that produces an [OrtSession] from raw model bytes.
///
/// Providing a custom factory lets tests inject a stub that never touches the
/// ONNX native runtime, so unit tests run without an `.onnx` file or native
/// shared libraries.
///
/// ```dart
/// // In tests:
/// final adapter = OnnxAdapter(
///   modelBytes: Uint8List(0),
///   modelId: 'stub',
///   sessionFactory: (_) => _StubOrtSession(),
/// );
/// ```
typedef OrtSessionFactory = OrtSession Function(Uint8List bytes);

/// Default factory: initialises [OrtEnv] and creates a real [OrtSession].
OrtSession _defaultSessionFactory(Uint8List bytes) {
  OrtEnv.instance.init();
  return OrtSession.fromBuffer(bytes, OrtSessionOptions());
}

/// [AIModelAdapter] implementation backed by the ONNX Runtime.
///
/// ## Basic usage
///
/// ```dart
/// final bytes = await File('model.onnx').readAsBytes();
/// final adapter = OnnxAdapter(modelBytes: bytes, modelId: 'my-model');
///
/// final report = await SateAI.stress(
///   model: adapter,
///   injectors: [MemoryPressureInjector(limitMb: 200)],
/// );
/// adapter.dispose();
/// ```
///
/// The adapter accepts raw model bytes instead of a file path so it works
/// uniformly with Flutter asset bundles, network fetches, and local storage
/// without coupling to a specific I/O API.
class OnnxAdapter implements AIModelAdapter {
  /// Constructs an [OnnxAdapter].
  ///
  /// [modelBytes] is the raw content of a `.onnx` model file.
  /// [modelId] is a stable identifier used in stress reports.
  /// [sessionFactory] is optional; override in unit tests to avoid native FFI.
  OnnxAdapter({
    required Uint8List modelBytes,
    required String modelId,
    OrtSessionFactory? sessionFactory,
  })  : _modelId = modelId,
        _session = (sessionFactory ?? _defaultSessionFactory)(modelBytes);

  final String _modelId;
  final OrtSession _session;

  double _currentMemoryMB = 0;
  bool _isDegraded = false;

  @override
  String get modelId => _modelId;

  @override
  double get currentMemoryMB => _currentMemoryMB;

  @override
  bool get isDegraded => _isDegraded;

  /// Runs a single ONNX inference call.
  ///
  /// Converts [AIInput.text] (or [AIInput.binary]) into a flat float32 tensor
  /// and passes it to the session as the `"input"` named input.
  ///
  /// Throws [AIInferenceError] if the adapter is degraded or the session fails.
  @override
  Future<AIOutput> runInference(AIInput input) async {
    if (_isDegraded) {
      throw AIInferenceError(
        'OnnxAdapter [$_modelId] is degraded. Call reset() before retrying.',
      );
    }

    final stopwatch = Stopwatch()..start();

    try {
      final rawBytes = input.binary ?? (input.text?.codeUnits ?? <int>[]);

      final inputData = Float32List.fromList(
        rawBytes.map((b) => b.toDouble()).toList(),
      );
      final shape = [1, inputData.length];
      final inputTensor =
          OrtValueTensor.createTensorWithDataList(inputData, shape);

      final runOptions = OrtRunOptions();
      final outputs = await _session
          .runAsync(runOptions, {'input': inputTensor})
          .timeout(const Duration(seconds: 3));

      String outputText;
      if (outputs != null && outputs.isNotEmpty) {
        final first = outputs.first?.value;
        if (first is List) {
          outputText = first.map((e) => e.toString()).join(' ');
        } else {
          outputText = first?.toString() ?? '[no output]';
        }
      } else {
        outputText = '[empty output]';
      }

      stopwatch.stop();

      final confidence = (0.95 - (_currentMemoryMB / 1000.0)).clamp(0.0, 1.0);

      return AIOutput(
        text: outputText,
        inferenceTime: stopwatch.elapsed,
        confidence: confidence,
        metadata: {
          'runtime': 'ONNX Runtime',
          'modelId': _modelId,
          'memoryMB': _currentMemoryMB,
        },
      );
    } catch (e, st) {
      stopwatch.stop();
      throw AIInferenceError(
        'OnnxAdapter [$_modelId] inference failed: $e',
        st,
      );
    }
  }

  /// Increases the simulated memory footprint by [mb] megabytes.
  ///
  /// When [currentMemoryMB] exceeds 150 MB the adapter is marked [isDegraded]
  /// and will reject further inference calls until [reset] is called.
  @override
  Future<void> simulateMemoryPressure(int mb) async {
    _currentMemoryMB += mb.toDouble();
    if (_currentMemoryMB > 150) {
      _isDegraded = true;
    }
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Resets the adapter to a healthy, non-degraded state.
  @override
  Future<void> reset() async {
    _currentMemoryMB = 0;
    _isDegraded = false;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Returns `true` when the adapter can safely accept inference calls.
  @override
  Future<bool> isHealthy() async {
    return !_isDegraded && _currentMemoryMB < 150;
  }

  /// Releases all ONNX Runtime resources held by this adapter.
  ///
  /// Call this when the adapter is no longer needed to avoid native memory
  /// leaks. The adapter must not be used after [dispose] is called.
  void dispose() {
    _session.release();
  }
}
