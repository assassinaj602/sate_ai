import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:sate_ai/sate_ai.dart';

void main() {
  StressReport makeReport({bool passed = true}) {
    return StressReport(
      modelId: 'test-model',
      passed: passed,
      results: [
        FaultResult(
          injectorType: FaultType.memoryPressure,
          passed: passed,
          inferenceTime: const Duration(milliseconds: 100),
          memoryUsageMB: 80.0,
          errorMessage: passed ? null : 'OOM',
        ),
      ],
      failures: passed
          ? []
          : [
              const Failure(
                injectorType: FaultType.memoryPressure,
                message: 'OOM',
              ),
            ],
      startTime: DateTime.parse('2026-09-28T10:00:00Z'),
      endTime: DateTime.parse('2026-09-28T10:00:02Z'),
      totalDuration: const Duration(seconds: 2),
    );
  }

  group('WebhookPayload', () {
    test('slack payload has blocks', () {
      final payload = WebhookPayload.build(WebhookType.slack, makeReport());
      expect(payload['blocks'], isA<List>());
      expect(payload['text'], contains('PASSED'));
    });

    test('slack payload marks failures', () {
      final payload =
          WebhookPayload.build(WebhookType.slack, makeReport(passed: false));
      expect(payload['text'], contains('FAILED'));
    });

    test('discord payload has embeds', () {
      final payload = WebhookPayload.build(WebhookType.discord, makeReport());
      expect(payload['embeds'], isA<List>());
      final embed = (payload['embeds'] as List).first as Map;
      expect(embed['color'], equals(0x34d399));
    });

    test('discord payload uses fail color on failure', () {
      final payload =
          WebhookPayload.build(WebhookType.discord, makeReport(passed: false));
      final embed = (payload['embeds'] as List).first as Map;
      expect(embed['color'], equals(0xf87171));
    });

    test('teams payload has MessageCard type', () {
      final payload = WebhookPayload.build(WebhookType.teams, makeReport());
      expect(payload['@type'], equals('MessageCard'));
      expect(payload['themeColor'], equals('34d399'));
    });

    test('teams payload uses fail color on failure', () {
      final payload =
          WebhookPayload.build(WebhookType.teams, makeReport(passed: false));
      expect(payload['themeColor'], equals('f87171'));
    });

    test('payloads are JSON serializable', () {
      for (final type in WebhookType.values) {
        final payload = WebhookPayload.build(type, makeReport());
        expect(() => jsonEncode(payload), returnsNormally);
      }
    });
  });

  group('WebhookNotifier', () {
    test('reports success on 200', () async {
      final client = _FakeClient(200, 'ok');
      final notifier = WebhookNotifier(
        url: 'https://example.test/hook',
        type: WebhookType.slack,
        client: client,
      );
      final result = await notifier.send(makeReport());
      expect(result.ok, isTrue);
      expect(result.statusCode, equals(200));
    });

    test('reports failure on 500', () async {
      final client = _FakeClient(500, 'boom');
      final notifier = WebhookNotifier(
        url: 'https://example.test/hook',
        type: WebhookType.slack,
        client: client,
      );
      final result = await notifier.send(makeReport());
      expect(result.ok, isFalse);
      expect(result.statusCode, equals(500));
    });

    test('reports failure on network error', () async {
      final client = _ThrowingClient();
      final notifier = WebhookNotifier(
        url: 'https://example.test/hook',
        type: WebhookType.slack,
        client: client,
      );
      final result = await notifier.send(makeReport());
      expect(result.ok, isFalse);
      expect(result.message, contains('Webhook failed'));
    });

    test('WebhookResult serializes', () {
      final result = WebhookResult(
        ok: true,
        statusCode: 200,
        message: 'ok',
      );
      final json = result.toJson();
      expect(json['ok'], isTrue);
      expect(json['statusCode'], equals(200));
    });
  });
}

class _FakeClient extends http.BaseClient {
  final int status;
  final String body;
  _FakeClient(this.status, this.body);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = utf8.encode(body);
    return http.StreamedResponse(
      Stream.fromIterable([bytes]),
      status,
      contentLength: bytes.length,
    );
  }
}

class _ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw http.ClientException('boom');
  }
}
