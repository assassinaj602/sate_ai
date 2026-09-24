import 'dart:io';

import 'badge_type.dart';
import 'report.dart';

/// Generates SVG CI/CD status badges from stress test reports.
///
/// Follows standard shields.io SVG badge formatting for embedding in
/// README files and CI build artifacts.
class BadgeGenerator {
  BadgeGenerator._();

  /// Generates a badge SVG string based on [report] and [type].
  static String generateBadge(
    StressReport report, {
    BadgeType type = BadgeType.status,
  }) {
    switch (type) {
      case BadgeType.status:
        return generateStatusBadge(report);
      case BadgeType.latency:
        return generateLatencyBadge(report);
      case BadgeType.memory:
        return generateMemoryBadge(report);
      case BadgeType.tests:
        return generateTestsBadge(report);
    }
  }

  /// Generates an overall status badge (`SATE AI | PASS` or `SATE AI | FAIL`).
  static String generateStatusBadge(StressReport report) {
    final label = BadgeType.status.label;
    final value = report.passed ? 'PASS' : 'FAIL';
    final color = report.passed ? '#4c1' : '#e05d44';
    return generate(label: label, value: value, color: color);
  }

  /// Generates a duration / latency badge (`stress duration | 120ms`).
  static String generateLatencyBadge(StressReport report) {
    final label = BadgeType.latency.label;
    final value = '${report.totalDuration.inMilliseconds}ms';
    const color = '#007ec6';
    return generate(label: label, value: value, color: color);
  }

  /// Generates a peak memory usage badge (`peak memory | 145.2MB` or `N/A`).
  static String generateMemoryBadge(StressReport report) {
    final label = BadgeType.memory.label;
    final mems = report.results
        .where((r) => r.memoryUsageMB != null)
        .map((r) => r.memoryUsageMB!)
        .toList();

    String value;
    if (mems.isEmpty) {
      value = 'N/A';
    } else {
      mems.sort();
      value = '${mems.last.toStringAsFixed(1)}MB';
    }
    const color = '#007ec6';
    return generate(label: label, value: value, color: color);
  }

  /// Generates a test pass count badge (`stress tests | 5/5 passed`).
  static String generateTestsBadge(StressReport report) {
    final label = BadgeType.tests.label;
    final value = '${report.passCount}/${report.totalTests} passed';
    final color = report.passed ? '#4c1' : '#dfb317';
    return generate(label: label, value: value, color: color);
  }

  /// Generates a custom SVG badge with given [label], [value], and [color].
  static String generate({
    required String label,
    required String value,
    String color = '#4c1',
  }) {
    final labelWidth = _calculateTextWidth(label) + 10;
    final valueWidth = _calculateTextWidth(value) + 10;
    final totalWidth = labelWidth + valueWidth;

    final labelX = (labelWidth / 2) * 10;
    final valueX = (labelWidth + valueWidth / 2) * 10;
    final labelTextLength = (labelWidth - 10) * 10;
    final valueTextLength = (valueWidth - 10) * 10;

    return '''
<svg xmlns="http://www.w3.org/2000/svg" width="$totalWidth" height="20" role="img" aria-label="$label: $value">
  <linearGradient id="s" x2="0" y2="100%">
    <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
    <stop offset="1" stop-opacity=".1"/>
  </linearGradient>
  <clipPath id="r">
    <rect width="$totalWidth" height="20" rx="3" fill="#fff"/>
  </clipPath>
  <g clip-path="url(#r)">
    <rect width="$labelWidth" height="20" fill="#555"/>
    <rect x="$labelWidth" width="$valueWidth" height="20" fill="$color"/>
    <rect width="$totalWidth" height="20" fill="url(#s)"/>
  </g>
  <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110">
    <text x="$labelX" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="$labelTextLength">$label</text>
    <text x="$labelX" y="140" transform="scale(.1)" fill="#fff" textLength="$labelTextLength">$label</text>
    <text x="$valueX" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)" textLength="$valueTextLength">$value</text>
    <text x="$valueX" y="140" transform="scale(.1)" fill="#fff" textLength="$valueTextLength">$value</text>
  </g>
</svg>''';
  }

  /// Saves an SVG badge string to [filePath].
  static Future<void> saveBadge(String filePath, String svgContent) async {
    await File(filePath).writeAsString(svgContent);
  }

  static int _calculateTextWidth(String text) {
    // Approximate font width for Verdana 11px
    return (text.length * 6.5).round();
  }
}
