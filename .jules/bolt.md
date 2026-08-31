## 2024-10-25 - CLI Execution and CI Testing Note
**Learning:** Pure Dart CLI execution encounters Flutter framework compilation errors (`velocity_tracker`/`dart:ui` issues) when executed via `dart run` if they have dependencies containing Flutter code. The SATE AI CLI must exclude `dart:ui` dependents directly in `bin/sate_ai.dart`.
**Action:** For CLI execution and CI testing, always activate the package globally using `flutter pub global activate --source=path .` and run the `sate_ai` executable directly to prevent these compilation errors. Ensure that `bin/sate_ai.dart` only imports `sate_ai_cli.dart` and excludes adapters like `OnnxAdapter` and `TFLiteAdapter` that rely on Flutter UI libraries.

## 2024-10-25 - File sorting synchronous I/O issue
**Learning:** In Dart, calling synchronous I/O methods like `statSync()` inside a `sort()` comparator causes repeated blocking disk accesses evaluated O(N log N) times, which can severely degrade performance.
**Action:** Always map files to cache their modification times asynchronously before sorting (O(N) operations), then extract the sorted keys.

## 2024-10-25 - Android minSdk Dependency Issue
**Learning:** When using ML dependencies like `fllama` in the example app, the Android `minSdk` must be set explicitly to a higher value (e.g., 23) in `build.gradle.kts`. Defaulting to `flutter.minSdkVersion` (which defaults to 21) causes an AndroidManifest merge conflict during the CI build process.
**Action:** Always ensure `minSdk` meets the minimum requirements of all ML dependencies included in the example app.
