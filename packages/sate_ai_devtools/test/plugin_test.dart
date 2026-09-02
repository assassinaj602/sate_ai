import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai_devtools/sate_ai_devtools.dart';

void main() {
  test('plugin name is SATE AI', () {
    const plugin = SateAIDevToolsPlugin();
    expect(plugin.name, 'SATE AI');
  });

  test('plugin icon is not empty', () {
    const plugin = SateAIDevToolsPlugin();
    expect(plugin.icon, isNotEmpty);
  });
}
