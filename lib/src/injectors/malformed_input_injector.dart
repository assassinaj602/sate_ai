import 'dart:math';

import '../adapters/model_adapter.dart';
import '../core/fault_injector.dart';
import '../core/fault_type.dart';

/// The variants of malformed input that [MalformedInputInjector] generates.
enum MalformedInputKind {
  /// An empty string (`''`).
  empty,

  /// A string of 1 MB of repeated `X` characters.
  oversized,

  /// 1 KB of random bytes passed as binary input.
  binaryGarbage,
}

/// Injects malformed, boundary-violating, and random inputs to test that
/// an AI model handles bad data without crashing or producing corrupt output.
///
/// Unlike other injectors, [MalformedInputInjector] does not modify the
/// model's state; instead it provides factory methods for generating bad
/// [AIInput] payloads that you can pass directly to
/// [AIModelAdapter.runInference].
///
/// ## Usage
///
/// ```dart
/// final injector = MalformedInputInjector();
///
/// // Generate and test a random malformed input
/// final badInput = MalformedInputInjector.generate();
/// try {
///   final out = await model.runInference(badInput);
///   assert(MalformedInputInjector.isHandledGracefully(out));
/// } on AIInferenceError catch (e) {
///   // Acceptable — model rejected the input explicitly
/// }
/// ```
class MalformedInputInjector implements FaultInjector {
  /// Creates a [MalformedInputInjector].
  const MalformedInputInjector();

  static final Random _rng = Random();

  @override
  FaultType get type => FaultType.malformedInput;

  @override
  String get name => 'Malformed Input Injector';

  @override
  String get description =>
      'Generates empty, oversized, and binary-garbage inputs to test model '
      'input validation.';

  /// No state to inject — this injector works via [generate].
  @override
  Future<void> inject() => Future<void>.value();

  /// No state to restore.
  @override
  Future<void> reset() => Future<void>.value();

  // ---------------------------------------------------------------------------
  // Static factory helpers
  // ---------------------------------------------------------------------------

  /// Generates a random [AIInput] of one of the [MalformedInputKind] variants.
  static AIInput generate([MalformedInputKind? kind]) {
    final selected = kind ??
        MalformedInputKind
            .values[_rng.nextInt(MalformedInputKind.values.length)];
    return generateKind(selected);
  }

  /// Generates an [AIInput] for the specified [kind].
  static AIInput generateKind(MalformedInputKind kind) {
    switch (kind) {
      case MalformedInputKind.empty:
        return AIInput(text: '');
      case MalformedInputKind.oversized:
        // 1 MB string
        return AIInput(text: 'X' * (1024 * 1024));
      case MalformedInputKind.binaryGarbage:
        final bytes = List<int>.generate(1024, (_) => _rng.nextInt(256));
        return AIInput(binary: bytes);
    }
  }

  /// Returns `true` when [output] appears to have been handled gracefully.
  ///
  /// A model that crashes, returns an empty string, or propagates the raw
  /// error message is considered to have **not** handled the input gracefully.
  static bool isHandledGracefully(AIOutput output) {
    if (output.text.isEmpty) return false;
    final lower = output.text.toLowerCase();
    if (lower.contains('exception') || lower.contains('stack trace')) {
      return false;
    }
    return true;
  }
}
