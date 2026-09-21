## 2024-10-25 - CLI Execution and CI Testing Note
**Learning:** Pure Dart CLI execution encounters Flutter framework compilation errors (`velocity_tracker`/`dart:ui` issues) when executed via `dart run` if they have dependencies containing Flutter code. The SATE AI CLI must exclude `dart:ui` dependents directly in `bin/sate_ai.dart`.
**Action:** For CLI execution and CI testing, always activate the package globally using `flutter pub global activate --source=path .` and run the `sate_ai` executable directly to prevent these compilation errors. Ensure that `bin/sate_ai.dart` only imports `sate_ai_cli.dart` and excludes adapters like `OnnxAdapter` and `TFLiteAdapter` that rely on Flutter UI libraries.

## 2024-10-25 - File sorting synchronous I/O issue
**Learning:** In Dart, calling synchronous I/O methods like `statSync()` inside a `sort()` comparator causes repeated blocking disk accesses evaluated O(N log N) times, which can severely degrade performance.
**Action:** Always map files to cache their modification times asynchronously before sorting (O(N) operations), then extract the sorted keys.

## 2024-10-25 - Android minSdk Dependency Issue
**Learning:** When using ML dependencies like `fllama` in the example app, the Android `minSdk` must be set explicitly to a higher value (e.g., 23) in `build.gradle.kts`. Defaulting to `flutter.minSdkVersion` (which defaults to 21) causes an AndroidManifest merge conflict during the CI build process.
**Action:** Always ensure `minSdk` meets the minimum requirements of all ML dependencies included in the example app.

## 2026-09-02 - List Sorting Memoization in Data Classes
**Learning:** When calculating multiple percentiles (p50, p90, p99) from lists of metrics in Dart, naively running `List<double>.from(array)..sort()` per calculation invokes the O(N log N) sorting algorithm multiple times.
**Action:** Use `late final` variables in Dart data transfer/report objects to cache sorted arrays lazily. This ensures sorting happens only once, turning subsequent percentile extractions into fast O(1) array accesses, without needing to pre-calculate values if they are never accessed.

## 2024-10-25 - Verification Task Status Update
**Learning:** During the comprehensive verification task, no missing performance optimization was identified within the acceptable rules set (i.e. micro-optimizations that impact readability). We resolved Android CMake dependencies and verified all 162 tests passed, lint checks are clean once `flutter pub get` is run on all nested packages. The CLI and Web dashboard also verify correctly.
**Action:** A plan and final execution step completed as required for verification when no performance tasks were valid to execute based on limits.
