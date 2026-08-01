# Contributing to SATE AI

Thank you for your interest in contributing! SATE AI is a community-driven project and every contribution counts — whether it's a bug fix, a new fault injector, documentation improvements, or just filing a good issue.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Ways to Contribute](#ways-to-contribute)
- [Good First Issues](#good-first-issues)
- [Development Setup](#development-setup)
- [Running Tests](#running-tests)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Code Style](#code-style)
- [Adding a New Injector](#adding-a-new-injector)
- [Adding a New Adapter](#adding-a-new-adapter)

---

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

---

## Ways to Contribute

| Type | How |
|------|-----|
| 🐛 Bug | Open a [bug report](.github/ISSUE_TEMPLATE/bug_report.md) |
| 💡 Feature | Open a [feature request](.github/ISSUE_TEMPLATE/feature_request.md) |
| 🔌 Injector | Open a [custom injector proposal](.github/ISSUE_TEMPLATE/custom_injector.md) |
| 📚 Docs | Edit any `.md` file or API docs inline |
| ✅ Tests | Add tests to `test/` for uncovered paths |
| 🔧 Fix | Pick up any issue labelled `good first issue` |

---

## Good First Issues

Look for issues labelled [`good first issue`](https://github.com/assassinaj602/sate_ai/issues?q=label%3A%22good+first+issue%22) — they are scoped to be completable in a few hours and include detailed guidance.

Examples of good first issues:
- Add `toMarkdown()` for a new `FaultResult` field
- Improve error messages in `StressRunner`
- Add a test for edge cases in `MalformedInputInjector`
- Write a guide in `docs/`

---

## Development Setup

### Prerequisites

- Flutter ≥ 3.10.0
- Dart ≥ 3.0.0
- Git

### Clone and install

```bash
git clone https://github.com/assassinaj602/sate_ai.git
cd sate_ai
flutter pub get
```

### Verify setup

```bash
flutter test
flutter analyze
```

Both should pass with zero errors.

---

## Running Tests

```bash
# All tests
flutter test

# Specific file
flutter test test/core/stress_runner_test.dart

# With coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Tests must pass before opening a PR.** The CI will run `flutter test`, `flutter analyze`, and `dart format` automatically.

---

## Submitting a Pull Request

1. **Fork** the repository
2. **Branch** off `main`: `git checkout -b feat/your-feature`
3. **Write tests first** (TDD preferred)
4. **Implement** your change
5. **Run** `flutter test && flutter analyze`
6. **Format**: `dart format lib/ test/`
7. **Commit** with a clear message: `feat: add ThermalThrottleInjector`
8. **Push** and open a PR against `main`

### Commit message format

```
<type>: <short description>

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `chore`

---

## Code Style

- Follow the `analysis_options.yaml` rules (enforced by CI)
- All public APIs must have doc comments (`///`)
- Use `const` constructors where possible
- Prefer `final` for local variables
- No `print()` statements in library code

---

## Adding a New Injector

1. Create `lib/src/injectors/your_injector.dart`
2. Implement `FaultInjector`
3. Export from `lib/sate_ai.dart`
4. Add tests in `test/injectors/your_injector_test.dart` (min 6 tests)
5. Document in README roadmap and CHANGELOG

Template:

```dart
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Your injector description.
class YourInjector implements FaultInjector {
  @override
  FaultType get type => FaultType.latency; // choose appropriate type

  @override
  String get name => 'Your Injector Name';

  @override
  String get description => 'What this injector does';

  @override
  Future<void> inject() async {
    // Inject the fault
  }

  @override
  Future<void> reset() async {
    // Restore normal state
  }
}
```

---

## Adding a New Adapter

1. Create `lib/src/adapters/your_adapter.dart`
2. Implement `AIModelAdapter`
3. Export from `lib/sate_ai.dart`
4. Add tests in `test/adapters/your_adapter_test.dart` (min 6 tests)

---

## Questions?

Open a [GitHub Discussion](https://github.com/assassinaj602/sate_ai/discussions) — we respond quickly!
