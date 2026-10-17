# Contributing to SATE AI

Thanks for your interest in contributing. This guide covers how to set up the
project, run tests, and submit changes.

## Development Setup

### Requirements

- Flutter 3.24 or newer (for `sate_ai`)
- Dart 3.0 or newer (for `sate_core` and `sate_cli`)
- Melos (`dart pub global activate melos`)
- Git

### Clone and bootstrap

```bash
git clone https://github.com/assassinaj602/sate_ai.git
cd sate_ai
melos bootstrap
```

### Run everything locally

```bash
melos run ci           # format + analyze + test across all packages
```

### Run a single package

```bash
melos run test:core    # packages/sate_core
melos run test:cli     # packages/sate_cli
melos run test:ai      # packages/sate_ai
```

### Project layout

See the "Repository structure" table in the root README.

### Adding a new package

1. Create the package with `flutter create --template=package packages/my_package` or `dart create packages/my_package`
2. Add it to the `packages` list in `melos.yaml`
3. Run `melos bootstrap`

## Adding a Fault Injector

1. Create `packages/sate_core/lib/src/injectors/<name>_injector.dart`.
2. Implement `FaultInjector` (`type`, `name`, `description`, `inject`, `reset`).
3. Add the new value to `FaultType` in `packages/sate_core/lib/src/core/fault_type.dart`.
4. Export it from `packages/sate_core/lib/sate_core.dart` (re-exported via `packages/sate_ai/lib/sate_ai.dart`).
5. Write unit tests in `packages/sate_core/test/injectors/<name>_injector_test.dart`.
6. Update `CHANGELOG.md` and README.

You can also generate the scaffolding using the CLI:

```bash
sate_ai create injector MyCustomInjector
```

## Adding a Model Adapter

1. If the adapter is pure Dart / framework-agnostic, place it in `packages/sate_core/lib/src/adapter/<name>_adapter.dart`. If it requires Flutter or platform channels, place it in `packages/sate_ai/lib/src/adapters/<name>_adapter.dart`.
2. Implement `AIModelAdapter` (all getters and methods, including `simulateGPUMemoryPressure` and `currentGPUMemoryMB`).
3. Export it from `packages/sate_core/lib/sate_core.dart` or `packages/sate_ai/lib/sate_ai.dart`.
4. Write unit tests in the corresponding package's `test/adapters/<name>_adapter_test.dart`.
5. Update `CHANGELOG.md` and README.

## Adding a New Language SDK

SATE AI is a multi-language framework. If you are interested in adding an SDK for a new runtime (such as Swift, Python, Rust, Go, or C++), follow this architectural specification.

### 1. Architectural Pattern

Every SATE AI language SDK must implement four fundamental components:

1. **`ModelAdapter`**: An interface or abstract class defining the contract for interacting with AI runtimes. It must expose:
   - Model identifier and state (`modelId`, `currentMemoryMB`, `isDegraded`).
   - Inference execution (`runInference(input)`).
   - Fault simulation hooks (`simulateMemoryPressure(mb)`, `reset()`, `isHealthy()`).

2. **`FaultInjector`**: An interface representing a repeatable fault injection strategy. It must expose:
   - Fault metadata (`type`, `name`, `description`).
   - Injection hooks (`inject()`, `reset()`).

3. **`StressRunner`**: The test orchestration engine that takes a model adapter and a list of injectors, executes each injector with timeout isolation and probe inferences, and aggregates results.

4. **`StressReport`**: The structured evaluation report capturing individual test results, pass/fail status, duration metrics, and serializing to both standard JSON and Markdown formats.

### 2. Built-in Fault Injectors

Where possible, new SDKs should implement the standard 11 fault injectors:
- `MemoryPressureInjector`
- `MalformedInputInjector`
- `QuantizationDriftInjector`
- `ThermalThrottleInjector`
- `LatencyInjector`
- `ModelSwapInjector`
- `ConfidenceThresholdInjector`
- `GpuMemoryPressureInjector`
- `DataCorruptionInjector`
- `ModelVersionMismatchInjector`
- `NetworkLatencyDropInjector`

### 3. Packaging & Monorepo Conventions

- Place the new SDK in `packages/sate_<language>/` (e.g., `packages/sate_ios/` for Swift).
- Include comprehensive unit tests verifying the runner, report, mock adapter, and all injectors.
- Include at least one native runtime adapter for the target platform (e.g., Core ML for iOS, PyTorch/ONNX for Python).
- Include a package-level `README.md` with installation and quick-start instructions.
- Add an automated testing job to `.github/workflows/test.yml`.

### 4. Reference Implementations

Refer to the existing SDKs in this monorepo as reference designs:
- **Dart (Core & CLI)**: [`packages/sate_core`](packages/sate_core) and [`packages/sate_cli`](packages/sate_cli)
- **Kotlin / Android**: [`packages/sate_android`](packages/sate_android) (Issue #121)
- **TypeScript / Web**: [`packages/sate_web`](packages/sate_web) (Issue #122)

---

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

- `feat:`: new feature
- `fix:`: bug fix
- `docs:`: documentation
- `test:`: tests
- `chore:`: tooling, refactors
- `style:`: formatting

## Pull Request Process

1. Fork the repo and create a feature branch.
2. Commit often with descriptive messages.
3. Push and open a pull request against `main`.
4. The CI will run format, analyze, and tests.
5. Address review comments.
6. Do not merge your own PR: the maintainer will merge.

## Reporting Issues

Please use the issue templates. Include:

- What you expected to happen
- What actually happened
- Steps to reproduce
- Flutter, Dart, and SATE AI versions

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
