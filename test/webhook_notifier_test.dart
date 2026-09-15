import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sate_ai/src/core/report.dart';
import 'package:sate_ai/src/webhook_notifier.dart';
import 'package:test/test.dart';

StressReport _passedReport() {
  return StressReport(
    modelId: 'test-model',
    results: const [],
    startedAt: DateTime(2026, 1, 1),
    finishedAt: DateTime(2026, 1, 1, 0, 0, 1),
  );
}

void main() {
  group('parseWebhookType', () {
    test('parses slack', () {
      expect(parseWebhookType('slack'), WebhookType.slack);
    });

    test('parses discord', () {
      expect(parseWebhookType('discord'), WebhookType.discord);
    });

    test('parses teams', () {
      expect(parseWebhookType('teams'), WebhookType.teams);
    });

    test('is case insensitive', () {
      expect(parseWebhookType('SLACK'), WebhookType.slack);
    });

    test('throws on unknown type', () {
      expect(() => parseWebhookType('mattermost'), throwsArgumentError);
    });
  });

  group('WebhookNotifier', () {
    test('sends slack payload with text and attachment', () async {
      late Map<String, dynamic> body;
      final client = MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('ok', 200);
      });

      final notifier = WebhookNotifier(
        url: 'https://hooks.slack.com/test',
        type: WebhookType.slack,
        client: client,
      );

      final ok = await notifier.send(_passedReport());
      expect(ok, isTrue);
      expect(body['text'], contains('passed'));
      expect(body['attachments'], isA<List<dynamic>>());
    });

    test('sends discord payload with embeds', () async {
      late Map<String, dynamic> body;
      final client = MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('ok', 204);
      });

      final notifier = WebhookNotifier(
        url: 'https://discord.com/api/webhooks/test',
        type: WebhookType.discord,
        client: client,
      );

      final ok = await notifier.send(_passedReport());
      expect(ok, isTrue);
      expect(body['embeds'], isA<List<dynamic>>());
    });

    test('sends teams payload with MessageCard', () async {
      late Map<String, dynamic> body;
      final client = MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response('ok', 200);
      });

      final notifier = WebhookNotifier(
        url: 'https://outlook.office.com/webhook/test',
        type: WebhookType.teams,
        client: client,
      );

      final ok = await notifier.send(_passedReport());
      expect(ok, isTrue);
      expect(body['@type'], 'MessageCard');
    });

    test('returns false on server error', () async {
      final client = MockClient((request) async => http.Response('boom', 500));

      final notifier = WebhookNotifier(
        url: 'https://hooks.slack.com/test',
        type: WebhookType.slack,
        client: client,
      );

      expect(await notifier.send(_passedReport()), isFalse);
    });

    test('returns false on client exception', () async {
      final client = MockClient((request) async {
        throw http.ClientException('offline');
      });

      final notifier = WebhookNotifier(
        url: 'https://hooks.slack.com/test',
        type: WebhookType.slack,
        client: client,
      );

      expect(await notifier.send(_passedReport()), isFalse);
    });
  });
}
