# SATE AI DevTools Plugin

A Flutter DevTools extension plugin for the **SATE AI** stress testing framework.

## Features

- 🧪 **Run Stress Tests**: Trigger fault injection runs directly from Flutter DevTools.
- 📊 **Real-time Metrics**: View live test execution metrics (Total, Passed, Failed, Duration).
- 📦 **Baseline Management**: Save golden baselines and compare against past runs.
- 📝 **Live Log Console**: Color-coded execution logging for instant debugging.

## Installation

Add `sate_ai_devtools` to your `pubspec.yaml`:

```yaml
dev_dependencies:
  sate_ai_devtools:
    path: packages/sate_ai_devtools
```

## Usage

1. Run your Flutter application in debug mode (`flutter run`).
2. Open Flutter DevTools in your browser or editor.
3. Select the **SATE AI** tab.
4. Click **Run Stress Test** to execute tests and view real-time diagnostic reports.
