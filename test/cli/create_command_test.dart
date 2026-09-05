import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/src/cli/templates.dart';

void main() {
  group('CLI Create Command', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sate_ai_test');
      // Create minimal project structure
      final libDir = Directory('${tempDir.path}/lib/src/injectors');
      await libDir.create(recursive: true);
      final testDir = Directory('${tempDir.path}/test/injectors');
      await testDir.create(recursive: true);
    });

    tearDown(() async {
      await tempDir.delete(recursive: true);
    });

    test('create injector generates files', () async {
      // This is a unit test for the template generation logic
      final name = 'TestInjector';
      final content = InjectorTemplates.injectorFile(name);
      expect(content, contains('class ${name}Injector'));
      expect(content, contains('FaultType.custom'));
      expect(content, contains('TODO: Describe what this injector does'));
    });

    test('create injector test template is valid', () async {
      final name = 'TestInjector';
      final content = InjectorTemplates.testFile(name);
      expect(content, contains('group(\'${name}Injector\''));
      expect(content, contains('MockAdapter'));
      expect(content, contains('FaultType.custom'));
    });

    test('injector template contains required methods', () async {
      final name = 'TestInjector';
      final content = InjectorTemplates.injectorFile(name);
      expect(content, contains('Future<void> inject()'));
      expect(content, contains('Future<void> reset()'));
      expect(content, contains('Future<void> applyTo'));
      expect(content, contains('String getStatus()'));
    });

    test('test template contains required tests', () async {
      final name = 'TestInjector';
      final content = InjectorTemplates.testFile(name);
      expect(content, contains('test(\'type is FaultType.custom\''));
      expect(content, contains('test(\'name is non-empty\''));
      expect(content, contains('test(\'applyTo simulates memory pressure\''));
    });
  });
}
