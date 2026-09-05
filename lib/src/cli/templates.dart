/// Templates for generating custom injectors.
class InjectorTemplates {
  static String injectorFile(String name) => '''
import 'dart:async';
import 'package:sate_ai/src/adapters/model_adapter.dart';
import 'package:sate_ai/src/core/fault_injector.dart';
import 'package:sate_ai/src/core/fault_type.dart';

/// Custom injector: $name
///
/// TODO: Describe what this injector does.
class ${name}Injector implements FaultInjector {
  final AIModelAdapter model;

  ${name}Injector({required this.model});

  @override
  FaultType get type => FaultType.custom;

  @override
  String get name => '${name}Injector';

  @override
  String get description => 'Custom injector for $name';

  @override
  Future<void> inject() async {
    // TODO: Implement injection logic
    // Example: simulate a custom failure
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> reset() async {
    // TODO: Reset state
    await Future.delayed(const Duration.zero);
  }

  /// Applies the injector to a model adapter.
  Future<void> applyTo(AIModelAdapter model) async {
    await inject();
    // TODO: Apply custom fault to model
    // Example: simulate memory pressure
    await model.simulateMemoryPressure(50);
    await Future.delayed(const Duration(milliseconds: 10));
  }

  /// Convenience method to get the status as a readable string.
  String getStatus() {
    // TODO: Return status
    return '${name}Injector: applied';
  }
}
''';

  static String testFile(String name) => '''
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('${name}Injector', () {
    late ${name}Injector injector;
    late MockAdapter model;

    setUp(() {
      model = MockAdapter(modelId: 'test-model');
      injector = ${name}Injector(model: model);
    });

    // --- Basic interface tests ---

    test('type is FaultType.custom', () {
      expect(injector.type, equals(FaultType.custom));
    });

    test('name is non-empty', () {
      expect(injector.name, isNotEmpty);
    });

    test('description is non-empty', () {
      expect(injector.description, isNotEmpty);
    });

    // --- Initial state tests ---

    test('inject() completes without error', () async {
      await injector.inject();
      expect(true, isTrue); // If we got here, it passed
    });

    test('reset() completes without error', () async {
      await injector.reset();
      expect(true, isTrue);
    });

    test('applyTo simulates memory pressure', () async {
      final initialMemory = model.currentMemoryMB;
      await injector.applyTo(model);
      expect(model.currentMemoryMB, greaterThan(initialMemory));
    });

    test('getStatus returns non-empty string', () {
      expect(injector.getStatus(), isNotEmpty);
    });

    // TODO: Add more tests for your custom injector
  });
}
''';

  static String exportedFile(String name) => '''
export 'src/injectors/${name.toLowerCase()}_injector.dart';
''';
}
