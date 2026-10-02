import '../core/report.dart';
import 'i18n.dart';
import 'report_language.dart';

/// Helper for rendering localized Markdown and HTML reports.
class ReportLocalizer {
  /// Language for localization.
  final ReportLanguage language;

  /// Constructs a [ReportLocalizer] for the given [language].
  const ReportLocalizer([this.language = ReportLanguage.en]);

  /// Convenience lookup for translation key.
  String text(String key) => I18n.text(key, language: language);

  /// Renders a [FaultResult] as a localized Markdown section.
  String formatFaultResultMarkdown(FaultResult result) {
    final buf = StringBuffer()
      ..writeln('### ${result.injectorType.icon} ${result.injectorType.displayName}');
    if (result.flaky) {
      final reason = result.errorMessage ?? text('intermittentFailure');
      buf.writeln('- **${text("status")}**: ⚠️ ${text("flaky")} ($reason)');
    } else {
      final statusStr = result.passed ? text('passedStatus') : text('failedStatus');
      buf.writeln('- **${text("status")}**: $statusStr');
    }
    if (result.inferenceTime != null) {
      buf.writeln(
          '- **${text("inferenceTime")}**: ${result.inferenceTime!.inMilliseconds} ms');
    }
    if (result.memoryUsageMB != null) {
      buf.writeln(
          '- **${text("memoryUsage")}**: ${result.memoryUsageMB!.toStringAsFixed(1)} MB');
    }
    if (result.errorMessage != null && !result.flaky) {
      buf.writeln('- **${text("error")}**: `${result.errorMessage}`');
    }
    return buf.toString();
  }

  /// Renders a [StressReport] as a localized Markdown document.
  String formatReportMarkdown(StressReport report) {
    final overallStatus = report.passed ? text('passedStatus') : text('failedStatus');
    final buf = StringBuffer()
      ..writeln('# ${text("reportTitle")}')
      ..writeln()
      ..writeln('## ${text("summary")}')
      ..writeln('| ${text("keyHeader")} | ${text("valueHeader")} |')
      ..writeln('|---|---|')
      ..writeln('| ${text("model")} | `${report.modelId}` |')
      ..writeln('| ${text("overall")} | $overallStatus |')
      ..writeln('| ${text("totalTests")} | ${report.totalTests} |')
      ..writeln('| ${text("passedCount")} | ${report.passCount} |')
      ..writeln('| ${text("failedCount")} | ${report.failureCount} |')
      ..writeln('| ${text("unexpectedErrors")} | ${report.failures.length} |')
      ..writeln('| ${text("duration")} | ${report.totalDuration.inMilliseconds} ms |')
      ..writeln()
      ..writeln('## ${text("testResults")}')
      ..writeln();

    for (final result in report.results) {
      buf
        ..writeln(formatFaultResultMarkdown(result))
        ..writeln();
    }

    if (report.failures.isNotEmpty) {
      buf
        ..writeln('## ${text("unexpectedErrorsTitle")}')
        ..writeln();
      for (final failure in report.failures) {
        buf
          ..writeln(
            '### ${failure.injectorType.icon} ${failure.injectorType.displayName}',
          )
          ..writeln('- **${text("error")}**: `${failure.message}`');
        if (failure.stackTrace != null) {
          buf
            ..writeln('```')
            ..writeln(failure.stackTrace)
            ..writeln('```');
        }
        buf.writeln();
      }
    }
    return buf.toString();
  }

