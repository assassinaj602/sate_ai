// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:sate_ai/sate_ai.dart';

void main() => runApp(const SateAIApp());

class SateAIApp extends StatelessWidget {
  const SateAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SATE AI Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'GoogleSans',
      ),
      home: const StressDashboard(),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard screen
// ---------------------------------------------------------------------------

class StressDashboard extends StatefulWidget {
  const StressDashboard({super.key});

  @override
  State<StressDashboard> createState() => _StressDashboardState();
}

class _StressDashboardState extends State<StressDashboard>
    with TickerProviderStateMixin {
  StressReport? _report;
  bool _running = false;
  String _status = 'Ready';
  final List<String> _log = [];
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _runStressTest() async {
    setState(() {
      _running = true;
      _report = null;
      _log.clear();
      _status = 'Initialising model…';
    });

    final model = MockAdapter(
      modelId: 'demo-llm-v1',
      inferenceDelay: const Duration(milliseconds: 200),
    );

    _appendLog('🤖  Model: ${model.modelId}');
    _appendLog('🧪  Starting stress test…');

    setState(() => _status = 'Injecting memory pressure…');
    _appendLog('⚙️   Running MemoryPressureInjector (100 MB)');

    setState(() => _status = 'Injecting malformed inputs…');
    _appendLog('⚙️   Running MalformedInputInjector');

    final report = await SateAI.stress(
      model: model,
      injectors: [
        MemoryPressureInjector(model: model, limitMb: 100),
        const MalformedInputInjector(),
      ],
      timeout: const Duration(seconds: 15),
    );

    for (final result in report.results) {
      final icon = result.passed ? '✅' : '❌';
      _appendLog(
        '$icon  ${result.injectorType.displayName}: '
        '${result.inferenceTime?.inMilliseconds ?? "N/A"} ms',
      );
    }

    setState(() {
      _running = false;
      _report = report;
      _status = report.passed ? '✅ All tests passed!' : '❌ Failures detected';
    });
  }

  void _appendLog(String line) => setState(() => _log.add(line));

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.science, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'SATE AI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(cs),
            const SizedBox(height: 16),
            _buildRunButton(cs),
            const SizedBox(height: 16),
            if (_report != null) ...[
              _buildSummaryCard(_report!, cs),
              const SizedBox(height: 16),
            ],
            Expanded(child: _buildLogCard(cs)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(ColorScheme cs) {
    final color = _running
        ? const Color(0xFF48CAE4)
        : (_report?.passed ?? true)
            ? const Color(0xFF06D6A0)
            : const Color(0xFFEF476F);

    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _running
                  ? color.withAlpha(
                      ((_pulseCtrl.value * 180 + 75).round()),
                    )
                  : color.withAlpha(80),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(_running ? 60 : 20),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              _running
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(
                      _report == null
                          ? Icons.pending_outlined
                          : (_report!.passed
                              ? Icons.check_circle
                              : Icons.error),
                      color: color,
                      size: 22,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRunButton(ColorScheme cs) {
    return GestureDetector(
      onTap: _running ? null : _runStressTest,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _running
              ? const LinearGradient(
                  colors: [Color(0xFF3A3A5C), Color(0xFF2A2A4A)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _running
              ? []
              : [
                  const BoxShadow(
                    color: Color(0x556C63FF),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _running ? Icons.hourglass_top : Icons.play_arrow_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Text(
                _running ? 'Running…' : 'Run Stress Test',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(StressReport report, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summary',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatChip(
                label: 'Tests',
                value: '${report.totalTests}',
                color: const Color(0xFF48CAE4),
              ),
              _StatChip(
                label: 'Passed',
                value: '${report.passCount}',
                color: const Color(0xFF06D6A0),
              ),
              _StatChip(
                label: 'Failed',
                value: '${report.failureCount}',
                color: const Color(0xFFEF476F),
              ),
              _StatChip(
                label: 'Duration',
                value: '${report.totalDuration.inMilliseconds}ms',
                color: const Color(0xFFFFD166),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'LOG',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: _log.isEmpty
                ? const Center(
                    child: Text(
                      'Hit "Run Stress Test" to begin',
                      style: TextStyle(color: Colors.white24, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    itemCount: _log.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(
                        _log[i],
                        style: const TextStyle(
                          color: Color(0xFFB0B8D8),
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
