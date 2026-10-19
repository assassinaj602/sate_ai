# Changelog

## 0.1.0

### Initial Release of SATE Core
- Standalone pure Dart fault injection and chaos testing framework for AI models.
- Zero Flutter SDK dependencies for headless CI/CD, server, and CLI execution.
- 12 built-in fault injectors:
  - Memory Pressure Injector
  - Thermal Throttle Injector
  - Malformed Input Injector
  - Latency Injector
  - Quantization Drift Injector
  - Model Version Mismatch Injector
  - Data Corruption Injector
  - Network Latency Drop Injector
  - GPU Memory Pressure Injector
  - Model Swap Injector
  - Confidence Threshold Injector
  - Adaptive Chaos Injector (closed-loop telemetry scaling)
- Resource telemetry monitoring:
  - CPU usage, RAM headroom, thermal state, battery level
- Pre-flight test cost estimation:
  - Wall-clock duration, peak RAM, battery drain, inference cycles, and cloud API cost
- Model binary analyzers:
  - ONNX Protobuf and TFLite FlatBuffer structural quantization analysis
- Multi-language localized stress reporting:
  - English, Spanish, French, German, Portuguese
- Baseline comparisons, retry / flaky detection, SQLite persistence, and webhook notifications.
