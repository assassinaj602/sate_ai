import 'dart:async';
import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Simulates CPU thermal throttling under sustained load.
///
/// Each call to [inject] increases the simulated temperature by [temperatureStep].
/// Once the temperature exceeds [maxTemperature], the injector enters a throttled
/// state where inference times are artificially increased and the model is marked
/// as degraded.
///
/// This is useful for testing how AI models behave when the device CPU is
/// throttled due to heat buildup.
class ThermalThrottleInjector implements FaultInjector {
  /// Temperature increase per injection in Celsius.
  final int temperatureStep;

  /// Maximum temperature before throttling begins (Celsius).
  final int maxTemperature;

  /// Delay to simulate throttled CPU (in milliseconds).
  final int throttledDelayMs;

  /// Simulated delay to apply during throttled state (in milliseconds).
  final int extraDelayMs;

  /// The model adapter to stress.
  final AIModelAdapter model;

  int _currentTemperature = 25;
  bool _isThrottling = false;
  int _throttleCount = 0;
  final List<int> _temperatureHistory = [];

  /// Creates a [ThermalThrottleInjector].
  ///
  /// [model] is the model adapter instance to apply the thermal simulation to.
  /// [temperatureStep] is the temperature increase per injection.
  /// [maxTemperature] is the threshold above which throttling triggers.
  /// [throttledDelayMs] and [extraDelayMs] are the simulated latencies applied.
  ThermalThrottleInjector({
    required this.model,
    this.temperatureStep = 10,
    this.maxTemperature = 85,
    this.throttledDelayMs = 200,
    this.extraDelayMs = 500,
  })  : assert(temperatureStep > 0 && temperatureStep <= 50,
            'temperatureStep must be between 1 and 50'),
        assert(maxTemperature >= 40 && maxTemperature <= 120,
            'maxTemperature must be between 40 and 120');

  @override
  FaultType get type => FaultType.thermalThrottle;

  @override
  String get name => 'Thermal Throttle Injector';

  @override
  String get description =>
      'Simulates CPU thermal throttling by increasing temperature by '
      '$temperatureStep°C per injection. Throttles at ${maxTemperature}°C.';

  /// Injects the thermal throttle simulation.
  ///
  /// Each call increases the simulated temperature by [temperatureStep] and
  /// records it. If the temperature exceeds [maxTemperature], the model adapter
  /// is throttled, incurring delays and simulating proportional memory pressure.
  @override
  Future<void> inject() async {
    _currentTemperature += temperatureStep;
    _temperatureHistory.add(_currentTemperature);

    if (_currentTemperature >= maxTemperature) {
      _isThrottling = true;
      _throttleCount++;
    }

    // Apply throttling effect to the model
    // Simulate memory pressure proportional to temperature
    final memoryToSimulate = (_currentTemperature / 10).round();
    await model.simulateMemoryPressure(memoryToSimulate);

    if (_isThrottling) {
      await model.simulateMemoryPressure(20);
      await Future.delayed(
        Duration(milliseconds: throttledDelayMs + extraDelayMs),
      );
    } else {
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }

  @override
  Future<void> reset() async {
    _currentTemperature = 25;
    _isThrottling = false;
    _throttleCount = 0;
    _temperatureHistory.clear();
    await model.reset();
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Current simulated temperature in Celsius.
  int get currentTemperature => _currentTemperature;

  /// Whether the injector is currently throttling.
  bool get isThrottling => _isThrottling;

  /// Number of times throttling has been triggered.
  int get throttleCount => _throttleCount;

  /// History of temperatures across injections.
  List<int> get temperatureHistory => List.unmodifiable(_temperatureHistory);

  /// Number of injection steps applied.
  int get injectionSteps => _temperatureHistory.length;

  /// Whether the model should be considered degraded.
  bool get isDegraded => _isThrottling;

  /// Convenience method to get the throttling status as a readable string.
  String getStatus() {
    if (_isThrottling) {
      return 'THROTTLING (temperature: ${_currentTemperature}°C, count: $_throttleCount)';
    }
    return 'Normal (temperature: ${_currentTemperature}°C)';
  }
}
