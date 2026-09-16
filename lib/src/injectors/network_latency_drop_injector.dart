import 'dart:async';
import 'dart:math';

import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Simulates network failures (latency spikes, timeouts, disconnections).
///
/// This injector simulates various network issues that can affect hybrid
/// on-device/cloud models that fall back to cloud inference when on-device
/// inference fails.
///
/// Supported failure modes:
/// - Latency: Adds delay to inference (simulates slow network)
/// - Timeout: Simulates network timeout (inference fails)
/// - Disconnection: Simulates complete network loss
class NetworkLatencyDropInjector implements FaultInjector {
  /// Network failure type to simulate.
  final NetworkFailureType failureType;

  /// Additional latency in milliseconds (only for latency mode).
  final int latencyMs;

  /// Timeout duration in milliseconds (only for timeout mode).
  final int timeoutMs;

  /// Whether the network is currently disconnected.
  bool _isDisconnected = false;

  /// Number of times the injector has been applied.
  int _injectionCount = 0;

  /// Random for realistic jitter in latency.
  static final Random _random = Random();

  /// Creates a [NetworkLatencyDropInjector].
  NetworkLatencyDropInjector({
    this.failureType = NetworkFailureType.latency,
    this.latencyMs = 1000,
    this.timeoutMs = 5000,
  })  : assert(latencyMs >= 0, 'latencyMs must be >= 0'),
        assert(timeoutMs >= 0, 'timeoutMs must be >= 0');

  @override
  FaultType get type => FaultType.networkFailure;

  @override
  String get name {
    switch (failureType) {
      case NetworkFailureType.latency:
        return 'Network Latency Injector';
      case NetworkFailureType.timeout:
        return 'Network Timeout Injector';
      case NetworkFailureType.disconnection:
        return 'Network Disconnection Injector';
    }
  }

  @override
  String get description {
    switch (failureType) {
      case NetworkFailureType.latency:
        return 'Simulates network latency of ${latencyMs}ms per injection';
      case NetworkFailureType.timeout:
        return 'Simulates network timeout after ${timeoutMs}ms';
      case NetworkFailureType.disconnection:
        return 'Simulates complete network disconnection';
    }
  }

  @override
  Future<void> inject() async {
    _injectionCount++;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  Future<void> reset() async {
    _isDisconnected = false;
    _injectionCount = 0;
    await Future.delayed(Duration.zero);
  }

  /// Applies the network failure to the model adapter.
  ///
  /// This simulates network failures by adding latency, triggering timeouts,
  /// or disconnecting the network. The model adapter can check the
  /// network state via `isNetworkAvailable()` or fallback to cloud inference.
  Future<void> applyTo(AIModelAdapter model) async {
    _injectionCount++;
    switch (failureType) {
      case NetworkFailureType.latency:
        // Add jitter to make it realistic
        final jitter = _random.nextInt(200) - 100; // -100 to +100 ms
        final totalLatency = max(0, latencyMs + jitter);
        await Future.delayed(Duration(milliseconds: totalLatency));
        break;

      case NetworkFailureType.timeout:
        // Simulate timeout by throwing an exception
        throw AIInferenceError(
          'Network timeout after ${timeoutMs}ms (injection #$_injectionCount)',
        );

      case NetworkFailureType.disconnection:
        // Simulate disconnection by marking network as unavailable
        _isDisconnected = true;
        throw AIInferenceError(
          'Network disconnected (injection #$_injectionCount)',
        );
    }

    // Simulate memory pressure proportional to the failure type
    final memoryToSimulate = _injectionCount * 10;
    await model.simulateMemoryPressure(memoryToSimulate);

    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Whether the network is currently disconnected.
  bool get isDisconnected => _isDisconnected;

  /// Number of times the injector has been applied.
  int get injectionCount => _injectionCount;

  /// Convenience method to get the status as a readable string.
  String getStatus() {
    switch (failureType) {
      case NetworkFailureType.latency:
        return 'Latency: ${latencyMs}ms (applied $_injectionCount times)';
      case NetworkFailureType.timeout:
        return 'Timeout: ${timeoutMs}ms (applied $_injectionCount times)';
      case NetworkFailureType.disconnection:
        return 'Disconnected: ${_isDisconnected ? "YES" : "NO"} (applied $_injectionCount times)';
    }
  }
}

/// Network failure types supported by the injector.
enum NetworkFailureType {
  /// Simulates network latency (delays).
  latency,

  /// Simulates network timeout (inference fails).
  timeout,

  /// Simulates network disconnection (complete loss of connectivity).
  disconnection,
}
