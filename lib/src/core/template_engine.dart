import 'fault_type.dart';
import 'report.dart';

/// Engine for rendering custom report templates.
///
/// Supports placeholders in the format `{{ placeholder }}` that are replaced
/// with values derived from a [StressReport].
///
/// ## Supported placeholders
///
/// - `model` – model ID
/// - `passed` – whether the report passed (true/false)
/// - `passed_emoji` – PASS or FAIL
/// - `total_tests` – number of tests
/// - `passed_count` – number of passing tests
/// - `failed_count` – number of failing tests
/// - `duration_ms` – total duration in milliseconds
/// - `start_time` – ISO8601 start time
/// - `end_time` – ISO8601 end time
/// - `results` – formatted list of all results
/// - `failures` – formatted list of all failures
/// - `memory_mb` – max memory usage (or "N/A")
class TemplateEngine {
  /// Regular expression matching `{{ placeholder }}` tokens.
  static final RegExp _placeholderRegex =
      RegExp(r'\{\{\s*([a-zA-Z0-9_]+)\s*\}\}');

  /// Renders a template string by replacing placeholders with values from [report].
  static String render(String template, StressReport report) {
    return template.replaceAllMapped(_placeholderRegex, (match) {
      final key = match.group(1);
      return _resolve(key, report);
    });
  }

  /// Resolves a placeholder key to its string value.
  static String _resolve(String? key, StressReport report) {
    switch (key) {
      case 'model':
        return report.modelId;
      case 'passed':
        return report.passed.toString();
      case 'passed_emoji':
        return report.passed ? 'PASS' : 'FAIL';
      case 'total_tests':
        return report.results.length.toString();
      case 'passed_count':
        return report.results.where((r) => r.passed).length.toString();
      case 'failed_count':
        return report.results.where((r) => !r.passed).length.toString();
      case 'duration_ms':
        return report.totalDuration.inMilliseconds.toString();
      case 'start_time':
        return report.startTime.toIso8601String();
      case 'end_time':
        return report.endTime.toIso8601String();
      case 'results':
        return _formatResults(report);
      case 'failures':
        return _formatFailures(report);
      case 'memory_mb':
        return _maxMemory(report);
      default:
        return '';
    }
  }

  static String _formatResults(StressReport report) {
    return report.results.map((r) {
      final status = r.passed ? 'PASS' : 'FAIL';
      final time = r.inferenceTime?.inMilliseconds ?? '-';
      final mem = r.memoryUsageMB?.toStringAsFixed(1) ?? '-';
      return '${r.injectorType.displayName}: $status (${time}ms, ${mem}MB)';
    }).join('\n');
  }

  static String _formatFailures(StressReport report) {
    if (report.failures.isEmpty) return '(none)';
    return report.failures
        .map((f) => '${f.injectorType.displayName}: ${f.message}')
        .join('\n');
  }

  static String _maxMemory(StressReport report) {
    final mems = report.results
        .where((r) => r.memoryUsageMB != null)
        .map((r) => r.memoryUsageMB!)
        .toList();
    if (mems.isEmpty) return 'N/A';
    // ⚡ Bolt: Replace O(N log N) sort with O(N) reduce to find max memory usage
    final maxMem = mems.reduce((a, b) => a > b ? a : b);
    return maxMem.toStringAsFixed(1);
  }

  /// Loads and renders a template from a JSON map.
  static String renderJson(Map<String, dynamic> template, StressReport report) {
    final body = template['body'] as String? ?? '';
    return render(body, report);
  }

  /// Loads and renders a template from a YAML map.
  static String renderYaml(Map<String, dynamic> template, StressReport report) {
    final body = template['body'] as String? ?? '';
    return render(body, report);
  }
}
