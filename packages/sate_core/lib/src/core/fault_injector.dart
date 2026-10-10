import 'fault_type.dart';

/// Abstract base class for all SATE AI fault injectors.
///
/// Implement this interface to create a custom fault scenario. Each injector
/// represents one failure mode (e.g. memory pressure, malformed input).
///
/// ## Example
///
/// ```dart
/// class ThermalThrottleInjector implements FaultInjector {
///   @override
///   FaultType get type => FaultType.thermalThrottle;
///
///   @override
///   String get name => 'Thermal Throttle Injector';
///
///   @override
///   String get description => 'Simulates CPU throttling under heat';
///
///   @override
///   Future<void> inject() async {
///     // artificially increase CPU load
///   }
///
///   @override
///   Future<void> reset() async {}
/// }
/// ```
abstract class FaultInjector {
  /// The [FaultType] category this injector belongs to.
  FaultType get type;

  /// Short human-readable name shown in reports and logs.
  String get name;

  /// Detailed description of what this injector simulates.
  String get description;

  /// Activate the fault.
  ///
  /// Called by `StressRunner` before each inference cycle. The injector
  /// should set up conditions (allocate memory, delay calls, etc.) that
  /// stress the model under test.
  Future<void> inject();

  /// Deactivate the fault and restore normal conditions.
  ///
  /// Always called after [inject], even if an error was thrown. Implementations
  /// must be idempotent (safe to call multiple times).
  Future<void> reset();
}
