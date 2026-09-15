# Multi-Injector Integration Guide & Best Practices

This guide covers composing multiple fault injectors into cohesive testing pipelines, handling flaky models, and setting up automated CI/CD regression gates.

---

## 🔀 Composing Multiple Fault Injectors

In real deployments, hardware issues don't happen in isolation. Devices frequently experience high RAM usage, elevated temperatures, and malformed inputs simultaneously.

```dart
import 'package:sate_ai/sate_ai.dart';

Future<void> runEndToEndPipeline(AIModelAdapter model) async {
  final runner = StressRunner(
    injectors: [
      MemoryPressureInjector(model: model, limitMb: 250),
      ThermalThrottleInjector(model: model, maxTemperature: 80),
      MalformedInputInjector(),
      QuantizationDriftInjector(model: model, driftFactor: 0.05),
    ],
    timeout: const Duration(seconds: 40),
    retryCount: 2,          // Automatically retries flaky tests up to 2 times
    flakyThreshold: 1,      // Flags test as flaky if it fails once before passing
  );

  final report = await runner.run(model);
  
  if (!report.passed) {
    for (final failure in report.failures) {
      print('❌ ${failure.injectorType.displayName} failed: ${failure.message}');
    }
  } else {
    print('✅ All multi-fault resilience checks passed.');
  }
}
```

---

## 📈 Baseline Regressions & CI Integration

Combine stress testing with `BaselineManager` to prevent performance degradation across releases:

```dart
final baselineManager = BaselineManager(tolerancePercent: 10.0);

// Check current report against golden baseline
final comparison = await baselineManager.checkAgainstBaseline(currentReport);
if (comparison != null && !comparison.passed) {
  throw Exception('Performance regression detected against baseline: ${comparison.summary}');
}
```

---

## 💡 Best Practices

1. **Test in Realistic Threading Environments**: Run tests on physical hardware or CI runners with constrained CPU cores.
2. **Combine Retries with Flakiness Tracking**: Use `retryCount` and `flakyThreshold` to uncover transient memory leaks vs permanent regressions.
3. **Save Markdown Reports as CI Artifacts**: Use `report.toMarkdown()` or `report.toHtml()` to publish test summaries to GitHub Actions or GitLab CI.
