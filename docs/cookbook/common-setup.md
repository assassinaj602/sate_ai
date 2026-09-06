# Common Setup & Utilities for SATE AI Recipes

This guide provides common boilerplate, model mocking utilities, and reusable test fixtures used throughout the cookbook recipes.

---

## 🏗️ 1. Test Harness Setup

When writing Flutter unit or widget tests with SATE AI:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('SATE AI Stress Test Fixture', () {
    late MockAdapter mockModel;

    setUp(() {
      mockModel = MockAdapter(modelId: 'shared-fixture-model');
    });

    tearDown(() async {
      await mockModel.reset();
    });

    test('validates model health baseline', () {
      expect(mockModel.isHealthy(), isTrue);
      expect(mockModel.currentMemoryMB, equals(0.0));
    });
  });
}
```

---

## 📦 2. Reusable Fault Injector Presets

Define standard injector bundles for CI testing vs deep stress testing:

```dart
import 'package:sate_ai/sate_ai.dart';

/// Lightweight smoke test suite (suitable for pull request CI)
List<FaultInjector> smokeTestSuite(AIModelAdapter model) => [
  MemoryPressureInjector(model: model, limitMb: 100.0),
  MalformedInputInjector(),
];

/// Deep stress suite (suitable for nightly / scheduled testing)
List<FaultInjector> comprehensiveStressSuite(AIModelAdapter model) => [
  MemoryPressureInjector(model: model, limitMb: 250.0),
  MalformedInputInjector(),
  ThermalThrottleInjector(model: model, temperatureStep: 10, maxTemperature: 80),
  LatencyInjector(model: model, latency: const Duration(milliseconds: 200)),
  QuantizationDriftInjector(model: model, driftFactor: 0.05),
];
```
