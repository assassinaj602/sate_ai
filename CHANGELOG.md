# Changelog

All notable changes to SATE AI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
- Zero production dependencies (Flutter SDK only)
- Zero `flutter analyze` issues
- `dart format` compliant

[Unreleased]: https://github.com/assassinaj602/sate_ai/compare/v0.4.0...HEAD
[0.4.0]: https://github.com/assassinaj602/sate_ai/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/assassinaj602/sate_ai/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/assassinaj602/sate_ai/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/assassinaj602/sate_ai/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/assassinaj602/sate_ai/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/assassinaj602/sate_ai/releases/tag/v0.1.0
