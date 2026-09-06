import 'package:sate_ai/sate_ai.dart';

/// Helper utility demonstrating how to execute automated stress runs
/// and assert reliability bounds.
class CookbookHelper {
  static Future<StressReport> runCustomStress({
    required AIModelAdapter model,
    required List<FaultInjector> injectors,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    return SateAI.stress(
      model: model,
      injectors: injectors,
      timeout: timeout,
    );
  }
}
