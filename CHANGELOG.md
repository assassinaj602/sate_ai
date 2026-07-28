# Changelog

All notable changes to SATE AI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-07-28

### Added
- Core `FaultInjector` abstract interface
- `StressRunner` orchestration engine with timeout support
- `StressReport` with JSON and Markdown serialization
- `AIModelAdapter` abstract interface for wrapping AI models
- `MockAdapter` for testing without a real model
- `MemoryPressureInjector` — simulates OOM and memory pressure
- `MalformedInputInjector` — injects empty, oversized, and binary-garbage inputs
- `SateAI.stress()` convenience API
- 35 unit tests with full coverage
- Flutter demo app in `example/`
- GitHub Actions CI/CD (test, lint, publish)
- Issue templates (bug, feature, custom injector)

[Unreleased]: https://github.com/YOUR_USERNAME/sate_ai/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/YOUR_USERNAME/sate_ai/releases/tag/v0.1.0