  /// Renders a [StressReport] as a localized HTML document.
  String formatReportHtml(StressReport report) {
    final buffer = StringBuffer();

    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html lang="${language.code}">');
    buffer.writeln('<head>');
    buffer.writeln('  <meta charset="UTF-8">');
    buffer.writeln(
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">');
    buffer.writeln('  <title>${text("reportTitle")} - ${report.modelId}</title>');
    buffer.writeln(
        '  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>');
    buffer.writeln('  <style>');
    buffer.writeln(_htmlStyles());
    buffer.writeln('  </style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('  <div class="container">');
    buffer.writeln('    <header>');
    buffer.writeln('      <h1>${text("reportTitle")}</h1>');
    buffer.writeln(
        '      <p class="subtitle">${text("model")}: <strong>${report.modelId}</strong></p>');
    buffer.writeln('    </header>');

    final statusClass = report.passed ? 'pass' : 'fail';
    final statusText = report.passed ? text('allPassedBanner') : text('failedBanner');
    buffer.writeln('    <div class="status-banner $statusClass">');
    buffer.writeln('      $statusText');
    buffer.writeln('    </div>');

    // Summary cards
    buffer.writeln('    <div class="summary-cards">');
    final summary = {
      text('totalTests'): report.results.length,
      text('passedCount'): report.results.where((r) => r.passed).length,
      text('failedCount'): report.results.where((r) => !r.passed).length,
      text('unexpectedErrors'): report.failures.length,
      text('duration'): '${report.totalDuration.inMilliseconds} ms',
    };
    for (final entry in summary.entries) {
      buffer.writeln('      <div class="card">');
      buffer.writeln('        <div class="card-value">${entry.value}</div>');
      buffer.writeln('        <div class="card-label">${entry.key}</div>');
      buffer.writeln('      </div>');
    }
    buffer.writeln('    </div>');

    // Charts
    buffer.writeln('    <div class="charts-container">');
    buffer.writeln('      <div class="chart-box">');
    buffer.writeln('        <h3>${text("inferenceTime")} (ms)</h3>');
    buffer.writeln('        <canvas id="timeChart"></canvas>');
    buffer.writeln('      </div>');
    buffer.writeln('      <div class="chart-box">');
    buffer.writeln('        <h3>${text("memoryUsage")} (MB)</h3>');
    buffer.writeln('        <canvas id="memoryChart"></canvas>');
    buffer.writeln('      </div>');
    buffer.writeln('    </div>');

    // Filter controls & Results Table
    buffer.writeln('    <div class="results-section">');
    buffer.writeln('      <div class="table-header">');
    buffer.writeln('        <h2>${text("testResults")}</h2>');
    buffer.writeln('        <div class="controls">');
    buffer.writeln(
        '          <input type="text" id="searchInput" placeholder="Search tests..." onkeyup="filterTable()">');
    buffer.writeln('          <select id="statusFilter" onchange="filterTable()">');
    buffer.writeln('            <option value="all">All Statuses</option>');
    buffer.writeln('            <option value="pass">Passed</option>');
    buffer.writeln('            <option value="fail">Failed</option>');
    buffer.writeln('          </select>');
    buffer.writeln(
        '          <button onclick="exportCSV()">${text("valueHeader")} CSV</button>');
    buffer.writeln('        </div>');
    buffer.writeln('      </div>');

    buffer.writeln('      <table id="resultsTable">');
    buffer.writeln('        <thead>');
    buffer.writeln('          <tr>');
    buffer.writeln('            <th>Injector</th>');
    buffer.writeln('            <th>${text("status")}</th>');
    buffer.writeln('            <th>${text("inferenceTime")} (ms)</th>');
    buffer.writeln('            <th>${text("memoryUsage")} (MB)</th>');
    buffer.writeln('            <th>${text("error")}</th>');
    buffer.writeln('          </tr>');
    buffer.writeln('        </thead>');
    buffer.writeln('        <tbody>');

    for (final result in report.results) {
      final badge = result.passed
          ? '<span class="badge badge-pass">PASS</span>'
          : '<span class="badge badge-fail">FAIL</span>';
      final timeStr = result.inferenceTime != null
          ? '${result.inferenceTime!.inMilliseconds}'
          : 'N/A';
      final memStr = result.memoryUsageMB != null
          ? result.memoryUsageMB!.toStringAsFixed(1)
          : 'N/A';
      final errStr = result.errorMessage != null
          ? _escapeHtml(result.errorMessage!)
          : '-';

      buffer.writeln(
          '          <tr data-status="${result.passed ? 'pass' : 'fail'}">');
      buffer.writeln(
          '            <td>${result.injectorType.icon} ${result.injectorType.displayName}</td>');
      buffer.writeln('            <td>$badge</td>');
      buffer.writeln('            <td>$timeStr</td>');
      buffer.writeln('            <td>$memStr</td>');
      buffer.writeln('            <td class="error-cell">$errStr</td>');
      buffer.writeln('          </tr>');
    }

    buffer.writeln('        </tbody>');
    buffer.writeln('      </table>');
    buffer.writeln('    </div>');

    buffer.writeln('  </div>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static String _htmlStyles() {
    return '''
      :root {
        --bg: #0f172a;
        --card-bg: #1e293b;
        --text: #f8fafc;
        --text-dim: #94a3b8;
        --pass: #22c55e;
        --fail: #ef4444;
        --border: #334155;
      }
      body {
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        background: var(--bg);
        color: var(--text);
        margin: 0;
        padding: 24px;
      }
      .container { max-width: 1200px; margin: 0 auto; }
      header { margin-bottom: 24px; }
      h1 { margin: 0 0 8px 0; font-size: 28px; }
      .subtitle { margin: 0; color: var(--text-dim); }
      .status-banner {
        padding: 16px 24px;
        border-radius: 8px;
        font-weight: 600;
        font-size: 18px;
        margin-bottom: 24px;
      }
      .status-banner.pass { background: rgba(34, 197, 94, 0.15); color: var(--pass); border: 1px solid var(--pass); }
      .status-banner.fail { background: rgba(239, 68, 68, 0.15); color: var(--fail); border: 1px solid var(--fail); }
      .summary-cards { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 16px; margin-bottom: 24px; }
      .card { background: var(--card-bg); padding: 20px; border-radius: 8px; border: 1px solid var(--border); }
      .card-value { font-size: 24px; font-weight: 700; margin-bottom: 4px; }
      .card-label { font-size: 14px; color: var(--text-dim); }
      .charts-container { display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 24px; margin-bottom: 24px; }
      .chart-box { background: var(--card-bg); padding: 20px; border-radius: 8px; border: 1px solid var(--border); }
      .results-section { background: var(--card-bg); border-radius: 8px; border: 1px solid var(--border); padding: 20px; }
      .table-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
      .controls { display: flex; gap: 12px; }
      input, select, button { background: var(--bg); color: var(--text); border: 1px solid var(--border); padding: 8px 12px; border-radius: 6px; }
      table { width: 100%; border-collapse: collapse; text-align: left; }
      th, td { padding: 12px; border-bottom: 1px solid var(--border); }
      th { color: var(--text-dim); font-size: 14px; }
      .badge { padding: 4px 8px; border-radius: 4px; font-size: 12px; font-weight: 600; }
      .badge-pass { background: rgba(34, 197, 94, 0.2); color: var(--pass); }
      .badge-fail { background: rgba(239, 68, 68, 0.2); color: var(--fail); }
      .error-cell { color: var(--fail); font-family: monospace; font-size: 13px; }
    ''';
  }
}
