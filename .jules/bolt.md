## 2024-10-25 - CLI Execution and CI Testing Note
**Learning:** Pure Dart CLI execution encounters Flutter framework compilation errors (`velocity_tracker`/`dart:ui` issues) when executed via `dart run` if they have dependencies containing Flutter code. The SATE AI CLI must exclude `dart:ui` dependents directly in `bin/sate_ai.dart`.
**Action:** For CLI execution and CI testing, always activate the package globally using `flutter pub global activate --source=path .` and run the `sate_ai` executable directly to prevent these compilation errors. Ensure that `bin/sate_ai.dart` only imports `sate_ai_cli.dart` and excludes adapters like `OnnxAdapter` and `TFLiteAdapter` that rely on Flutter UI libraries.

## 2026-09-02 - File System Sorting Performance
**Learning:** In Dart, calling synchronous I/O methods like `statSync()` inside a `sort()` comparator causes O(N log N) blocking disk accesses, leading to UI/app lockups.
**Action:** Always fetch file stats asynchronously in a loop and store them in a Map prior to sorting. Then sort the list based on the cached map values.
