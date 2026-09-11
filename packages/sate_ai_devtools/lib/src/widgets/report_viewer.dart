import 'package:flutter/material.dart';
import 'package:sate_ai/sate_ai.dart';

class ReportViewer extends StatelessWidget {
  final StressReport? report;
  final List<String> logs;

  const ReportViewer({super.key, this.report, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1d27),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2e3345)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              reverse: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: logs.map((log) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      log,
                      style: TextStyle(
                        color: _getLogColor(log),
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLogColor(String log) {
    if (log.contains('✅') || log.contains('PASS')) return Colors.green;
    if (log.contains('❌') || log.contains('FAIL')) return Colors.red;
    if (log.contains('⚠️')) return Colors.orange;
    if (log.contains('🚀') || log.contains('⚙️')) return const Color(0xFF60a5fa);
    return const Color(0xFFa0a5b5);
  }
}
