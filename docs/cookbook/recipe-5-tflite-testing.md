# Recipe 5: Testing with TensorFlow Lite

This recipe demonstrates testing TensorFlow Lite (`.tflite`) models on Flutter using `TFLiteAdapter`.

---

## 🎯 Testing Goals

1. **Quantization Precision Drift**: Assess impact of INT8 / FP16 quantized models under repeated stress cycles.
2. **GPU Delegate & NNAPI Resilience**: Validate model stability when switching hardware delegates or under thermal throttling.
3. **Multi-Model Batch Testing**: Run simultaneous stress batches across multiple TFLite asset files.

---

## 💻 Code Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  test('TFLiteAdapter stress testing with delegates and quantization drift', () async {
    // 1. Instantiate TFLiteAdapter
    final adapter = TFLiteAdapter(
      modelId: 'assets/models/detector_quant.tflite',
    );

    // 2. Configure injectors
    final injectors = [
      MemoryPressureInjector(model: adapter, limitMb: 150.0),
      ThermalThrottleInjector(model: adapter, temperatureStep: 10),
      QuantizationDriftInjector(
        model: adapter,
        driftFactor: 0.05,
        degradationThreshold: 0.25,
      ),
    ];

    // 3. Run stress test suite
    final report = await SateAI.stress(
      model: adapter,
      injectors: injectors,
      timeout: const Duration(seconds: 20),
    );

    expect(report.passed, isTrue);

    // 4. Save golden baseline for CI regression tracking
    final baselineManager = BaselineManager();
    final baselinePath = await baselineManager.saveBaseline(report);
    print('Baseline saved at $baselinePath');
  });
}
```

---

## 🔧 TFLite Delegate Configuration Notes

- **GPU Delegate Fallback**: On older Android or low-tier devices, GPU delegates can fail on initialization; make sure your adapter code falls back to CPU cleanly.
- **Thread Count Tuning**: Set optimal thread count (typically 2–4 on mobile cores) before running stress benchmarks to avoid CPU starvation.
