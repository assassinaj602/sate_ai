# Cron & Scheduled Stress Testing Guide

Continuous AI red-teaming requires periodic execution of stress testing suites to ensure model safety post-deployment. SATE AI includes built-in cron scheduling via `StressTestScheduler`.

## Overview

The scheduler allows SATE AI to:
- Run stress test suites on cron schedules (e.g. hourly, daily at midnight, or weekly).
- Automatically persist results to SQLite history.
- Generate and update SVG status badges after every scheduled run.
- Trigger webhooks or notifications on test failures.

## Running Scheduler via CLI

Launch SATE AI in continuous daemon mode with a cron expression:

```bash
sate_ai schedule \
  --cron "0 0 * * *" \
  --model llama3:8b \
  --db \
  --badge-output ./badges/status.svg
```

### Common Cron Expressions

- `*/15 * * * *` — Every 15 minutes
- `0 * * * *` — Top of every hour
- `0 0 * * *` — Every day at midnight
- `0 8 * * 1` — Every Monday at 8:00 AM

## Configuration File Scheduling

Define scheduled jobs in `scheduler.yaml`:

```yaml
version: 1.0
jobs:
  - name: "Hourly Quick Health Check"
    cron: "0 * * * *"
    model: "llama3:8b"
    injectors: ["prompt_injection"]
    db_store: true

  - name: "Daily Deep Red-Teaming"
    cron: "0 2 * * *"
    model: "llama3:8b"
    injectors: ["all"]
    db_store: true
    webhook_url: "https://hooks.slack.com/services/XXX/YYY/ZZZ"
```

Start the background worker using the config file:

```bash
sate_ai schedule --config scheduler.yaml
```

## Programmatic Scheduler API

```dart
import 'package:sate_ai/sate_ai.dart';

void main() async {
  final scheduler = StressTestScheduler();

  scheduler.scheduleJob(
    cronExpression: '0 0 * * *',
    config: StressTestConfig(
      modelName: 'llama3:8b',
      injectors: [PromptInjectionInjector(), JailbreakInjector()],
    ),
    onComplete: (report) async {
      print('Scheduled test finished. Pass rate: ${report.passRate}%');
      
      final db = ReportDatabase();
      await db.open();
      await db.insertReport(report);
    },
    onError: (error) {
      print('Scheduled test failed with error: $error');
    },
  );

  scheduler.start();
  print('SATE AI Scheduler active. Press Ctrl+C to terminate.');
}
```
