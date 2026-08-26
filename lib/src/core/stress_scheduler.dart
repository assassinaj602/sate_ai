// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'package:cron/cron.dart';
import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/report.dart';
import 'package:sate_ai/src/core/stress_runner.dart';

/// Scheduler for running stress tests at specified intervals.
///
/// Uses cron expressions to schedule stress test execution.
/// Supports storing and comparing reports for regression detection.
class StressScheduler {
  /// The cron expression specifying execution interval.
  final String cronExpression;

  /// Model under test.
  final AIModelAdapter model;

  /// Ordered list of fault injectors to execute.
  final List<FaultInjector> injectors;

  /// Timeout per test cycle.
  final Duration timeout;

  /// Directory path where stress report files are saved.
  final String reportDirectory;

  Cron? _cron;
  bool _isRunning = false;
  final List<StressReport> _reportHistory = [];
  StressReport? _lastSuccessfulReport;

  /// Constructs a [StressScheduler] instance and validates the cron expression.
  StressScheduler({
    required this.cronExpression,
    required this.model,
    required this.injectors,
    this.timeout = const Duration(seconds: 30),
    this.reportDirectory = 'stress_reports',
  }) {
    _validateCronExpression();
  }

  /// Validates the cron expression.
  void _validateCronExpression() {
    try {
      final parts = cronExpression.split(' ').where((s) => s.isNotEmpty).toList();
      if (parts.length != 5 && parts.length != 6) {
        throw ArgumentError(
          'Invalid cron expression: "$cronExpression". '
          'Expected 5 or 6 parts (minute hour day month weekday [year])',
        );
      }
      Schedule.parse(cronExpression);
    } catch (e) {
      if (e is ArgumentError) rethrow;
      throw ArgumentError('Invalid cron expression: $e');
    }
  }

  /// Starts the scheduler.
  Future<void> start() async {
    if (_isRunning) {
      print('Scheduler is already running.');
      return;
    }

    _cron = Cron();
    _isRunning = true;

    // Ensure report directory exists
    await _ensureReportDirectory();

    print('Stress scheduler started with cron: $cronExpression');
    print('Reports will be saved to: $reportDirectory');

    _cron!.schedule(Schedule.parse(cronExpression), () async {
      await _runScheduledTest();
    });
  }

  /// Stops the scheduler.
  void stop() {
    if (_cron != null) {
      _cron!.close();
      _cron = null;
    }
    _isRunning = false;
    print('Stress scheduler stopped.');
  }

  /// Runs a scheduled test.
  Future<void> _runScheduledTest() async {
    print('Running scheduled stress test at ${DateTime.now()}');

    try {
      final runner = StressRunner(
        model: model,
        injectors: injectors,
        timeout: timeout,
      );

      final report = await runner.run();

      // Save the report
      final reportPath = await _saveReport(report);
      print('Report saved to: $reportPath');

      // Compare with last successful report
      if (_lastSuccessfulReport != null) {
        final comparison = _compareReports(report, _lastSuccessfulReport!);
        if (!comparison.passed) {
          print('⚠️ Test regressed!');
          print(
              '  - Previous: ${comparison.previousPassed}/${comparison.previousTotal}');
          print(
              '  - Current: ${comparison.currentPassed}/${comparison.currentTotal}');
        } else {
          print('✅ Test passed. No regression detected.');
        }
      }

      // Store report history (keep last 30)
      _reportHistory.add(report);
      if (_reportHistory.length > 30) {
        _reportHistory.removeAt(0);
      }

      // Update last successful report
      if (report.passed) {
        _lastSuccessfulReport = report;
      }
    } catch (e) {
      print('❌ Scheduled test failed: $e');
    }
  }

  /// Ensures the report directory exists.
  Future<void> _ensureReportDirectory() async {
    final dir = Directory(reportDirectory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  /// Saves a report to disk with timestamp.
  Future<String> _saveReport(StressReport report) async {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filename = 'report_$timestamp.json';
    final path = '$reportDirectory/$filename';
    await File(path).writeAsString(report.toJsonString());
    return path;
  }

  /// Compares two reports and returns a comparison result.
  ReportComparison _compareReports(
      StressReport current, StressReport previous) {
    return ReportComparison(
      currentPassed: current.results.where((r) => r.passed).length,
      currentTotal: current.results.length,
      previousPassed: previous.results.where((r) => r.passed).length,
      previousTotal: previous.results.length,
      passed: current.passed == previous.passed,
    );
  }

  /// Gets the report history.
  List<StressReport> get reportHistory => List.unmodifiable(_reportHistory);

  /// Gets the last successful report.
  StressReport? get lastSuccessfulReport => _lastSuccessfulReport;

  /// Whether the scheduler is running.
  bool get isRunning => _isRunning;

  /// Returns the status summary.
  String getStatus() {
    final status = [
      'Scheduler: ${_isRunning ? "Running" : "Stopped"}',
      'Cron: $cronExpression',
      'Reports saved: ${_reportHistory.length}',
      'Last successful: ${_lastSuccessfulReport != null ? "Yes" : "No"}',
    ];
    return status.join('\n');
  }
}

/// Result of comparing two reports.
class ReportComparison {
  /// Number of passed tests in the current report.
  final int currentPassed;

  /// Total number of tests in the current report.
  final int currentTotal;

  /// Number of passed tests in the previous report.
  final int previousPassed;

  /// Total number of tests in the previous report.
  final int previousTotal;

  /// Overall pass/fail status comparison.
  final bool passed;

  /// Constructs a [ReportComparison].
  ReportComparison({
    required this.currentPassed,
    required this.currentTotal,
    required this.previousPassed,
    required this.previousTotal,
    required this.passed,
  });

  /// Converts comparison to JSON map.
  Map<String, dynamic> toJson() => {
        'currentPassed': currentPassed,
        'currentTotal': currentTotal,
        'previousPassed': previousPassed,
        'previousTotal': previousTotal,
        'passed': passed,
      };
}
