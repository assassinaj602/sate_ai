# Changelog

## 0.1.0

### Initial Release of SATE CLI
- Standalone CLI executable `sate_ai` installed via `dart pub global activate sate_cli`.
- Pure Dart CLI runner with no Flutter SDK dependency required.
- Commands and flags supported:
  - `--model`: Target model path (`.tflite`, `.onnx`, `.gguf`)
  - `--injectors`: Comma-separated active fault injectors
  - `--adaptive-chaos`: Closed-loop adaptive chaos injection scaling with device telemetry
  - `--estimate`: Pre-flight stress test cost and resource estimation
  - `--estimate-profile`: Hardware profile (`mobile`, `edge`, `tablet`)
  - `--estimate-cloud`: Hybrid cloud API token cost estimation
  - `--health-check`: Rapid single-pass model health verification
  - `--benchmark`: Latency profiling without fault injection (p50, p90, p99)
  - `--analyze-quantization`: Structural binary model quantization analysis
  - `--models`, `--auto-detect`, `--parallel`: Batch model testing
  - `--compare-reports`, `--diff-output`: Report diffing with HTML/Markdown output
  - `--schedule`: Automated cron testing
  - `--db`, `--db-history`: SQLite historical test runs
  - `--badge`, `--badge-type`: SVG badge generation
  - `--webhook-url`: Webhook reporting to Slack, Discord, and Microsoft Teams
  - `--language`: Multi-language report generation (`en`, `es`, `fr`, `de`, `pt`)
