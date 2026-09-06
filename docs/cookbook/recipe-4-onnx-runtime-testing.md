# Recipe 4: Testing with ONNX Runtime

This recipe details using `OnnxAdapter` to run comprehensive fault injection tests directly against ONNX model artifacts (.onnx) in Flutter applications.

---

## 🎯 Testing Goals

1. **Asset Loading Verification**: Ensure the `.onnx` graph is properly loaded into memory and sessions are cleanly created.
2. **Dimension Shape Mismatch Handling**: Inject non-conforming tensor inputs and assert that exceptions are caught without crashing native memory pointers.
3. **Execution Providers & Fallback**: Stress memory to trigger CPU/NNAPI fallback if GPU/NPU memory is depleted.

---

## 💻 Code Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  test('ONNX Runtime model stress verification with all core injectors', () async {
    // 1. Initialize OnnxAdapter
    final adapter = OnnxAdapter(
      modelId: 'models/sentiment_analysis.onnx',
    );

    // 2. Build full injector test suite
    final injectors = [
      MemoryPressureInjector(model: adapter, limitMb: 200.0),
      MalformedInputInjector(),
      LatencyInjector(model: adapter, latency: const Duration(milliseconds: 100)),
      ThermalThrottleInjector(model: adapter),
      QuantizationDriftInjector(model: adapter),
    ];

    // 3. Execute stress test
    final report = await SateAI.stress(
      model: adapter,
      injectors: injectors,
      timeout: const Duration(seconds: 30),
    );

    // 4. Validate output
    expect(report.passed, isTrue);
    expect(report.results.length, equals(5));

    // Export HTML report for dashboard
    final html = report.toHtml();
    expect(html, contains('sentiment_analysis.onnx'));
  });
}
```

---

## ⚙️ ONNX-Specific Configuration Notes

- **Input Tensor Dimensions**: Set explicit batch and sequence dimensions if dynamic axis shapes cause memory fragmentation.
- **Session Cleanup**: Always invoke `dispose()` or rely on SATE AI lifecycle management to avoid native C++ memory leaks.
