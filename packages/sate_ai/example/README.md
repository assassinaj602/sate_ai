# SATE AI Example

A minimal Flutter app that demonstrates SATE AI's stress testing framework
on a variety of on-device AI models.

## Running the example

```bash
cd example
flutter pub get
flutter run
```

The app runs on Android, iOS, web, macOS, Linux, and Windows.

> Web builds are not supported when the TFLite adapter is active. The
> tflite_flutter package relies on native FFI bindings that cannot be
> transpiled to JavaScript. Web projects should use MockAdapter or a
> web-compatible adapter.

## What it demonstrates

- Interactive Guided Tutorial: Step-by-step onboarding walkthrough covering installation, basic testing, configuring injectors, custom adapter implementation, and analyzing stress reports
- Swapping between MockAdapter, OnnxAdapter, and TFLiteAdapter
- Selecting different fault injectors (Memory Pressure, Malformed Input, Thermal Throttle, Quantization Drift, Confidence Validator, Adaptive Chaos)
- Viewing the resulting StressReport
- Copying the report to JSON or Markdown

## Interactive Tutorial

Launch the example app and tap the **Tutorial** button in the top navigation bar to open the interactive guided walkthrough. The tutorial covers:
1. **Installation and Architecture**: Cross-platform configuration for Flutter, CLI, Android, and Web.
2. **Basic Test Execution**: Selecting adapters and executing baseline inference probes.
3. **Configuring Fault Injectors**: Simulating memory exhaustion, thermal throttling, input corruption, and dynamic adaptive chaos.
4. **Implementing Custom Adapters**: Writing custom wrappers for proprietary vision and LLM models.
5. **Analyzing Reports and Metrics**: Interpreting pass/fail rates, latency percentiles, memory consumption, and golden baseline comparisons.

## Adding real models

Place your model files in `assets/models/` and reference them in
`pubspec.yaml` under `flutter.assets`.
