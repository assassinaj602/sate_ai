import 'dart:math';
import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Random Gaussian extension helper.
extension _RandomGaussian on Random {
  double nextGaussian() {
    double u1 = nextDouble();
    double u2 = nextDouble();
    while (u1 <= 1e-15) {
      u1 = nextDouble();
    }
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }
}

/// Simulates corrupted input data (image noise, missing pixels, audio glitches).
///
/// This injector modifies input data to simulate various types of corruption
/// that can occur in real-world scenarios. It supports:
/// - Gaussian noise: Adds random noise to input
/// - Blur: Simulates blurry or out-of-focus inputs
/// - Occlusion: Simulates missing or blocked parts of input
/// - Salt & Pepper noise: Random bright/dark pixels
/// - Audio glitch: Simulates audio artifacts
class DataCorruptionInjector implements FaultInjector {
  /// Type of corruption to apply.
  final DataCorruptionType corruptionType;

  /// Intensity of the corruption (0.0 to 1.0).
  final double intensity;

  /// Seed for deterministic randomness (for reproducibility).
  final int? seed;

  int _injectionCount = 0;

  /// Creates a [DataCorruptionInjector].
  DataCorruptionInjector({
    this.corruptionType = DataCorruptionType.gaussianNoise,
    this.intensity = 0.1,
    this.seed,
  }) : assert(intensity >= 0.0 && intensity <= 1.0,
            'intensity must be between 0.0 and 1.0');

  @override
  FaultType get type => FaultType.dataCorruption;

  @override
  String get name {
    switch (corruptionType) {
      case DataCorruptionType.gaussianNoise:
        return 'Gaussian Noise Injector';
      case DataCorruptionType.blur:
        return 'Blur Injector';
      case DataCorruptionType.occlusion:
        return 'Occlusion Injector';
      case DataCorruptionType.saltPepper:
        return 'Salt & Pepper Noise Injector';
      case DataCorruptionType.audioGlitch:
        return 'Audio Glitch Injector';
    }
  }

  @override
  String get description {
    switch (corruptionType) {
      case DataCorruptionType.gaussianNoise:
        return 'Adds Gaussian noise with intensity $intensity to input data';
      case DataCorruptionType.blur:
        return 'Applies blur with intensity $intensity to input data';
      case DataCorruptionType.occlusion:
        return 'Blocks $intensity of input data (simulates missing parts)';
      case DataCorruptionType.saltPepper:
        return 'Adds salt & pepper noise with intensity $intensity to input data';
      case DataCorruptionType.audioGlitch:
        return 'Simulates audio glitch with intensity $intensity';
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
    await Future.delayed(Duration.zero);
  }

  /// Applies corruption to the input data.
  ///
  /// This method corrupts the input data and then runs inference on the corrupted data.
  /// The model is expected to handle the corrupted input gracefully.
  Future<void> applyTo(AIModelAdapter model) async {
    _injectionCount++;
    // Simulate memory pressure based on intensity
    final memoryToSimulate = (intensity * 100).round();
    await model.simulateMemoryPressure(memoryToSimulate);

    // If intensity is high, simulate degradation
    if (intensity > 0.6) {
      // Simulate that the model failed due to corruption
      throw AIInferenceError(
        'Data corruption (${corruptionType.name}) at intensity $intensity caused inference failure (injection #$_injectionCount)',
      );
    }

    // For lower intensity, we just add memory pressure but let inference succeed
    await Future.delayed(const Duration(milliseconds: 50));
  }

  /// Number of times the injector has been applied.
  int get injectionCount => _injectionCount;

  /// Convenience method to get the status as a readable string.
  String getStatus() {
    return '${corruptionType.name}: intensity $intensity (applied $_injectionCount times)';
  }

  /// Simulate corruption on a list of input values (for testing).
  ///
  /// This is a utility method to demonstrate the corruption effect.
  List<double> corruptData(List<double> data) {
    final rng = seed != null ? Random(seed!) : Random();
    final result = List<double>.from(data);

    switch (corruptionType) {
      case DataCorruptionType.gaussianNoise:
        for (var i = 0; i < result.length; i++) {
          final noise = rng.nextGaussian() * intensity * 0.5;
          result[i] = result[i] + noise;
          result[i] = result[i].clamp(0.0, 1.0);
        }
        break;

      case DataCorruptionType.blur:
        // Simple moving average blur
        final windowSize = max(1, (intensity * 5).round());
        final temp = List<double>.from(result);
        for (var i = 0; i < result.length; i++) {
          var sum = 0.0;
          var count = 0;
          for (var j = -windowSize; j <= windowSize; j++) {
            final index = i + j;
            if (index >= 0 && index < result.length) {
              sum += temp[index];
              count++;
            }
          }
          result[i] = sum / count;
        }
        break;

      case DataCorruptionType.occlusion:
        final blockSize = max(1, (intensity * result.length).round());
        final start = rng.nextInt(result.length - blockSize);
        for (var i = start; i < start + blockSize; i++) {
          result[i] = 0.0;
        }
        break;

      case DataCorruptionType.saltPepper:
        for (var i = 0; i < result.length; i++) {
          final rand = rng.nextDouble();
          if (rand < intensity / 2) {
            result[i] = 0.0; // pepper
          } else if (rand < intensity) {
            result[i] = 1.0; // salt
          }
        }
        break;

      case DataCorruptionType.audioGlitch:
        // Simulate audio glitch: random pops and clicks
        var glitched = false;
        for (var i = 0; i < result.length; i++) {
          if (rng.nextDouble() < intensity * 0.5) {
            result[i] = rng.nextDouble() * 2 - 1; // random spike
            glitched = true;
          }
        }
        if (!glitched && result.isNotEmpty) {
          final idx = rng.nextInt(result.length);
          result[idx] = rng.nextDouble() * 2 - 1;
        }
        break;
    }

    return result;
  }
}

/// Types of data corruption supported by the injector.
enum DataCorruptionType {
  /// Adds Gaussian noise to input data.
  gaussianNoise,

  /// Applies blur to input data.
  blur,

  /// Blocks out parts of input data (simulates missing pixels/samples).
  occlusion,

  /// Adds salt & pepper noise (random bright/dark pixels).
  saltPepper,

  /// Simulates audio glitches (pops, clicks, artifacts).
  audioGlitch,
}
