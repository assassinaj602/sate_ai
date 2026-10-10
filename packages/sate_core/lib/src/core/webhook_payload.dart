import 'package:sate_core/src/core/fault_type.dart';
import 'package:sate_core/src/core/report.dart';

/// Supported webhook providers.
enum WebhookType {
  /// Slack incoming webhook.
  slack,

  /// Discord webhook.
  discord,

  /// Microsoft Teams incoming webhook.
  teams,
}

/// Builds provider-specific JSON payloads from a [StressReport].
class WebhookPayload {
  /// Builds a payload for the given [type].
  static Map<String, dynamic> build(WebhookType type, StressReport report) {
    switch (type) {
      case WebhookType.slack:
        return _slack(report);
      case WebhookType.discord:
        return _discord(report);
      case WebhookType.teams:
        return _teams(report);
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Slack
  // ─────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _slack(StressReport report) {
    final status = report.passed ? 'PASSED' : 'FAILED';
    final summary =
        '${report.results.where((r) => r.passed).length}/${report.results.length} tests passed '
        'in ${report.totalDuration.inMilliseconds}ms';

    final blocks = <Map<String, dynamic>>[
      {
        'type': 'header',
        'text': {
          'type': 'plain_text',
          'text': 'SATE AI Stress Test $status',
        },
      },
      {
        'type': 'section',
        'fields': [
          {'type': 'mrkdwn', 'text': '*Model:*\n${report.modelId}'},
          {'type': 'mrkdwn', 'text': '*Status:*\n$status'},
          {'type': 'mrkdwn', 'text': '*Summary:*\n$summary'},
          {
            'type': 'mrkdwn',
            'text': '*Failures:*\n${report.failures.length}',
          },
        ],
      },
    ];

    if (report.failures.isNotEmpty) {
      final failureText = report.failures
          .take(5)
          .map((f) => '- ${f.injectorType.displayName}: ${f.message}')
          .join('\n');
      blocks.add({
        'type': 'section',
        'text': {'type': 'mrkdwn', 'text': '*Top failures:*\n$failureText'},
      });
    }

    return {
      'text': 'SATE AI Stress Test $status for ${report.modelId}',
      'blocks': blocks,
    };
  }

  // ─────────────────────────────────────────────────────────────────────
  // Discord
  // ─────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _discord(StressReport report) {
    final color = report.passed ? 0x34d399 : 0xf87171;
    final status = report.passed ? 'PASSED' : 'FAILED';

    final fields = <Map<String, dynamic>>[
      {
        'name': 'Model',
        'value': report.modelId,
        'inline': true,
      },
      {
        'name': 'Status',
        'value': status,
        'inline': true,
      },
      {
        'name': 'Tests',
        'value':
            '${report.results.where((r) => r.passed).length}/${report.results.length}',
        'inline': true,
      },
      {
        'name': 'Duration',
        'value': '${report.totalDuration.inMilliseconds}ms',
        'inline': true,
      },
      {
        'name': 'Failures',
        'value': report.failures.length.toString(),
        'inline': true,
      },
    ];

    if (report.failures.isNotEmpty) {
      final failureText = report.failures
          .take(5)
          .map((f) => '- ${f.injectorType.displayName}: ${f.message}')
          .join('\n');
      fields.add({
        'name': 'Failure details',
        'value': failureText,
        'inline': false,
      });
    }

    return {
      'content': 'SATE AI Stress Test $status',
      'embeds': [
        {
          'title': 'SATE AI Stress Test Report',
          'color': color,
          'fields': fields,
          'timestamp': report.endTime.toIso8601String(),
        },
      ],
    };
  }

  // ─────────────────────────────────────────────────────────────────────
  // Microsoft Teams
  // ─────────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _teams(StressReport report) {
    final status = report.passed ? 'PASSED' : 'FAILED';
    final color = report.passed ? '34d399' : 'f87171';

    final facts = <Map<String, String>>[
      {'name': 'Model', 'value': report.modelId},
      {'name': 'Status', 'value': status},
      {
        'name': 'Tests',
        'value':
            '${report.results.where((r) => r.passed).length}/${report.results.length}',
      },
      {'name': 'Duration', 'value': '${report.totalDuration.inMilliseconds}ms'},
      {'name': 'Failures', 'value': report.failures.length.toString()},
    ];

    if (report.failures.isNotEmpty) {
      final failureText = report.failures
          .take(5)
          .map((f) => '${f.injectorType.displayName}: ${f.message}')
          .join('; ');
      facts.add({'name': 'Failure details', 'value': failureText});
    }

    return {
      '@type': 'MessageCard',
      '@context': 'https://schema.org/extensions',
      'themeColor': color,
      'summary': 'SATE AI Stress Test $status',
      'title': 'SATE AI Stress Test $status',
      'sections': [
        {
          'activityTitle': 'SATE AI Stress Test',
          'activitySubtitle': report.modelId,
          'facts': facts,
          'markdown': true,
        },
      ],
    };
  }
}
