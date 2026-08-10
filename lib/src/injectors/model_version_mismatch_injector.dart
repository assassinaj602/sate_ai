import 'dart:async';
import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Simulates model version mismatch (e.g., expects v2 but loads v1).
///
/// This injector tests how the application handles version mismatches
/// when loading models. It simulates:
/// - Loading an older version (downgrade scenario)
/// - Loading a newer version (upgrade scenario)
/// - Complete version mismatch (incompatible versions)
///
/// The injector can also simulate version detection and fallback behavior.
class ModelVersionMismatchInjector implements FaultInjector {
  /// Type of version mismatch to simulate.
  final VersionMismatchType mismatchType;

  /// Expected version (e.g., "2.0.0").
  final String expectedVersion;

  /// Actual version loaded (e.g., "1.0.0").
  final String actualVersion;

  /// Whether the app should attempt fallback to another version.
  final bool attemptFallback;

  int _injectionCount = 0;
  bool _mismatchDetected = false;
  String? _errorMessage;

  /// Creates a [ModelVersionMismatchInjector].
  ModelVersionMismatchInjector({
    this.mismatchType = VersionMismatchType.olderVersion,
    this.expectedVersion = "2.0.0",
    this.actualVersion = "1.0.0",
    this.attemptFallback = false,
  })  : assert(expectedVersion.isNotEmpty, 'expectedVersion must not be empty'),
        assert(actualVersion.isNotEmpty, 'actualVersion must not be empty');

  @override
  FaultType get type => FaultType.modelVersionMismatch;

  @override
  String get name {
    switch (mismatchType) {
      case VersionMismatchType.olderVersion:
        return 'Older Model Version Injector';
      case VersionMismatchType.newerVersion:
        return 'Newer Model Version Injector';
      case VersionMismatchType.incompatible:
        return 'Incompatible Model Version Injector';
    }
  }

  @override
  String get description {
    switch (mismatchType) {
      case VersionMismatchType.olderVersion:
        return 'Simulates loading older version ($actualVersion) instead of expected ($expectedVersion)';
      case VersionMismatchType.newerVersion:
        return 'Simulates loading newer version ($actualVersion) instead of expected ($expectedVersion)';
      case VersionMismatchType.incompatible:
        return 'Simulates loading incompatible version ($actualVersion) instead of expected ($expectedVersion)';
    }
  }

  @override
  Future<void> inject() async {
    _injectionCount++;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> reset() async {
    _injectionCount = 0;
    _mismatchDetected = false;
    _errorMessage = null;
    await Future.delayed(Duration.zero);
  }

  /// Detects if there is a version mismatch.
  bool detectMismatch() {
    // For simplicity, assume any difference is a mismatch
    // In a real implementation, this would parse and compare versions.
    if (expectedVersion == actualVersion) {
      _mismatchDetected = false;
      return false;
    }

    // Check if versions are compatible (simplified)
    if (mismatchType == VersionMismatchType.incompatible) {
      _mismatchDetected = true;
      _errorMessage =
          'Incompatible version: $actualVersion != $expectedVersion';
      return true;
    }

    // For older/newer, we treat as mismatch but may be recoverable
    _mismatchDetected = true;
    _errorMessage =
        'Version mismatch: expected $expectedVersion but found $actualVersion';
    return true;
  }

  /// Simulates attempting to fallback to another version.
  Future<bool> fallbackToVersion() async {
    // Simulate fallback attempt
    await Future.delayed(const Duration(milliseconds: 100));
    // Return success if fallback is enabled and it's not an incompatible mismatch
    if (attemptFallback && mismatchType != VersionMismatchType.incompatible) {
      // Simulate loading a compatible version
      _mismatchDetected = false;
      _errorMessage = null;
      return true;
    }
    return false;
  }

  /// Applies the injector to a model adapter.
  ///
  /// This simulates the version mismatch by:
  /// 1. Detecting the mismatch.
  /// 2. Optionally attempting fallback.
  /// 3. If mismatch persists, failing the test.
  @override
  Future<void> applyTo(AIModelAdapter model) async {
    _injectionCount++;
    // Simulate version detection
    final mismatch = detectMismatch();

    if (mismatch) {
      // Try fallback if enabled
      if (attemptFallback) {
        final fallbackSuccess = await fallbackToVersion();
        if (fallbackSuccess) {
          // Fallback succeeded, add some memory pressure but continue
          await model.simulateMemoryPressure(10);
          return;
        }
      }

      // Mismatch detected and no fallback or fallback failed
      await model.simulateMemoryPressure(50);

      // Simulate degradation
      throw AIInferenceError(
        'Model version mismatch: $actualVersion (actual) != $expectedVersion (expected). '
        'Fallback: ${attemptFallback ? "attempted but failed" : "not attempted"}',
      );
    }

    // No mismatch, just add some memory pressure
    await model.simulateMemoryPressure(5);
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Whether a version mismatch was detected.
  bool get mismatchDetected => _mismatchDetected;

  /// The error message for the mismatch.
  String? get errorMessage => _errorMessage;

  /// Number of times the injector has been applied.
  int get injectionCount => _injectionCount;

  /// Convenience method to get the status as a readable string.
  String getStatus() {
    if (_mismatchDetected) {
      return 'MISMATCH: $actualVersion != $expectedVersion (applied $_injectionCount times)';
    }
    return 'OK: $actualVersion == $expectedVersion (applied $_injectionCount times)';
  }
}

/// Types of version mismatch supported by the injector.
enum VersionMismatchType {
  /// Simulates loading an older version.
  olderVersion,

  /// Simulates loading a newer version.
  newerVersion,

  /// Simulates loading an incompatible version.
  incompatible,
}
