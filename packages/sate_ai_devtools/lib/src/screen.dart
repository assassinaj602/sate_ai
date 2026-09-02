import 'package:flutter/material.dart';
import 'package:sate_ai/sate_ai.dart';
import 'package:sate_ai_devtools/src/widgets/control_panel.dart';
import 'package:sate_ai_devtools/src/widgets/metrics_display.dart';
import 'package:sate_ai_devtools/src/widgets/report_viewer.dart';

class SateAIScreen extends StatefulWidget {
  const SateAIScreen({super.key});

  @override
  State<SateAIScreen> createState() => _SateAIScreenState();
}

class _SateAIScreenState extends State<SateAIScreen> {
  StressReport? _lastReport;
  bool _isRunning = false;
  double _progress = 0.0;
  final List<String> _logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f1117),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  '🧪 SATE AI Stress Testing',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _isRunning
                        ? Colors.amber.withOpacity(0.2)
                        : _lastReport != null
                            ? _lastReport!.passed
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isRunning
                          ? Colors.amber
                          : _lastReport != null
                              ? _lastReport!.passed
                                  ? Colors.green
                                  : Colors.red
                              : Colors.grey,
                    ),
                  ),
                  child: Text(
                    _isRunning
                        ? 'Running...'
                        : _lastReport != null
                            ? _lastReport!.passed
                                ? 'PASSED'
                                : 'FAILED'
                            : 'Ready',
                    style: TextStyle(
                      color: _isRunning
                          ? Colors.amber
                          : _lastReport != null
                              ? _lastReport!.passed
                                  ? Colors.green
                                  : Colors.red
                              : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress Bar
            if (_isRunning) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.grey.shade800,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF60a5fa),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(_progress * 100).toInt()}% complete',
                style: const TextStyle(color: Color(0xFFa0a5b5)),
              ),
              const SizedBox(height: 12),
            ],

            // Two columns: Controls + Metrics
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Control Panel
                  Expanded(
                    flex: 1,
                    child: ControlPanel(
                      onRun: _runStressTest,
                      onSaveBaseline: _saveBaseline,
                      onCompareBaseline: _compareBaseline,
                      onClear: _clearResults,
                      isRunning: _isRunning,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Right: Metrics + Report
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        // Metrics
                        MetricsDisplay(report: _lastReport),
                        const SizedBox(height: 12),

                        // Report Viewer
                        Expanded(
                          child: ReportViewer(
                            report: _lastReport,
                            logs: _logs,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runStressTest() async {
    setState(() {
      _isRunning = true;
      _progress = 0.0;
      _logs.clear();
      _logs.add('🚀 Starting stress test...');
    });

    try {
      final model = MockAdapter(modelId: 'devtools-test');

      final injectors = [
        MemoryPressureInjector(model: model, limitMb: 150),
        MalformedInputInjector(),
      ];

      final runner = StressRunner(
        model: model,
        injectors: injectors,
        timeout: const Duration(seconds: 30),
      );

      for (var i = 0; i < 10; i++) {
        await Future.delayed(Duration(milliseconds: 50 + i * 20));
        if (mounted) {
          setState(() {
            _progress = (i + 1) / 10;
            _logs.add('⚙️ Running injector ${i + 1}/10...');
          });
        }
      }

      final report = await runner.run();

      if (mounted) {
        setState(() {
          _lastReport = report;
          _isRunning = false;
          _progress = 1.0;
          _logs.add('✅ Test completed!');
          if (report.passed) {
            _logs.add('✅ All tests passed!');
          } else {
            _logs.add('❌ ${report.failures.length} failures detected.');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _logs.add('❌ Error: $e');
        });
      }
    }
  }

  Future<void> _saveBaseline() async {
    if (_lastReport == null) {
      setState(() {
        _logs.add('⚠️ No report to save as baseline.');
      });
      return;
    }
    final manager = BaselineManager();
    final path = await manager.saveBaseline(_lastReport!);
    setState(() {
      _logs.add('✅ Baseline saved to: $path');
    });
  }

  Future<void> _compareBaseline() async {
    if (_lastReport == null) {
      setState(() {
        _logs.add('⚠️ No report to compare.');
      });
      return;
    }
    final manager = BaselineManager();
    final comparison = await manager.checkAgainstBaseline(_lastReport!);
    setState(() {
      if (comparison == null) {
        _logs.add('ℹ️ No baseline found. Saved as baseline.');
      } else if (comparison.passed) {
        _logs.add('✅ Baseline comparison passed! No regressions.');
      } else {
        _logs.add('❌ Baseline comparison failed! Regressions detected.');
      }
    });
  }

  void _clearResults() {
    setState(() {
      _lastReport = null;
      _logs.clear();
      _logs.add('🧹 Cleared results.');
    });
  }
}
