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

  /// Battery percentage threshold below which low-battery throttling triggers.
  final int batteryThreshold;

  /// Battery percentage drop per injection step.
  final double batteryDropStep;

  /// The model adapter to stress.
  final AIModelAdapter model;

  int _currentTemperature = 25;
  bool _isThrottling = false;
  int _throttleCount = 0;
  final List<int> _temperatureHistory = [];

  int _batteryLevel = 100;
  bool _isBatteryLow = false;

  /// Creates a [ThermalThrottleInjector].
  ///
  /// [model] is the model adapter instance to apply the thermal simulation to.
  /// [temperatureStep] is the temperature increase per injection.
  /// [maxTemperature] is the threshold above which throttling triggers.
  /// [throttledDelayMs] and [extraDelayMs] are the simulated latencies applied.
  /// [batteryThreshold] is the low-battery threshold (default 20%).
  /// [batteryDropStep] is the battery percentage drop per step (default 5.0).
  ThermalThrottleInjector({
    required this.model,
    this.temperatureStep = 10,
    this.maxTemperature = 85,
    this.throttledDelayMs = 200,
    this.extraDelayMs = 500,
    this.batteryThreshold = 20,
    this.batteryDropStep = 5.0,
  })  : assert(temperatureStep > 0 && temperatureStep <= 50,
            'temperatureStep must be between 1 and 50'),
        assert(maxTemperature >= 40 && maxTemperature <= 120,
            'maxTemperature must be between 40 and 120'),
        assert(batteryThreshold >= 5 && batteryThreshold <= 50,
            'batteryThreshold must be between 5 and 50'),
        assert(batteryDropStep > 0 && batteryDropStep <= 50,
            'batteryDropStep must be between 0 and 50');

  @override
  FaultType get type => FaultType.thermalThrottle;

  @override
  String get name => 'Thermal Throttle Injector';

  @override
  String get description =>
      'Simulates CPU thermal throttling by increasing temperature by '
      '$temperatureStep°C per injection. Throttles at $maxTemperature°C.';

  /// Injects the thermal throttle simulation.
  ///
  /// Each call increases the simulated temperature by [temperatureStep] and
  /// records it. If the temperature exceeds [maxTemperature], the model adapter
  /// is throttled, incurring delays and simulating proportional memory pressure.
  @override
  Future<void> inject() async {
    _currentTemperature += temperatureStep;
    _temperatureHistory.add(_currentTemperature);

    // Battery drain simulation
    _batteryLevel = (_batteryLevel - batteryDropStep).clamp(0.0, 100.0).toInt();
    if (_batteryLevel <= batteryThreshold) {
      _isBatteryLow = true;
    }

    if (_currentTemperature >= maxTemperature || _isBatteryLow) {
      _isThrottling = true;
      _throttleCount++;
    }

    // Apply throttling effect to the model
    // Simulate memory pressure proportional to temperature
    final memoryToSimulate = (_currentTemperature / 10).round();
    await model.simulateMemoryPressure(memoryToSimulate);

    if (_isBatteryLow) {
      await model.simulateMemoryPressure(30);
    }

    if (_isThrottling) {
      await model.simulateMemoryPressure(20);
      if (_isBatteryLow) {
        await Future.delayed(
          Duration(milliseconds: throttledDelayMs + extraDelayMs + 200),
        );
      } else {
        await Future.delayed(
          Duration(milliseconds: throttledDelayMs + extraDelayMs),
        );
      }
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
    _batteryLevel = 100;
    _isBatteryLow = false;
    await model.reset();
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Current simulated temperature in Celsius.
  int get currentTemperature => _currentTemperature;

  /// Current simulated battery level percentage (0 - 100).
  int get batteryLevel => _batteryLevel;

  /// Whether the battery is currently in a low state (<= [batteryThreshold]).
  bool get isBatteryLow => _isBatteryLow;

  /// Whether the injector is currently throttling.
  bool get isThrottling => _isThrottling;

  /// Number of times throttling has been triggered.
  int get throttleCount => _throttleCount;

  /// History of temperatures across injections.
  List<int> get temperatureHistory => List.unmodifiable(_temperatureHistory);

  /// Number of injection steps applied.
  int get injectionSteps => _temperatureHistory.length;

  /// Whether the model should be considered degraded.
  bool get isDegraded => _isThrottling || _isBatteryLow;

  /// Convenience method to get the throttling status as a readable string.
  String getStatus() {
    if (_isThrottling) {
      return 'THROTTLING (temperature: $_currentTemperature°C, battery: $_batteryLevel%, count: $_throttleCount)';
    }
    return 'Normal (temperature: $_currentTemperature°C, battery: $_batteryLevel%)';
  }
}
