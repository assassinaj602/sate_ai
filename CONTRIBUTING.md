# Contributing to SATE AI

Thanks for your interest in contributing. This guide covers how to set up the
project, run tests, and submit changes.

## Development Setup

### Requirements

- Flutter 3.10 or newer
- Dart 3.0 or newer
- Linux, macOS, or Windows
- Git

### Clone and bootstrap

```bash
git clone https://github.com/assassinaj602/sate_ai.git
cd sate_ai
flutter pub get
flutter test
```

## Running the Full Verification Suite

```bash
dart format --set-exit-if-changed lib/ test/ bin/
flutter analyze --fatal-infos
flutter test
```

All three commands must pass before opening a pull request.

## Project Layout

```
lib/src/
  core/          Core abstractions (FaultInjector, StressRunner, Report, ...)
  adapters/      Model adapters (Mock, ONNX, TFLite, Fllama, MediaPipe, ...)
  injectors/     Fault injectors
  cli/           CLI helpers
test/            Unit tests mirroring lib/ structure
example/         Flutter demo app
bin/             CLI entry point
web/             Static web dashboard for HTML reports
docs/            GitHub Pages site
```

## Adding a Fault Injector

1. Create `lib/src/injectors/<name>_injector.dart`.
2. Implement `FaultInjector` (`type`, `name`, `description`, `inject`, `reset`).
3. Add the new value to `FaultType` in `lib/src/core/fault_type.dart`.
4. Export it from `lib/sate_ai.dart`.
5. Write unit tests in `test/injectors/<name>_injector_test.dart`.
6. Update `CHANGELOG.md` and README.

You can also generate the scaffolding:

```bash
sate_ai create injector MyCustomInjector
```

## Adding a Model Adapter

1. Create `lib/src/adapters/<name>_adapter.dart`.
2. Implement `AIModelAdapter` (all getters and methods, including
   `simulateGPUMemoryPressure` and `currentGPUMemoryMB`).
3. Export it from `lib/sate_ai.dart`.
4. Write unit tests in `test/adapters/<name>_adapter_test.dart`.
5. Update `CHANGELOG.md` and README.

## Testing Guidelines

- Every public class and method must have tests.
- Prefer small, focused tests over large integration ones.
- Use `MockAdapter` to test adapters and injectors.
- Run `flutter test` frequently during development.

## Code Style

- Follow `very_good_analysis`.
- Run `dart format` before committing.
- No `print` calls in library code (use stderr or a logger).
- Public API must have dartdoc comments.

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation
- `test:` — tests
- `chore:` — tooling, refactors
- `style:` — formatting

## Pull Request Process

1. Fork the repo and create a feature branch.
2. Commit often with descriptive messages.
3. Push and open a pull request against `main`.
4. The CI will run format, analyze, and tests.
5. Address review comments.
6. Do not merge your own PR — the maintainer will merge.

## Reporting Issues

Please use the issue templates. Include:

- What you expected to happen
- What actually happened
- Steps to reproduce
- Flutter, Dart, and SATE AI versions

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
