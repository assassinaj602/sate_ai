# Changelog

All notable changes to SATE AI are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.11.0] - 2026-09-26

### Added
- CLI code generation for custom injectors (`sate_ai create injector <name>`)
- Stress test scheduling via cron expressions
- Golden baseline comparisons with tolerance thresholds
- Batch mode for running stress tests on multiple models
- Auto-detect model type from file extension in batch mode
- Report comparison and diff view with HTML output
- Performance benchmarking mode (p50, p90, p99 percentiles)
- Stress test retry and flaky test detection
- HTML report export with Chart.js charts
- Real-time SSE monitoring dashboard
- MediaPipe adapter for on-device vision tasks
- Core ML adapter for iOS (with simulation mode)
- Google ML Kit adapter
- CI/CD SVG status badges generator
- Custom report templates in JSON and YAML
- SQLite storage for historical report tracking
- Model health check API (`SateAI.healthCheck`)
- VS Code extension for editor integration
- Comprehensive documentation rewrite (README, CONTRIBUTING)
- Website redesign with feature guides
- 8 in-depth feature guides in `docs/guides/`

### Changed
- `README.md` rewritten to reflect all new features
- `CONTRIBUTING.md` rewritten with current tooling and workflows
- `pubspec.yaml` description and topics updated
- `example/README.md` refreshed
- `docs/paper.html` updated with current status
- `.github/ISSUE_TEMPLATE/*` verified and updated
- Adapters table expanded to 7 adapters
- Fault injectors table expanded to 11 injectors

### Fixed
- Various CI fixes for Android SDK setup and NDK installation
- Manifest merger conflicts between example app and `fllama` plugin

## [0.10.0] - 2026-09-01

### Added
- Real-time monitoring dashboard (Issue #33)
- HTML report export with Chart.js (Issue #32)
- MediaPipe adapter (Issue #29)
- Core ML adapter (Issue #30)
- Google ML Kit adapter (Issue #31)

## [0.9.0] - 2026-08-21

### Added
- TensorFlow Lite adapter (Issue #4)
- Confidence threshold injector (Issue #6)
- Data corruption injector (Issue #26)
- Model version mismatch injector (Issue #27)
- Network latency/drop injector (Issue #25)

## [0.8.0] - 2026-08-12

### Added
- Fllama (llama.cpp) adapter (Issue #28)

## [0.7.0] - 2026-08-05

### Added
- Latency injector
- Model swap injector
- Interactive demo on website

## [0.6.0] - 2026-07-30

### Added
- Thermal throttle injector (Issue #5)

## [0.5.0] - 2026-07-29

### Added
- CLI executable `sate_ai`
- GitHub composite action

## [0.4.0] - 2026-07-28

### Added
- Quantization drift injector (Issue #2)

## [0.3.0] - 2026-07-28

### Added
- Web dashboard with dark mode and exports

## [0.2.0] - 2026-07-28

### Added
- ONNX Runtime adapter (Issue #1)

## [0.1.0] - 2026-07-28

### Added
- Initial release: core framework, MockAdapter, MemoryPressureInjector, MalformedInputInjector
- 59 unit tests

[Unreleased]: https://github.com/assassinaj602/sate_ai/compare/v0.11.0...HEAD
[0.11.0]: https://github.com/assassinaj602/sate_ai/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/assassinaj602/sate_ai/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/assassinaj602/sate_ai/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/assassinaj602/sate_ai/compare/v0.7.1...v0.8.0
[0.7.1]: https://github.com/assassinaj602/sate_ai/compare/v0.7.0...v0.7.1
[0.7.0]: https://github.com/assassinaj602/sate_ai/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/assassinaj602/sate_ai/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/assassinaj602/sate_ai/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/assassinaj602/sate_ai/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/assassinaj602/sate_ai/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/assassinaj602/sate_ai/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/assassinaj602/sate_ai/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/assassinaj602/sate_ai/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/assassinaj602/sate_ai/releases/tag/v0.1.0
