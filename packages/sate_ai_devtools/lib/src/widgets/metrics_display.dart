import 'package:flutter/material.dart';
import 'package:sate_ai/sate_ai.dart';

class MetricsDisplay extends StatelessWidget {
  final StressReport? report;

  const MetricsDisplay({super.key, this.report});

  @override
  Widget build(BuildContext context) {
    if (report == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1d27),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2e3345)),
        ),
        child: const Center(
          child: Text(
            'Run a stress test to see metrics',
            style: TextStyle(color: Color(0xFFa0a5b5)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1d27),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2e3345)),
      ),
      child: Row(
        children: [
          _MetricItem(
            label: 'Total',
            value: '${report!.results.length}',
          ),
          _MetricItem(
            label: 'Passed',
            value: '${report!.results.where((r) => r.passed).length}',
            color: Colors.green,
          ),
          _MetricItem(
            label: 'Failed',
            value: '${report!.results.where((r) => !r.passed).length}',
            color: Colors.red,
          ),
          _MetricItem(
            label: 'Duration',
            value: '${report!.totalDuration.inMilliseconds}ms',
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MetricItem({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFa0a5b5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
