import '../adapters/model_adapter.dart';

/// A fully-in-process mock implementation of [AIModelAdapter] for testing.
///
/// [MockAdapter] simulates inference with a configurable delay and can be
/// programmatically pushed into a degraded or failing state, making it ideal
/// for unit-testing injectors without a real model present.
///
/// ```dart
/// final adapter = MockAdapter();
/// final output  = await adapter.runInference(AIInput(text: 'hello'));
/// print(output.text); // "Hello from MockAdapter! Input: hello"
///
/// // Simulate a model that fails immediately
/// final broken = MockAdapter(forceFailure: true);
/// ```
class MockAdapter implements AIModelAdapter {
  /// Creates a [MockAdapter].
  MockAdapter({
    String modelId = 'mock-model-v1',
    Duration inferenceDelay = const Duration(milliseconds: 500),
    bool forceFailure = false,
    String? forceFailureMessage,
  })  : _modelId = modelId,
        _inferenceDelay = inferenceDelay,
        _forceFailure = forceFailure,
        _forceFailureMessage = forceFailureMessage;

  final String _modelId;
  final Duration _inferenceDelay;
  final bool _forceFailure;
  final String? _forceFailureMessage;

  double _currentMemoryMB = 0;
  double _currentGPUMemoryMB = 0;
  bool _isDegraded = false;
  bool _isHealthy = true;

  // Allocated list simulates memory consumption; GC'd on reset.
  List<int>? _allocatedMemory;

  /// Returns the simulated raw bytes allocated under memory pressure.
  List<int>? get allocatedMemory => _allocatedMemory;

  // ---------------------------------------------------------------------------
  // AIModelAdapter interface
  // ---------------------------------------------------------------------------

  @override
  String get modelId => _modelId;

  @override
  double get currentMemoryMB => _currentMemoryMB;

  @override
  double get currentGPUMemoryMB => _currentGPUMemoryMB;

  @override
  bool get isDegraded => _isDegraded;

  @override
  Future<AIOutput> runInference(AIInput input) async {
    await Future<void>.delayed(_inferenceDelay);

    if (_forceFailure) {
      throw AIInferenceError(
        _forceFailureMessage ?? 'MockAdapter: forced inference failure',
      );
    }

    if (_isDegraded) {
      // Return a low-confidence, slow response when degraded.
      return AIOutput(
        text: '[DEGRADED] ${input.text ?? "binary payload"}',
        inferenceTime: _inferenceDelay * 3,
        confidence: 0.2,
        metadata: const {'degraded': true},
      );
    }

    return AIOutput(
      text: 'Hello from MockAdapter! Input: ${input.text ?? "binary payload"}',
      inferenceTime: _inferenceDelay,
      confidence: 0.97,
      metadata: const {'mock': true},
    );
  }

  @override
  Future<void> simulateMemoryPressure(int mb) async {
    _currentMemoryMB += mb;
    // Allocate a list of bytes to represent memory consumption.
    // This is intentionally simplistic; real pressure would use
    // platform channels or native code.
    _allocatedMemory = List<int>.filled(mb * 256, 0); // ~256 bytes per "MB"
    if (_currentMemoryMB > 150) {
      _isDegraded = true;
    }
  }

  @override
  Future<void> simulateGPUMemoryPressure(int mb) async {
    _currentGPUMemoryMB += mb.toDouble();
    if (_currentGPUMemoryMB > 150) {
      _isDegraded = true;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> reset() async {
    _allocatedMemory = null;
    _currentMemoryMB = 0;
    _currentGPUMemoryMB = 0;
    _isDegraded = false;
    _isHealthy = true;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  @override
  Future<bool> isHealthy() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return _isHealthy && !_isDegraded;
  }

  // ---------------------------------------------------------------------------
  // Test helpers (not part of AIModelAdapter)
  // ---------------------------------------------------------------------------

  /// Force-set the degraded flag without going through memory pressure.
  ///
  /// Useful for directly testing [MockAdapter] behaviour when a model
  /// reports degradation.
  // ignore: avoid_setters_without_getters
  set degraded(bool value) => _isDegraded = value;

  /// Force-set the healthy flag.
  // ignore: avoid_setters_without_getters
  set healthy(bool value) => _isHealthy = value;
}
