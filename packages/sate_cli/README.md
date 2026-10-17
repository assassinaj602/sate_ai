# sate_cli

Lightweight, standalone command-line tool for SATE AI on-device fault injection and reliability testing.

`sate_cli` allows developers and CI/CD pipelines to run automated stress tests, model quantization analyses, pre-flight cost estimations, benchmarks, batch suites, and cron schedules directly from the terminal without requiring the Flutter SDK.

---

## Installation

Install globally using the Dart SDK:

```bash
dart pub global activate sate_cli
```

Ensure your pub cache bin directory is in your `PATH`:

```bash
# Linux / macOS
export PATH="$PATH:$HOME/.pub-cache/bin"

# Windows
set PATH=%PATH%;%LOCALAPPDATA%\Pub\Cache\bin
```

Verify installation:

```bash
sate_ai --version
```

---

## Commands & Usage

### 1. Basic Fault Injection Stress Test

Execute fault injectors against a model file:

```bash
sate_ai --model assets/models/model.gguf --injectors memoryPressure,malformedInput,thermalThrottle
```

With automatic retries and flaky test detection:

```bash
sate_ai --model model.gguf --injectors memoryPressure --retry 3 --flaky-threshold 2
```

### 2. Adaptive Chaos Testing

Modulate injection intervals and memory intensity in real-time based on live device CPU, RAM, and thermal telemetry:

```bash
sate_ai --model model.gguf --adaptive-chaos --injectors memoryPressure,thermalThrottle
```

### 3. Pre-Flight Stress Test Cost Estimation

Estimate test run duration, RAM consumption, battery impact, and cloud spend before starting:

```bash
sate_ai --estimate --injectors memoryPressure,thermalThrottle --estimate-profile edge
```

Supported profiles: `edge`, `mobile`, `server`.

### 4. Model Quantization Analysis

Inspect weight distribution, quantization scheme, and precision drift risk for ONNX and TFLite models:

```bash
sate_ai --model assets/models/detector.onnx --quantization-analysis
```

### 5. Benchmark & Batch Mode

Benchmark inference latency percentiles:

```bash
sate_ai --model model.gguf --benchmark --benchmark-runs 50
```

Batch test multiple models across formats with auto-detection:

```bash
sate_ai --models model1.onnx,model2.tflite,model3.gguf --auto-detect
```

### 6. SQLite Storage & Historical Queries

Save test results to an embedded SQLite database and query historical regressions:

```bash
# Save run to SQLite
sate_ai --model model.gguf --injectors memoryPressure --db reports.db

# Query history
sate_ai --db reports.db --db-history all
```

### 7. Golden Baseline Comparison

Establish a performance baseline and fail CI runs if regressions exceed tolerance:

```bash
# Establish baseline
sate_ai --model model.gguf --baseline

# Compare future runs against baseline (fails if latency or memory exceeds 5%)
sate_ai --model model.gguf --compare --tolerance 5.0
```

### 8. HTML Reports & SVG Status Badges

Export rich, interactive HTML reports with Chart.js visualisations and generate Shields.io style status badges:

```bash
# Self-contained HTML report
sate_ai --model model.gguf --injectors memoryPressure --html --output report.html

# Generate SVG status badges
sate_ai --model model.gguf --badge badge.svg --badge-type status
```

### 9. Real-Time SSE Monitoring Server

Launch an embedded HTTP server streaming live test metrics over Server-Sent Events (SSE):

```bash
sate_ai serve --port 8080
```

### 10. Generate Custom Injector Scaffolding

Bootstrap boilerplate code for a new custom fault injector:

```bash
sate_ai create injector MyCustomInjector
```

---

## CI/CD Integration

Example GitHub Actions step in `.github/workflows/ai-test.yml`:

```yaml
name: On-Device AI Stress Test

on: [push, pull_request]

jobs:
  sate-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install SATE AI CLI
        run: dart pub global activate sate_cli

      - name: Pre-Flight Cost Estimation
        run: sate_ai --estimate --injectors memoryPressure,thermalThrottle --estimate-profile server

      - name: Run Fault Injection Stress Suite
        run: sate_ai --model assets/models/model.onnx --injectors memoryPressure,malformedInput --fail-on-regression
```

---

## License

MIT License. See [LICENSE](../../LICENSE) for details.

