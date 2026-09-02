import 'package:flutter/material.dart';

class ControlPanel extends StatelessWidget {
  final VoidCallback onRun;
  final VoidCallback onSaveBaseline;
  final VoidCallback onCompareBaseline;
  final VoidCallback onClear;
  final bool isRunning;

  const ControlPanel({
    super.key,
    required this.onRun,
    required this.onSaveBaseline,
    required this.onCompareBaseline,
    required this.onClear,
    required this.isRunning,
  });

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
            'Controls',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildButton(
            icon: Icons.play_arrow,
            label: 'Run Stress Test',
            onPressed: isRunning ? null : onRun,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildButton(
            icon: Icons.save,
            label: 'Save as Baseline',
            onPressed: isRunning ? null : onSaveBaseline,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildButton(
            icon: Icons.compare_arrows,
            label: 'Compare Baseline',
            onPressed: isRunning ? null : onCompareBaseline,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildButton(
            icon: Icons.clear_all,
            label: 'Clear Results',
            onPressed: isRunning ? null : onClear,
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.withOpacity(0.1),
          disabledForegroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: color.withOpacity(0.3)),
          ),
        ),
      ),
    );
  }
}
