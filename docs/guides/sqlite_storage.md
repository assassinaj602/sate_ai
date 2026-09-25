# SQLite Storage & History Tracking Guide

SATE AI provides local SQLite database storage for historical stress test reports powered by `sqflite_common_ffi`. This enables continuous performance tracking, historical trend analysis, regression detection, and local report querying across both Flutter and CLI environments.

## Architecture

The database module operates via `ReportDatabase`, using pure-Dart native SQLite bindings (`sqlite3` native library).

- **Database File:** Saved by default at `~/.sate_ai/reports.db` (configurable via environment variables or initialization parameters).
- **Cross-Platform Compatibility:** Runs on Linux, macOS, Windows, iOS, Android, and CLI environments without Flutter engine dependencies.

## Initializing the Database

In CLI scripts or custom Dart applications, initialize FFI before performing database operations:

```dart
import 'package:sate_ai/sate_ai.dart';

void main() async {
  // Initialize SQLite FFI bindings
  ReportDatabase.initializeFfi();

  final db = ReportDatabase(
    path: './custom_db_path/reports.db',
  );

  await db.open();
}
```

## Storing Stress Test Reports

Save test results automatically after execution:

```dart
final runner = StressTestRunner(config: config);
final report = await runner.run();

final db = ReportDatabase();
await db.open();

final reportId = await db.insertReport(report);
print('Saved report to SQLite DB with ID: $reportId');
```

## Querying Historical Reports

### 1. Get Latest Report

```dart
final latestReport = await db.getLatestReport(modelName: 'llama3:8b');
print('Latest Pass Rate: ${latestReport?.passRate}%');
```

### 2. List Reports with Pagination and Filtering

```dart
final history = await db.queryReports(
  modelName: 'llama3:8b',
  limit: 20,
  offset: 0,
  sortBy: 'timestamp',
  descending: true,
);

for (final record in history) {
  print('${record.timestamp} - Pass Rate: ${record.passRate}% - P95: ${record.p95LatencyMs}ms');
}
```

### 3. Fetching Performance Metrics Over Time

```dart
final trendData = await db.getMetricTrend(
  modelName: 'llama3:8b',
  metric: 'avgLatencyMs',
  startDate: DateTime.now().subtract(const Duration(days: 30)),
);
```

## CLI Storage Commands

### Enabling Automatic Storage on Run

Save test runs automatically to the local database:

```bash
sate_ai run --model llama3:8b --db --db-path ./my_reports.db
```

### Listing Historical Runs

```bash
sate_ai db list --model llama3:8b --limit 10
```

### Exporting Reports from Database

```bash
sate_ai db export --id 42 --output historical_report.html
```

### Database Maintenance & Pruning

Prune records older than 90 days:

```bash
sate_ai db prune --days 90
```
