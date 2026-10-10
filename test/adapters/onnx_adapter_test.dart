import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:sate_ai/sate_ai.dart';

// ---------------------------------------------------------------------------
// Stub OrtSession — returns pure Dart, never touches FFI / native DLL.
// ---------------------------------------------------------------------------

class _StubOrtSession implements OrtSession {
  /// Absorb every method call without crashing.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Session factory that bypasses all native FFI calls.
///
/// The factory signature is [OrtSessionFactory] = OrtSession Function(Uint8List).
/// By returning [_StubOrtSession] here, the [OnnxAdapter] constructor never
/// touches [OrtEnv], [OrtSessionOptions], or any native symbol.
OrtSession _stubFactory(Uint8List bytes) => _StubOrtSession();

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------
OnnxAdapter _makeAdapter({String modelId = 'stub-model'}) {
  return OnnxAdapter(
    modelBytes: Uint8List(0),
    modelId: modelId,
    sessionFactory: _stubFactory,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------
void main() {
  group('OnnxAdapter', () {
    late OnnxAdapter adapter;

    setUp(() {
      adapter = _makeAdapter();
    });

    // --- interface compliance ------------------------------------------------

    test('implements AIModelAdapter', () {
      expect(adapter, isA<AIModelAdapter>());
    });

    test('modelId matches the value passed at construction', () {
      final a = _makeAdapter(modelId: 'my-onnx-model');
      expect(a.modelId, equals('my-onnx-model'));
    });

    test('modelId is non-empty', () {
      expect(adapter.modelId, isNotEmpty);
    });

    // --- initial state -------------------------------------------------------

    test('currentMemoryMB starts at 0', () {
      expect(adapter.currentMemoryMB, equals(0.0));
    });

    test('isDegraded starts as false', () {
      expect(adapter.isDegraded, isFalse);
    });

    test('isHealthy() returns true for a fresh adapter', () async {
      expect(await adapter.isHealthy(), isTrue);
    });

    // --- memory pressure simulation -----------------------------------------

    test('simulateMemoryPressure increases currentMemoryMB', () async {
      await adapter.simulateMemoryPressure(50);
      expect(adapter.currentMemoryMB, equals(50.0));
    });

    test('simulateMemoryPressure is additive across multiple calls', () async {
      await adapter.simulateMemoryPressure(80);
      await adapter.simulateMemoryPressure(40);
      expect(adapter.currentMemoryMB, equals(120.0));
    });

    test('simulateMemoryPressure over 150 MB marks adapter as degraded',
        () async {
      await adapter.simulateMemoryPressure(160);
      expect(adapter.isDegraded, isTrue);
    });

    test('isHealthy() returns false when degraded', () async {
      await adapter.simulateMemoryPressure(160);
      expect(await adapter.isHealthy(), isFalse);
    });

    // --- reset ---------------------------------------------------------------

    test('reset() clears memory and degradation', () async {
      await adapter.simulateMemoryPressure(160);
      expect(adapter.isDegraded, isTrue);

      await adapter.reset();

      expect(adapter.currentMemoryMB, equals(0.0));
      expect(adapter.isDegraded, isFalse);
    });

    test('reset() is idempotent when called twice', () async {
      await adapter.reset();
      await adapter.reset();
      expect(adapter.currentMemoryMB, equals(0.0));
      expect(adapter.isDegraded, isFalse);
    });

    test('inject then reset leaves adapter healthy', () async {
      await adapter.simulateMemoryPressure(160);
      await adapter.reset();
      expect(await adapter.isHealthy(), isTrue);
    });

    // --- degraded inference guard -------------------------------------------

    test('runInference throws AIInferenceError when adapter is degraded',
        () async {
      await adapter.simulateMemoryPressure(160);
      await expectLater(
        adapter.runInference(AIInput(text: 'hello')),
        throwsA(isA<AIInferenceError>()),
      );
    });
  });
}
