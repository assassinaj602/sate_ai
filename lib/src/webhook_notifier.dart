import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'core/report.dart';

enum WebhookType { slack, discord, teams }

WebhookType parseWebhookType(String value) {
  switch (value.toLowerCase()) {
    case 'slack':
      return WebhookType.slack;
    case 'discord':
      return WebhookType.discord;
    case 'teams':
      return WebhookType.teams;
    default:
      throw ArgumentError('Unknown webhook type: $value');
  }
}

class WebhookNotifier {
  WebhookNotifier({
    required this.url,
    required this.type,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String url;
  final WebhookType type;
  final http.Client _client;

  Future<bool> send(StressReport report) async {
    final payload = _buildPayload(report);
    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } on SocketException {
      return false;
    } on http.ClientException {
      return false;
    }
  }

  Map<String, dynamic> _buildPayload(StressReport report) {
    switch (type) {
      case WebhookType.slack:
        return _slackPayload(report);
      case WebhookType.discord:
        return _discordPayload(report);
      case WebhookType.teams:
        return _teamsPayload(report);
    }
  }

  Map<String, dynamic> _slackPayload(StressReport report) {
    return {
      'text': _summary(report),
      'attachments': [
        {
          'color': report.passed ? 'good' : 'danger',
          'fields': [
            {'title': 'Model', 'value': report.modelId, 'short': true},
            {'title': 'Tests', 'value': '${report.results.length}', 'short': true},
            {'title': 'Failures', 'value': '${report.failureCount}', 'short': true},
          ],
          'footer': 'SATE AI',
        },
      ],
    };
  }

  Map<String, dynamic> _discordPayload(StressReport report) {
    return {
      'content': _summary(report),
      'embeds': [
        {
          'title': 'Stress Test Report',
          'color': report.passed ? 0x2ECC71 : 0xE74C3C,
          'fields': [
            {'name': 'Model', 'value': report.modelId, 'inline': true},
            {'name': 'Tests', 'value': '${report.results.length}', 'inline': true},
            {'name': 'Failures', 'value': '${report.failureCount}', 'inline': true},
          ],
          'footer': {'text': 'SATE AI'},
        },
      ],
    };
  }

  Map<String, dynamic> _teamsPayload(StressReport report) {
    return {
      '@type': 'MessageCard',
      '@context': 'https://schema.org/extensions',
      'summary': 'SATE AI stress test ${report.passed ? "passed" : "failed"}',
      'themeColor': report.passed ? '2ECC71' : 'E74C3C',
      'title': _summary(report),
      'sections': [
        {
          'facts': [
            {'name': 'Model', 'value': report.modelId},
            {'name': 'Tests', 'value': '${report.results.length}'},
            {'name': 'Failures', 'value': '${report.failureCount}'},
          ],
          'markdown': true,
        },
      ],
    };
  }

  String _summary(StressReport report) {
    if (report.passed) {
      return 'SATE AI: all ${report.results.length} stress tests passed';
    }
    return 'SATE AI: ${report.failureCount} of ${report.results.length} stress tests failed';
  }

  void dispose() => _client.close();
}
