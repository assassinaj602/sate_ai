/// Types of CI/CD status badges generated from a stress report.
enum BadgeType {
  /// Pass/fail status badge (e.g. `SATE AI | PASS`).
  status,

  /// Total duration / latency badge (e.g. `stress duration | 120ms`).
  latency,

  /// Peak memory usage badge (e.g. `peak memory | 145.2 MB`).
  memory,

  /// Test pass count badge (e.g. `stress tests | 5/5 passed`).
  tests,
}

/// Extension methods for [BadgeType].
extension BadgeTypeX on BadgeType {
  /// Default label for this badge type.
  String get label {
    switch (this) {
      case BadgeType.status:
        return 'SATE AI';
      case BadgeType.latency:
        return 'stress duration';
      case BadgeType.memory:
        return 'peak memory';
      case BadgeType.tests:
        return 'stress tests';
    }
  }

  /// Parses a string into a [BadgeType].
  static BadgeType parse(String value) {
    switch (value.toLowerCase()) {
      case 'latency':
      case 'duration':
        return BadgeType.latency;
      case 'memory':
      case 'mem':
        return BadgeType.memory;
      case 'tests':
      case 'results':
        return BadgeType.tests;
      case 'status':
      default:
        return BadgeType.status;
    }
  }
}
