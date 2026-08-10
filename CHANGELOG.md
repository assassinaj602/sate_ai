# Changelog

All notable changes to SATE AI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.0] - 2026-08-07

### Added
- GPU Memory Pressure Injector (`GpuMemoryPressureInjector`) (Issue #23)
  - Simulates GPU memory pressure with configurable limit (`limitMb`)
  - Extended `AIModelAdapter` interface with `simulateGPUMemoryPressure(int mb)` and `currentGPUMemoryMB`
  - Added `FaultType.gpuMemoryPressure` enum value, display name, and icon
  - Added 8 unit tests (now 172 total)
- Enhanced `ThermalThrottleInjector` with battery drain simulation (Issue #24)
  - Simulates battery percentage drop on each injection
  - Triggers throttling when battery drops below configurable threshold
  - Adds extra memory pressure when battery is low
  - Configurable `batteryThreshold` and `batteryDropStep`
  - 8 new unit tests (now 180 total)
- Network Latency / Drop Injector (`NetworkLatencyDropInjector`) (Issue #25)
  - Simulates network latency, timeouts, and disconnections
  - Configurable failure type, latency, and timeout
  - 13 new unit tests (now 193 total)
  - Works with any adapter (adapter can check network state)
- Data Corruption Injector (`DataCorruptionInjector`) (Issue #26)
  - Simulates corrupted input data (image noise, blur, occlusion, salt & pepper, audio glitch)
  - Configurable corruption type and intensity
  - 16 new unit tests (now 209 total)
  - Utility method `corruptData()` for testing data corruption effects

### Changed
- Breaking: `AIModelAdapter` now requires implementing `simulateGPUMemoryPressure` and `currentGPUMemoryMB`

## [0.7.1] - 2026-08-02

### Fixed
- Updated `tflite_flutter` constraint to `^0.12.0` (recovers 10 pub points → 160/160 score)
- Fixed CI workflow status badge URL in `README.md`
- Fixed `OnnxAdapter` null-safety call for `runAsync` timeout
- All dependencies now up-to-date with latest stable releases

### Added
- Prominent Research Paper section and links in `README.md`
- Live demo animations (`pass.gif`, `fail.gif`) and physical app preview (`demo.png`)
- New package topics (`research`, `flutter`, `machine-learning`)

## [0.7.0] - 2026-07-30

### Added
- Confidence Threshold Validator injector (Issue #6)
  - Validates that model confidence stays above a threshold
  - Configurable threshold (default 0.5)
  - Marks test as failed when confidence drops below
  - 10 new unit/integration tests (now 164 total)

## [0.6.0] - 2026-07-30

### Added
- TensorFlow Lite Adapter (`TFLiteAdapter`) wrapping `tflite_flutter` (Issue #4)
  - Supports `fromAsset` and `fromFile` factory constructors
  - Memory pressure simulation and degradation tracking
  - 8 new unit tests (now 153 total)

### Changed
- Documentation updated with TensorFlow Lite details
- Injector/Adapter tables in README updated

## [0.5.0] - 2026-07-30

### Added
- CLI command `sate_ai` for running stress tests from the terminal
- GitHub Action for CI/CD integration (`.github/actions/sate-ai-test`)
- Example workflow showing how to use the action
- New documentation for CLI and GitHub Action

## [0.4.0] - 2026-07-30

### Added
- Latency Injector for simulating increasing inference latency (Issue #8)
  - Configurable baseDelayMs, incrementMs, maxLatencyMs
  - Tracks latency history for debugging
  - Applies memory pressure proportional to latency
- Model Swap Injector for simulating model corruption (Issue #9)
  - Configurable initialQuality, qualityDegradation, qualityThreshold
  - Tracks quality history for debugging
  - Applies memory pressure based on quality loss
- 20 new unit tests (now 140+ total)

### Changed
- Documentation updated with new injectors
- Injector table in README updated

## [0.3.0] - 2026-07-30

### Added
- Thermal Throttle Injector for simulating CPU throttling (Issue #5)
  - Configurable temperatureStep and maxTemperature
  - Tracks temperature history for debugging
  - Applies memory pressure proportional to temperature
  - 25 new unit tests for comprehensive coverage
  - Full integration with StressRunner

### Changed
- Documentation updated with ThermalThrottleInjector details
- Injector table in README updated

## [0.2.0] - 2026-07-30

### Added
- Quantization Drift Injector for simulating gradual precision loss (Issue #2)
  - Configurable driftFactor and degradationThreshold
  - Tracks confidence history for debugging
  - Applies memory pressure proportional to drift
  - 20 new unit tests for comprehensive coverage
  - Full integration with StressRunner

### Changed
- Documentation updated with QuantizationDriftInjector details
- Injector table in README updated

## [0.1.2] - 2026-07-29

### Added
- Web dashboard for visualizing stress test reports (Issue #7)
  - Drag-and-drop JSON upload
  - Dark/light mode toggle with localStorage persistence
  - Chart.js integration for inference time and memory usage charts
  - Export reports to JSON, Markdown, and CSV
  - Mobile responsive design
- MemoryUsageMB field to FaultResult for memory tracking

## [0.1.1] - 2026-07-29

### Added

- `OnnxAdapter` — [AIModelAdapter] implementation backed by the ONNX Runtime
  (`onnxruntime ^1.4.1`). Supports text and binary inputs, memory pressure
  simulation, degradation tracking, and safe reset. (Closes #1)
- Injectable `OrtSessionFactory` parameter on `OnnxAdapter` for unit testing
  without a real `.onnx` model file.
- 11 new unit tests for `OnnxAdapter` (70 total across the library).

### Changed

- `pubspec.yaml` version bumped to `0.1.1`.

## [0.1.0] - 2026-07-28

Initial release of SATE AI.

### Added

- `FaultInjector` abstract interface for implementing fault injection strategies
- `StressRunner` orchestration engine with configurable timeout support
- `StressReport` with JSON (`toJsonString`) and Markdown (`toMarkdown`) serialization
- `FaultResult` value object capturing per-injector pass/fail outcomes and timing
- `AIModelAdapter` abstract interface for wrapping on-device AI runtimes
- `AIInput` and `AIOutput` typed value objects for inference I/O
- `MockAdapter` for testing without a real AI model; supports memory simulation and forced failures
- `MemoryPressureInjector` — simulates out-of-memory conditions up to a configurable limit in MB
- `MalformedInputInjector` — injects empty strings, oversized payloads (1 MB), and binary garbage inputs
- `FaultType` enum with values: `memoryPressure`, `malformedInput`, `quantizationDrift`, `thermalThrottle`, `latency`, `modelSwap`
- `SateAI.stress()` convenience API for single-call test execution
- 59 unit tests with full coverage of all core modules and injectors
- Flutter demo application in `example/` demonstrating all features with a dark-theme UI
- GitHub Actions CI/CD workflow for automated testing and lint on every pull request
- GitHub Actions workflow for automated pub.dev publishing on version tag push
- Issue templates for bug reports, feature requests, and custom injector proposals
- `CONTRIBUTING.md` with development setup, code style, and pull request guidelines
- `CODE_OF_CONDUCT.md` following the Contributor Covenant standard

### Technical Details

- Dart SDK constraint: `>=3.0.0 <4.0.0`
- Flutter constraint: `>=3.10.0`
- Minimal dependencies (Flutter SDK + test tooling)
- Zero `flutter analyze` issues
- `dart format` compliant

[Unreleased]: https://github.com/assassinaj602/sate_ai/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/assassinaj602/sate_ai/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/assassinaj602/sate_ai/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/assassinaj602/sate_ai/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/assassinaj602/sate_ai/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/assassinaj602/sate_ai/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/assassinaj602/sate_ai/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/assassinaj602/sate_ai/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/assassinaj602/sate_ai/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/assassinaj602/sate_ai/releases/tag/v0.1.0
