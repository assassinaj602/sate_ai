import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sate_core/src/core/report.dart';
import 'package:sate_core/src/core/webhook_payload.dart';

/// Sends webhook notifications for stress test results.
///
/// Supports Slack, Discord, and Microsoft Teams incoming webhooks.
/// Failures are reported via [WebhookResult] instead of throwing so that
/// a broken webhook never breaks a stress test run.
class WebhookNotifier {
  /// The webhook URL to POST to.
  final String url;

  /// The provider type.
  final WebhookType type;

  /// Optional HTTP client (useful for testing).
  final http.Client _client;

  /// Optional timeout.
  final Duration timeout;

  /// Creates a new [WebhookNotifier].
  WebhookNotifier({
    required this.url,
    required this.type,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  /// Sends a notification for [report].
  Future<WebhookResult> send(StressReport report) async {
    final payload = WebhookPayload.build(type, report);
    final body = jsonEncode(payload);

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(timeout);

      final ok = response.statusCode >= 200 && response.statusCode < 300;
      return WebhookResult(
        ok: ok,
        statusCode: response.statusCode,
        message: ok
            ? 'Notification delivered'
            : 'Webhook returned ${response.statusCode}: ${response.body}',
      );
    } on TimeoutException {
      return WebhookResult(
        ok: false,
        statusCode: null,
        message: 'Webhook timed out after ${timeout.inSeconds}s',
      );
    } catch (e) {
      return WebhookResult(
        ok: false,
        statusCode: null,
        message: 'Webhook failed: $e',
      );
    }
  }

  /// Closes the underlying HTTP client.
  void dispose() => _client.close();
}

/// Outcome of a webhook delivery attempt.
class WebhookResult {
  /// Whether the webhook delivery succeeded.
  final bool ok;

  /// HTTP status code returned by the endpoint (if any).
  final int? statusCode;

  /// Descriptive message or error detail.
  final String message;

  /// Creates a new [WebhookResult].
  WebhookResult({
    required this.ok,
    this.statusCode,
    required this.message,
  });

  /// Serializes to JSON map.
  Map<String, dynamic> toJson() => {
        'ok': ok,
        'statusCode': statusCode,
        'message': message,
      };

  @override
  String toString() =>
      'WebhookResult(ok: $ok, status: $statusCode, message: $message)';
}
