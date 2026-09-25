import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'report.dart';

/// SQLite-backed storage for historical stress test reports.
///
/// Uses `sqflite_common_ffi` so it works in pure Dart (CLI) and Flutter.
///
/// Example:
/// ```dart
/// final db = ReportDatabase('sate_ai.db');
/// await db.open();
/// await db.insertReport(report);
/// final recent = await db.queryRecent(limit: 10);
/// await db.close();
/// ```
class ReportDatabase {
  /// Path to the SQLite database file.
  final String databasePath;

  Database? _db;
  bool _initialized = false;

  ReportDatabase(this.databasePath);

  /// Opens the database and creates the schema if needed.
  Future<void> open() async {
    if (_db != null) return;

    // Set up the FFI factory once per process.
    if (!_initialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _initialized = true;
    }

    // Ensure parent directory exists.
    final dir = Directory(p.dirname(databasePath));
    if (dir.path.isNotEmpty && !dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    _db = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  /// Closes the database connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// True if the database has been opened.
  bool get isOpen => _db != null;

  // ─────────────────────────────────────────────────────────────────────
  // Schema
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        model_id TEXT NOT NULL,
        passed INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        total_duration_ms INTEGER NOT NULL,
        total_tests INTEGER NOT NULL,
        passed_count INTEGER NOT NULL,
        failed_count INTEGER NOT NULL,
        failure_count INTEGER NOT NULL,
        payload TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_reports_model ON reports(model_id)',
    );
    await db.execute(
      'CREATE INDEX idx_reports_start_time ON reports(start_time)',
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // CRUD
  // ─────────────────────────────────────────────────────────────────────

  /// Inserts a [StressReport] into the database.
  ///
  /// Returns the new row ID.
  Future<int> insertReport(StressReport report) async {
    final db = _requireDb();

    final passedCount = report.results.where((r) => r.passed).length;
    final failedCount = report.results.length - passedCount;

    return db.insert('reports', {
      'model_id': report.modelId,
      'passed': report.passed ? 1 : 0,
      'start_time': report.startTime.toIso8601String(),
      'end_time': report.endTime.toIso8601String(),
      'total_duration_ms': report.totalDuration.inMilliseconds,
      'total_tests': report.results.length,
      'passed_count': passedCount,
      'failed_count': failedCount,
      'failure_count': report.failures.length,
      'payload': report.toJsonString(),
    });
  }

  /// Returns the most recent reports, optionally limited.
  Future<List<StressReport>> queryRecent({int limit = 10}) async {
    final db = _requireDb();
    final rows = await db.query(
      'reports',
      orderBy: 'start_time DESC',
      limit: limit,
    );
    return rows.map(_rowToReport).toList();
  }

  /// Returns all reports for a given model, ordered by start time (newest first).
  Future<List<StressReport>> queryByModel(String modelId) async {
    final db = _requireDb();
    final rows = await db.query(
      'reports',
      where: 'model_id = ?',
      whereArgs: [modelId],
      orderBy: 'start_time DESC',
    );
    return rows.map(_rowToReport).toList();
  }

  /// Returns reports within a start-time range (inclusive).
  Future<List<StressReport>> queryByDateRange({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = _requireDb();
    final rows = await db.query(
      'reports',
      where: 'start_time >= ? AND start_time <= ?',
      whereArgs: [from.toIso8601String(), to.toIso8601String()],
      orderBy: 'start_time DESC',
    );
    return rows.map(_rowToReport).toList();
  }

  /// Returns the total number of reports stored.
  Future<int> count() async {
    final db = _requireDb();
    final result = await db.rawQuery('SELECT COUNT(*) AS c FROM reports');
    return (result.first['c'] as int?) ?? 0;
  }

  /// Deletes all reports for a given model.
  Future<int> deleteByModel(String modelId) async {
    final db = _requireDb();
    return db.delete(
      'reports',
      where: 'model_id = ?',
      whereArgs: [modelId],
    );
  }

  /// Deletes all reports (dangerous).
  Future<void> deleteAll() async {
    final db = _requireDb();
    await db.delete('reports');
  }

  // ─────────────────────────────────────────────────────────────────────
  // Internals
  // ─────────────────────────────────────────────────────────────────────

  Database _requireDb() {
    final db = _db;
    if (db == null) {
      throw StateError(
        'ReportDatabase not open. Call open() before using.',
      );
    }
    return db;
  }

  StressReport _rowToReport(Map<String, Object?> row) {
    final payload = row['payload'] as String;
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return StressReport.fromJson(json);
  }
}
