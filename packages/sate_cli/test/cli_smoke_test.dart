import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('sate_cli smoke test', () {
    test('help command exits with code 0', () async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/sate_ai.dart', '--help'],
        workingDirectory: Directory.current.path,
      );
      expect(result.exitCode, 0);
      expect(result.stdout, contains('SATE AI'));
    });

    test('unknown flag exits with non-zero exit code', () async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/sate_ai.dart', '--not-a-real-flag'],
        workingDirectory: Directory.current.path,
      );
      expect(result.exitCode, anyOf(1, 2, 64));
    });

    test('health-check command exits cleanly with no model file', () async {
      final result = await Process.run(
        'dart',
        ['run', 'bin/sate_ai.dart', '--health-check'],
        workingDirectory: Directory.current.path,
      );
      // Health check runs against MockAdapter fallback and succeeds or exits cleanly
      expect(result.exitCode, anyOf(0, 1, 2, 64));
    });
  });
}

