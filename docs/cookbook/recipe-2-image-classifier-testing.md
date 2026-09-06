# Recipe 2: Testing an Image Classifier

This recipe details testing on-device computer vision models (MobileNet, ResNet, EfficientNet, YOLO) against real-world device thermal constraints, latency delays, and asset corruption.

---

## 🎯 Testing Goals

1. **Thermal Throttling**: Test behavior when CPU/GPU core temperatures elevate (e.g. 70°C+) during continuous real-time camera feed processing.
2. **Inference Latency Spike**: Validate that UI rendering (60/120 fps) does not freeze when an inference cycle is delayed by 150–500ms.
3. **Model Swap & Corrupted Assets**: Verify that missing or corrupted model weights fall back to a placeholder or cloud-assisted endpoint.

---

## 💻 Code Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  test('Vision Image Classifier testing under thermal throttling and latency', () async {
    final model = MockAdapter(modelId: 'mobilenet_v3_quant.tflite');

    final injectors = [
      ThermalThrottleInjector(
        model: model,
        temperatureStep: 15,
        maxTemperature: 85,
      ),
      LatencyInjector(
        model: model,
        latency: const Duration(milliseconds: 300),
      ),
      ModelSwapInjector(
        model: model,
        alternateModelId: 'mobilenet_fallback_tiny.tflite',
      ),
    ];

    final report = await SateAI.stress(
      model: model,
      injectors: injectors,
      timeout: const Duration(seconds: 30),
    );

    expect(report.passed, isTrue);

    for (final result in report.results) {
      print('${result.injectorType.displayName}: ${result.passed ? "PASSED" : "FAILED"} (${result.durationMs}ms)');
    }
  });
}
```

---

## 📊 Performance Benchmarks & Visualization

When evaluating vision models:
- Monitor camera frame drop rates when `ThermalThrottleInjector` is active.
- Verify that `ModelSwapInjector` triggers proper model reloading events without app restart.
- Export results to HTML diff views using `--diff-html` to compare classification accuracy across thermal cycles.
