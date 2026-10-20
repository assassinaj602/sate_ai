# SATE AI Stress Test - GitHub Action

[![GitHub Marketplace](https://img.shields.io/badge/Marketplace-SATE%20AI%20Stress%20Test-blue.svg?logo=github&style=flat)](https://github.com/marketplace/actions/sate-ai-stress-test)
[![CI](https://github.com/assassinaj602/sate_ai/actions/workflows/test.yml/badge.svg)](https://github.com/assassinaj602/sate_ai/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Run systematic fault injection and chaos testing on your on-device AI models directly in your GitHub Actions CI/CD workflows. Prevent silent mobile app crashes, memory exhaustion, and latency blowups before releasing to production.

---

## 🚀 Why Use SATE AI in CI/CD?

On-device machine learning models (TensorFlow Lite, ONNX Runtime, llama.cpp) operate in constrained mobile environments. Unit tests verify standard inference on clean inputs, but miss real-world operational hostility:
- **Memory Pressure**: Sudden allocation spikes causing Low Memory Killer (LMK) process evictions.
- **Thermal Throttling**: CPU core frequency drops causing 4x+ latency degradation.
- **Corrupted Inputs**: NaNs, infinities, or sensor noise causing unhandled native segfaults.

This GitHub Action executes automated stress runs against your compiled model files on every commit or pull request, generating structured JSON and Markdown reports with actionable insights.

---

## 📦 Usage Examples

### 1. Basic Example (TensorFlow Lite Model)

```yaml
name: Model Stress Testing

on: [push, pull_request]

jobs:
  test-model:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Run SATE AI Stress Test
        uses: assassinaj602/sate_ai/.github/actions/sate-ai-test@main
        with:
          model-path: 'assets/models/mobilenet_v2.tflite'
          injectors: 'memoryPressure,malformedInput'
          output-format: 'markdown'
```

### 2. Multi-Fault Combinatorial Testing (ONNX / GGUF)

```yaml
      - name: Run Comprehensive Chaos Suite
        uses: assassinaj602/sate_ai/.github/actions/sate-ai-test@main
        with:
          model-path: 'assets/models/resnet18.onnx'
          injectors: 'memoryPressure,thermalThrottle,malformedInput,quantizationDrift'
          timeout: '45'
          output-format: 'json'
          fail-threshold: '0.95'
```

---

## ⚙️ Action Inputs

| Input | Description | Required | Default |
| :--- | :--- | :---: | :--- |
| `model-path` | Path to the AI model file (`.tflite`, `.onnx`, `.gguf`) | **Yes** | - |
| `injectors` | Comma-separated list of injectors (`memoryPressure`, `malformedInput`, `thermalThrottle`, `quantizationDrift`) | No | `memoryPressure,malformedInput` |
| `timeout` | Timeout in seconds for each test iteration | No | `30` |
| `output-format` | Format of output report (`json` or `markdown`) | No | `json` |
| `fail-threshold` | Minimum acceptable pass rate (0.0 to 1.0) before failing step | No | `0.0` |

---

## 📤 Action Outputs

| Output | Description |
| :--- | :--- |
| `report-path` | File path to the generated report artifact (`stress-report.json` or `stress-report.md`) |

---

## 🏷️ Marketplace Metadata

- **Category**: Testing
- **Tags**: `flutter`, `ai`, `testing`, `fault-injection`, `on-device`, `tflite`, `onnx`, `chaos-engineering`
- **Branding**: Icon `activity`, Color `indigo`

---

## 📄 License

This action is open source under the [MIT License](../../../LICENSE).
