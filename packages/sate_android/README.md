# sate-android

Kotlin/Android SDK for SATE AI, a fault-injection framework for on-device AI models.

## Install

Add to your app's build.gradle.kts:

```kotlin
dependencies {
    testImplementation("io.github.assassinaj602:sate-ai-android:0.1.0")
}
```

## Usage

```kotlin
class MyModelReliabilityTest {
    @Test
    fun testModelReliability() = runBlocking {
        val model = MockModelAdapter()
        val runner = StressRunner(
            model = model,
            injectors = listOf(
                MemoryPressureInjector(model, 150),
                MalformedInputInjector(),
            ),
        )
        val report = runner.run()
        assertTrue(report.passed)
    }
}
```

## Supported Adapters and Injectors

- **Adapters**:
  - `MockModelAdapter` (for JVM unit tests)
  - `TFLiteModelAdapter` (for native TensorFlow Lite models on Android)
- **Fault Injectors**:
  - `MemoryPressureInjector`
  - `MalformedInputInjector`
  - `QuantizationDriftInjector`
  - `ThermalThrottleInjector`
  - `LatencyInjector`
  - `ModelSwapInjector`
  - `ConfidenceThresholdInjector`
  - `GpuMemoryPressureInjector`
  - `DataCorruptionInjector`
  - `ModelVersionMismatchInjector`
  - `NetworkLatencyDropInjector`

## License

MIT
