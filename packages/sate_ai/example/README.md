# SATE AI Example

A minimal Flutter app that demonstrates SATE AI's stress testing framework
on a variety of on-device AI models.

## Running the example

```bash
cd example
flutter pub get
flutter run
```

The app runs on Android, iOS, web, macOS, Linux, and Windows.

## What it demonstrates

- Swapping between MockAdapter, OnnxAdapter, and TFLiteAdapter
- Selecting different fault injectors
- Viewing the resulting StressReport
- Copying the report to JSON or Markdown

## Adding real models

Place your model files in `assets/models/` and reference them in
`pubspec.yaml` under `flutter.assets`.
