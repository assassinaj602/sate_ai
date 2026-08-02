import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sate_ai/sate_ai.dart';

void main() => runApp(const SateAIApp());

enum AdapterType { mock, onnx, tflite }

class SateAIApp extends StatelessWidget {
  const SateAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SATE AI Real-World Stress Test Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const StressDashboard(),
    );
  }
}

class StressDashboard extends StatefulWidget {
  const StressDashboard({super.key});

  @override
  State<StressDashboard> createState() => _StressDashboardState();
}

class _StressDashboardState extends State<StressDashboard>
    with TickerProviderStateMixin {
  AdapterType _selectedAdapter = AdapterType.mock;
  StressReport? _report;
  bool _running = false;
  String _status = 'Ready';
  final List<String> _log = [];
  late AnimationController _pulseCtrl;

  // Selected injectors
  bool _useMemoryPressure = true;
  bool _useMalformedInput = true;
  bool _useThermalThrottle = true;
  bool _useQuantizationDrift = true;
  bool _useConfidenceValidation = true;

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

  Future<AIModelAdapter> _createAdapter() async {
    switch (_selectedAdapter) {
      case AdapterType.mock:
        return MockAdapter(
          modelId: 'mock-llm-v1',
          inferenceDelay: const Duration(milliseconds: 150),
        );

      case AdapterType.onnx:
        _appendLog('📦 Attempting to initialize OnnxAdapter (assets/models/mobilenet.onnx)...');
        try {
          final bytes = await rootBundle.load('assets/models/mobilenet.onnx');
          return OnnxAdapter(
            modelId: 'onnx-mobilenet-v2',
            modelBytes: bytes.buffer.asUint8List(),
          );
        } catch (e) {
          _appendLog('⚠️ ONNX init fallback to Mock: $e');
          return MockAdapter(modelId: 'onnx-fallback-mock');
        }

      case AdapterType.tflite:
        _appendLog('📦 Attempting to initialize TFLiteAdapter (assets/models/mobilenet.tflite)...');
        try {
          return await TFLiteAdapter.fromAsset(
            'assets/models/mobilenet.tflite',
            modelId: 'tflite-mobilenet-v1',
          );
        } catch (e) {
          _appendLog('⚠️ TFLite init fallback to Mock: $e');
          return MockAdapter(modelId: 'tflite-fallback-mock');
        }
    }
  }

  Future<void> _runStressTest() async {
    setState(() {
      _running = true;
      _report = null;
      _log.clear();
      _status = 'Initialising selected model adapter...';
    });

    _appendLog('🤖 Selected Adapter: ${_selectedAdapter.name.toUpperCase()}');
    final model = await _createAdapter();
    _appendLog('✅ Model initialized: ${model.modelId}');

    final List<FaultInjector> injectors = [];

    if (_useMemoryPressure) {
      injectors.add(MemoryPressureInjector(model: model, limitMb: 120));
      _appendLog('⚙️ Configured MemoryPressureInjector (120 MB)');
    }
    if (_useMalformedInput) {
      injectors.add(const MalformedInputInjector());
      _appendLog('⚙️ Configured MalformedInputInjector');
    }
    if (_useThermalThrottle) {
      injectors.add(
        ThermalThrottleInjector(
          model: model,
          temperatureStep: 15,
          maxTemperature: 80,
        ),
      );
      _appendLog('⚙️ Configured ThermalThrottleInjector (Max 80°C)');
    }
    if (_useQuantizationDrift) {
      injectors.add(
        QuantizationDriftInjector(
          model: model,
          driftFactor: 0.1,
          degradationThreshold: 0.3,
        ),
      );
      _appendLog('⚙️ Configured QuantizationDriftInjector');
    }
    if (_useConfidenceValidation) {
      injectors.add(ConfidenceThresholdInjector(model: model, threshold: 0.6));
      _appendLog('⚙️ Configured ConfidenceThresholdInjector (0.6)');
    }

    if (injectors.isEmpty) {
      _appendLog('⚠️ No injectors selected. Adding default MalformedInputInjector.');
      injectors.add(const MalformedInputInjector());
    }

    setState(() => _status = 'Running SateAI.stress() runner...');
    _appendLog('🧪 Starting stress runner evaluation (${injectors.length} injectors)...');

    final report = await SateAI.stress(
      model: model,
      injectors: injectors,
      timeout: const Duration(seconds: 30),
    );

    for (final result in report.results) {
      final icon = result.passed ? '✅' : '❌';
      final timeMs = result.inferenceTime?.inMilliseconds ?? 0;
      _appendLog(
        '$icon ${result.injectorType.displayName}: ${timeMs}ms '
        '${result.memoryUsageMB != null ? "(${result.memoryUsageMB}MB)" : ""}',
      );
    }

    setState(() {
      _running = false;
      _report = report;
      _status = report.passed
          ? '✅ Stress Suite Passed (${report.passCount}/${report.totalTests})'
          : '❌ Failures Detected (${report.failureCount} failed)';
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
              'SATE AI Stress Test Demo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAdapterSelector(),
            const SizedBox(height: 12),
            _buildInjectorToggles(),
            const SizedBox(height: 12),
            _buildStatusCard(cs),
            const SizedBox(height: 12),
            _buildRunButton(cs),
            const SizedBox(height: 12),
            if (_report != null) ...[
              _buildSummaryCard(_report!),
              const SizedBox(height: 12),
            ],
            Expanded(child: _buildLogCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildAdapterSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SELECT MODEL ADAPTER',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: AdapterType.values.map((type) {
              final isSelected = _selectedAdapter == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        type.name.toUpperCase(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF6C63FF),
                    backgroundColor: const Color(0xFF0F0F1A),
                    onSelected: (val) {
                      if (val) setState(() => _selectedAdapter = type);
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInjectorToggles() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONFIGURED INJECTORS',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              FilterChip(
                label: const Text('Memory Pressure', style: TextStyle(fontSize: 11)),
                selected: _useMemoryPressure,
                onSelected: (v) => setState(() => _useMemoryPressure = v),
              ),
              FilterChip(
                label: const Text('Malformed Input', style: TextStyle(fontSize: 11)),
                selected: _useMalformedInput,
                onSelected: (v) => setState(() => _useMalformedInput = v),
              ),
              FilterChip(
                label: const Text('Thermal Throttle', style: TextStyle(fontSize: 11)),
                selected: _useThermalThrottle,
                onSelected: (v) => setState(() => _useThermalThrottle = v),
              ),
              FilterChip(
                label: const Text('Quantization Drift', style: TextStyle(fontSize: 11)),
                selected: _useQuantizationDrift,
                onSelected: (v) => setState(() => _useQuantizationDrift = v),
              ),
              FilterChip(
                label: const Text('Confidence Threshold', style: TextStyle(fontSize: 11)),
                selected: _useConfidenceValidation,
                onSelected: (v) => setState(() => _useConfidenceValidation = v),
              ),
            ],
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _running
                  ? color.withAlpha(((_pulseCtrl.value * 180 + 75).round()))
                  : color.withAlpha(80),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              _running
                  ? SizedBox(
                      width: 18,
                      height: 18,
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
                      size: 20,
                    ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _status,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: _running
              ? const LinearGradient(
                  colors: [Color(0xFF3A3A5C), Color(0xFF2A2A4A)],
                )
              : const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
                ),
          borderRadius: BorderRadius.circular(14),
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
                _running ? 'Running Suite...' : 'Execute Stress Suite',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(StressReport report) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatChip(label: 'Total', value: '${report.totalTests}', color: const Color(0xFF48CAE4)),
          _StatChip(label: 'Passed', value: '${report.passCount}', color: const Color(0xFF06D6A0)),
          _StatChip(label: 'Failed', value: '${report.failureCount}', color: const Color(0xFFEF476F)),
          _StatChip(label: 'Duration', value: '${report.totalDuration.inMilliseconds}ms', color: const Color(0xFFFFD166)),
        ],
      ),
    );
  }

  Widget _buildLogCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Text(
              'EXECUTION LOG',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: _log.isEmpty
                ? const Center(
                    child: Text(
                      'Select an adapter and hit "Execute Stress Suite"',
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
                    itemCount: _log.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _log[i],
                        style: const TextStyle(
                          color: Color(0xFFB0B8D8),
                          fontFamily: 'monospace',
                          fontSize: 12,
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
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
