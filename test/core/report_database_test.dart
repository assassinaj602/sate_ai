import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  late String dbPath;
  late ReportDatabase db;

  setUp(() async {
    final tempDir = await Directory.systemTemp.createTemp('sate_db_test_');
    dbPath = '${tempDir.path}/test_reports.db';
    db = ReportDatabase(dbPath);
  });

  tearDown(() async {
    if (db.isOpen) {
      await db.close();
    }
    final file = File(dbPath);
    if (file.existsSync()) {
      file.deleteSync();
    }
  });

  StressReport createDummyReport({
    String modelId = 'test-model',
    bool passed = true,
    DateTime? startTime,
  }) {
    final now = startTime ?? DateTime.now();
    return StressReport(
      modelId: modelId,
      passed: passed,
      startTime: now,
      endTime: now.add(const Duration(milliseconds: 250)),
      totalDuration: const Duration(milliseconds: 250),
      results: [
        FaultResult(
          injectorType: FaultType.memoryPressure,
          passed: passed,
          inferenceTime: const Duration(milliseconds: 100),
          memoryUsageMB: 120,
          errorMessage: passed ? null : 'Out of memory',
        ),
      ],
      failures: passed
          ? []
          : [
              const Failure(
                injectorType: FaultType.memoryPressure,
                message: 'Out of memory',
              ),
            ],
    );
  }

  test('open() initializes database and sets isOpen to true', () async {
    expect(db.isOpen, isFalse);
    await db.open();
    expect(db.isOpen, isTrue);
  });

  test('close() closes database and sets isOpen to false', () async {
    await db.open();
    expect(db.isOpen, isTrue);
    await db.close();
    expect(db.isOpen, isFalse);
  });

  test('insertReport() inserts a report and returns positive row ID', () async {
    await db.open();
    final report = createDummyReport();
    final id = await db.insertReport(report);
    expect(id, greaterThan(0));
  });

  test('count() returns total number of reports', () async {
    await db.open();
    expect(await db.count(), equals(0));

    await db.insertReport(createDummyReport(modelId: 'm1'));
    await db.insertReport(createDummyReport(modelId: 'm2'));
    expect(await db.count(), equals(2));
  });

  test('queryRecent() returns reports ordered by start_time DESC with limit', () async {
    await db.open();
    final t1 = DateTime.now().subtract(const Duration(hours: 2));
    final t2 = DateTime.now().subtract(const Duration(hours: 1));
    final t3 = DateTime.now();

    await db.insertReport(createDummyReport(modelId: 'm1', startTime: t1));
    await db.insertReport(createDummyReport(modelId: 'm2', startTime: t2));
    await db.insertReport(createDummyReport(modelId: 'm3', startTime: t3));

    final recent = await db.queryRecent(limit: 2);
    expect(recent.length, equals(2));
    expect(recent.first.modelId, equals('m3'));
    expect(recent.last.modelId, equals('m2'));
  });

  test('queryByModel() returns only reports for specified model ID', () async {
    await db.open();
    await db.insertReport(createDummyReport(modelId: 'llama-7b'));
    await db.insertReport(createDummyReport(modelId: 'llama-7b'));
    await db.insertReport(createDummyReport(modelId: 'mistral-7b'));

    final llamaReports = await db.queryByModel('llama-7b');
    expect(llamaReports.length, equals(2));
    expect(llamaReports.every((r) => r.modelId == 'llama-7b'), isTrue);

    final mistralReports = await db.queryByModel('mistral-7b');
    expect(mistralReports.length, equals(1));
  });

  test('queryByDateRange() filters reports within time window', () async {
    await db.open();
    final base = DateTime(2026, 1, 10, 12, 0);

    await db.insertReport(createDummyReport(modelId: 'm1', startTime: base));
    await db.insertReport(createDummyReport(modelId: 'm2', startTime: base.add(const Duration(hours: 5))));
    await db.insertReport(createDummyReport(modelId: 'm3', startTime: base.add(const Duration(days: 2))));

    final filtered = await db.queryByDateRange(
      from: base.subtract(const Duration(minutes: 1)),
      to: base.add(const Duration(hours: 6)),
    );

    expect(filtered.length, equals(2));
  });

  test('deleteByModel() removes only matching model reports', () async {
    await db.open();
    await db.insertReport(createDummyReport(modelId: 'to-delete'));
    await db.insertReport(createDummyReport(modelId: 'to-keep'));

    final deletedCount = await db.deleteByModel('to-delete');
    expect(deletedCount, equals(1));
    expect(await db.count(), equals(1));

    final remaining = await db.queryRecent();
    expect(remaining.single.modelId, equals('to-keep'));
  });

  test('deleteAll() removes all reports from database', () async {
    await db.open();
    await db.insertReport(createDummyReport(modelId: 'm1'));
    await db.insertReport(createDummyReport(modelId: 'm2'));
    expect(await db.count(), equals(2));

    await db.deleteAll();
    expect(await db.count(), equals(0));
  });

  test('full round-trip preserves StressReport data integrity', () async {
    await db.open();
    final original = createDummyReport(modelId: 'custom-model', passed: false);
    await db.insertReport(original);

    final retrievedList = await db.queryByModel('custom-model');
    expect(retrievedList.length, equals(1));

    final retrieved = retrievedList.first;
    expect(retrieved.modelId, equals(original.modelId));
    expect(retrieved.passed, equals(original.passed));
    expect(retrieved.results.length, equals(original.results.length));
    expect(retrieved.failures.length, equals(original.failures.length));
    expect(retrieved.totalDuration.inMilliseconds, equals(original.totalDuration.inMilliseconds));
  });

  test('throws StateError when operations are called without open()', () async {
    final report = createDummyReport();
    expect(() => db.insertReport(report), throwsStateError);
    expect(() => db.count(), throwsStateError);
    expect(() => db.queryRecent(), throwsStateError);
    expect(() => db.queryByModel('test'), throwsStateError);
    expect(() => db.deleteByModel('test'), throwsStateError);
    expect(() => db.deleteAll(), throwsStateError);
  });

  test('persists data across database close and reopen', () async {
    await db.open();
    await db.insertReport(createDummyReport(modelId: 'persistent-model'));
    await db.close();

    // Reopen same database file
    final reopenedDb = ReportDatabase(dbPath);
    await reopenedDb.open();
    expect(await reopenedDb.count(), equals(1));

    final reports = await reopenedDb.queryByModel('persistent-model');
    expect(reports.length, equals(1));
    await reopenedDb.close();
  });
}
