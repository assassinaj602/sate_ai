import 'package:flutter/material.dart';
import 'package:sate_ai_devtools/src/screen.dart';

/// The DevTools plugin widget for SATE AI.
class SateAIDevToolsPlugin extends StatelessWidget {
  const SateAIDevToolsPlugin({super.key});

  String get name => 'SATE AI';
  String get icon => '🧪';

  @override
  Widget build(BuildContext context) {
    return const SateAIScreen();
  }
}
