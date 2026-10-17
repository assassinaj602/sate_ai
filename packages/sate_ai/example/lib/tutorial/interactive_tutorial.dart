import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sate_ai/sate_ai.dart';

import '../main.dart' show AdapterType;

/// Configuration generated or modified during the interactive tutorial.
class TutorialConfiguration {
  /// The chosen model adapter.
  final AdapterType adapter;

  /// Whether MemoryPressureInjector is active.
  final bool useMemoryPressure;

  /// Whether MalformedInputInjector is active.
  final bool useMalformedInput;

  /// Whether ThermalThrottleInjector is active.
  final bool useThermalThrottle;

  /// Whether QuantizationDriftInjector is active.
  final bool useQuantizationDrift;

  /// Whether ConfidenceValidationInjector is active.
  final bool useConfidenceValidation;

  /// Whether AdaptiveChaosInjector is active.
  final bool useAdaptiveChaos;

  /// Creates a [TutorialConfiguration].
  const TutorialConfiguration({
    this.adapter = AdapterType.mock,
    this.useMemoryPressure = true,
    this.useMalformedInput = true,
    this.useThermalThrottle = true,
    this.useQuantizationDrift = true,
    this.useConfidenceValidation = true,
    this.useAdaptiveChaos = false,
  });

  /// Creates a copy with optional updated fields.
  TutorialConfiguration copyWith({
    AdapterType? adapter,
    bool? useMemoryPressure,
    bool? useMalformedInput,
    bool? useThermalThrottle,
    bool? useQuantizationDrift,
    bool? useConfidenceValidation,
    bool? useAdaptiveChaos,
  }) {
    return TutorialConfiguration(
      adapter: adapter ?? this.adapter,
      useMemoryPressure: useMemoryPressure ?? this.useMemoryPressure,
      useMalformedInput: useMalformedInput ?? this.useMalformedInput,
      useThermalThrottle: useThermalThrottle ?? this.useThermalThrottle,
      useQuantizationDrift: useQuantizationDrift ?? this.useQuantizationDrift,
      useConfidenceValidation:
          useConfidenceValidation ?? this.useConfidenceValidation,
      useAdaptiveChaos: useAdaptiveChaos ?? this.useAdaptiveChaos,
    );
  }
}

/// A dialog presenting a 5-step interactive onboarding tutorial for SATE AI.
class InteractiveTutorialDialog extends StatefulWidget {
  /// Initial configuration passed from the dashboard.
  final TutorialConfiguration initialConfiguration;

  /// Callback when user completes or applies the tutorial configuration.
  final void Function(TutorialConfiguration config)? onApplyConfiguration;

  /// Creates an [InteractiveTutorialDialog].
  const InteractiveTutorialDialog({
    super.key,
    this.initialConfiguration = const TutorialConfiguration(),
    this.onApplyConfiguration,
  });

  /// Displays the interactive tutorial in a dialog.
  static Future<void> show(
    BuildContext context, {
    TutorialConfiguration initialConfig = const TutorialConfiguration(),
    void Function(TutorialConfiguration config)? onApply,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => InteractiveTutorialDialog(
        initialConfiguration: initialConfig,
        onApplyConfiguration: onApply,
      ),
    );
  }

  @override
  State<InteractiveTutorialDialog> createState() =>
      _InteractiveTutorialDialogState();
}

class _InteractiveTutorialDialogState extends State<InteractiveTutorialDialog> {
  int _currentStep = 0;
  late TutorialConfiguration _config;

  // Step 1 interactive state: selected installation platform
  String _selectedPlatform = 'Flutter';

  // Step 2 interactive state: baseline probe response
  String? _probeStatus;
  int? _probeLatencyMs;
  bool _isProbing = false;

  // Step 4 interactive state: custom adapter template kind
  String _selectedAdapterTemplate = 'Vision';

  // Step 5 interactive state: simulated report pass state
  bool _simulatedReportPassed = true;

  @override
  void initState() {
    super.initState();
    _config = widget.initialConfiguration;
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      _finishTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  void _finishTutorial() {
    widget.onApplyConfiguration?.call(_config);
    Navigator.of(context).pop();
  }

  Future<void> _runBaselineProbe() async {
    setState(() {
      _isProbing = true;
      _probeStatus = 'Running baseline inference probe...';
    });

    final stopwatch = Stopwatch()..start();
    final model = MockAdapter(
      modelId: 'tutorial-${_config.adapter.name}-model',
      inferenceDelay: const Duration(milliseconds: 120),
    );

    try {
      final input = AIInput(
        text: 'Tutorial baseline test prompt',
        metadata: {'channel': 'tutorial_probe'},
      );
      final output = await model.runInference(input);
      stopwatch.stop();

      if (mounted) {
        setState(() {
          _isProbing = false;
          _probeLatencyMs = stopwatch.elapsedMilliseconds;
          final conf = output.confidence != null
              ? ' | Conf: ${(output.confidence! * 100).toStringAsFixed(0)}%'
              : '';
          _probeStatus =
              'Success! Response: "${output.text}"$conf | Latency: ${_probeLatencyMs}ms';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProbing = false;
          _probeStatus = 'Probe error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF131326),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressBar(),
            _buildStepChips(),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E38),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF48CAE4)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SATE AI Guided Tutorial',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Learn on-device AI fault injection and resilience testing',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close Tutorial',
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_currentStep + 1) / 5;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: const Color(0xFF25254B),
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
      minHeight: 3,
    );
  }

  Widget _buildStepChips() {
    final titles = [
      '1. Installation',
      '2. Basic Test',
      '3. Injectors',
      '4. Custom Adapters',
      '5. Reports',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFF181830),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(5, (index) {
            final isSelected = _currentStep == index;
            final isCompleted = _currentStep > index;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCompleted)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.check_circle,
                            size: 14, color: Color(0xFF48CAE4)),
                      ),
                    Text(
                      titles[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isCompleted
                                ? const Color(0xFF48CAE4)
                                : Colors.white60),
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF6C63FF).withValues(alpha: 0.35),
                backgroundColor: const Color(0xFF222244),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : (isCompleted
                            ? const Color(0xFF48CAE4)
                            : Colors.white12),
                  ),
                ),
                onSelected: (_) => setState(() => _currentStep = index),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Installation();
      case 1:
        return _buildStep2BasicTest();
      case 2:
        return _buildStep3Injectors();
      case 3:
        return _buildStep4CustomAdapters();
      case 4:
      default:
        return _buildStep5Reports();
    }
  }

  // STEP 1: Installation & Architecture
  Widget _buildStep1Installation() {
    final code = _selectedPlatform == 'Flutter'
        ? '''# pubspec.yaml
dependencies:
  sate_ai: ^0.11.0

# Install via terminal
flutter pub get'''
        : _selectedPlatform == 'CLI'
            ? '''# Pure Dart CLI (No Flutter required)
dart pub global activate sate_cli

# Run stress tests anywhere
sate_ai --model model.gguf --injectors memoryPressure'''
            : _selectedPlatform == 'Android'
                ? '''// build.gradle.kts (Kotlin/Android Native)
dependencies {
    implementation("io.github.assassinaj602:sate-android:0.1.0")
}'''
                : '''// package.json (TypeScript / Web / Node.js)
npm install @sate-ai/core @sate-ai/tfjs''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          Icons.download,
          'Step 1: Installation and Architecture',
          'SATE AI provides modular libraries for Flutter, CLI, Android, and Web environments.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Choose your target platform to view the quick installation syntax:',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: ['Flutter', 'CLI', 'Android', 'Web'].map((platform) {
            final isSel = _selectedPlatform == platform;
            return ChoiceChip(
              label: Text(platform),
              selected: isSel,
              selectedColor: const Color(0xFF6C63FF),
              onSelected: (_) => setState(() => _selectedPlatform = platform),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _buildCodeBlock(code),
        const SizedBox(height: 16),
        _buildKeyPointsCard([
          'sate_core: Framework-agnostic pure Dart engine (injectors, models, reports).',
          'sate_ai: Flutter package adding UI monitors, DevTools, and native adapters.',
          'sate_cli: Zero-dependency Dart executable for CI/CD automation pipelines.',
        ]),
      ],
    );
  }

  // STEP 2: Basic Test
  Widget _buildStep2BasicTest() {
    final code = '''import 'package:sate_ai/sate_ai.dart';

void main() async {
  // 1. Choose or initialize your model adapter
  final model = MockAdapter(
    modelId: '${_config.adapter.name}-model',
    inferenceDelay: const Duration(milliseconds: 150),
  );

  // 2. Run stress suite with retry policies
  final report = await SateAI.stress(
    model: model,
    injectors: [
      MemoryPressureInjector(limitMb: 120),
      MalformedInputInjector(),
    ],
    timeout: const Duration(seconds: 15),
  );

  print('Report passed: \${report.passed}');
}''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          Icons.play_circle_outline,
          'Step 2: Basic Stress Test Execution',
          'Execute your first on-device fault injection test suite against a model adapter.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Select an adapter for your baseline run:',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: AdapterType.values.map((type) {
            final isSelected = _config.adapter == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(type.name.toUpperCase()),
                selected: isSelected,
                selectedColor: const Color(0xFF6C63FF),
                onSelected: (_) {
                  setState(() {
                    _config = _config.copyWith(adapter: type);
                  });
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _buildCodeBlock(code),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Interactive Live Probe:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isProbing ? null : _runBaselineProbe,
                    icon: _isProbing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bolt, size: 16),
                    label: const Text('Run Baseline Probe'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              if (_probeStatus != null) ...[
                const SizedBox(height: 8),
                Text(
                  _probeStatus!,
                  style: TextStyle(
                    color: _probeStatus!.startsWith('Success')
                        ? const Color(0xFF48CAE4)
                        : Colors.orangeAccent,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // STEP 3: Adding & Configuring Fault Injectors
  Widget _buildStep3Injectors() {
    final activeCount = [
      _config.useMemoryPressure,
      _config.useMalformedInput,
      _config.useThermalThrottle,
      _config.useQuantizationDrift,
      _config.useConfidenceValidation,
      _config.useAdaptiveChaos,
    ].where((x) => x).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          Icons.tune,
          'Step 3: Configuring Fault Injectors',
          'SATE AI provides specialized injectors to simulate hardware limits and chaotic edge conditions.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Select injectors to include in your stress test configuration:',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _buildInjectorCheckbox(
          title: 'MemoryPressureInjector',
          subtitle:
              'Simulates RAM exhaustion up to a target limit (e.g. 150 MB)',
          value: _config.useMemoryPressure,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(useMemoryPressure: v ?? false)),
        ),
        _buildInjectorCheckbox(
          title: 'MalformedInputInjector',
          subtitle:
              'Injects corrupted floats, NaNs, and unexpected tensor shapes',
          value: _config.useMalformedInput,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(useMalformedInput: v ?? false)),
        ),
        _buildInjectorCheckbox(
          title: 'ThermalThrottleInjector',
          subtitle:
              'Simulates thermal elevation and CPU frequency down-clocking',
          value: _config.useThermalThrottle,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(useThermalThrottle: v ?? false)),
        ),
        _buildInjectorCheckbox(
          title: 'QuantizationDriftInjector',
          subtitle:
              'Simulates INT8/FP16 quantization loss and drift degradation',
          value: _config.useQuantizationDrift,
          onChanged: (v) => setState(() =>
              _config = _config.copyWith(useQuantizationDrift: v ?? false)),
        ),
        _buildInjectorCheckbox(
          title: 'ConfidenceThresholdInjector',
          subtitle:
              'Validates inference confidence does not drop below threshold',
          value: _config.useConfidenceValidation,
          onChanged: (v) => setState(() =>
              _config = _config.copyWith(useConfidenceValidation: v ?? false)),
        ),
        _buildInjectorCheckbox(
          title: 'AdaptiveChaosInjector',
          subtitle:
              'Dynamically modulates pacing and memory based on live OS telemetry',
          value: _config.useAdaptiveChaos,
          onChanged: (v) => setState(
              () => _config = _config.copyWith(useAdaptiveChaos: v ?? false)),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFF48CAE4).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF48CAE4), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Configured $activeCount active injector(s). When applied, the dashboard will immediately reflect this set.',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInjectorCheckbox({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF1B1B34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: value ? const Color(0xFF6C63FF) : Colors.white12,
          ),
        ),
        child: CheckboxListTile(
          value: value,
          onChanged: onChanged,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          activeColor: const Color(0xFF6C63FF),
          dense: true,
        ),
      ),
    );
  }

  // STEP 4: Creating Custom Adapters
  Widget _buildStep4CustomAdapters() {
    final code = _selectedAdapterTemplate == 'Vision'
        ? '''class MyCustomVisionAdapter implements AIModelAdapter {
  @override
  final String modelId = 'custom-mobilenet-v3';

  @override
  bool isDegraded = false;

  @override
  double currentMemoryMB = 45.0;

  @override
  double currentGPUMemoryMB = 0.0;

  @override
  Future<AIOutput> runInference(AIInput input) async {
    // 1. Run inference on native runtime
    final result = await executeNativeVisionPipeline(input.binary ?? []);
    
    // 2. Return standard AIOutput with confidence score
    return AIOutput(
      text: result.label,
      confidence: 0.94,
      inferenceTime: const Duration(milliseconds: 28),
    );
  }

  @override
  Future<void> simulateMemoryPressure(int mb) async => currentMemoryMB += mb;

  @override
  Future<void> simulateGPUMemoryPressure(int mb) async => currentGPUMemoryMB += mb;

  @override
  Future<void> reset() async => isDegraded = false;

  @override
  Future<bool> isHealthy() async => !isDegraded;
}'''
        : '''class MyCustomLLMAdapter implements AIModelAdapter {
  @override
  final String modelId = 'on-device-llama-3b';

  @override
  bool isDegraded = false;

  @override
  double currentMemoryMB = 1200.0;

  @override
  double currentGPUMemoryMB = 512.0;

  @override
  Future<AIOutput> runInference(AIInput input) async {
    final prompt = input.text ?? '';
    final responseText = await llamaCppRun(prompt);

    return AIOutput(
      text: responseText,
      confidence: 0.88,
      inferenceTime: const Duration(milliseconds: 320),
    );
  }

  @override
  Future<void> simulateMemoryPressure(int mb) async => currentMemoryMB += mb;

  @override
  Future<void> simulateGPUMemoryPressure(int mb) async => currentGPUMemoryMB += mb;

  @override
  Future<void> reset() async => isDegraded = false;

  @override
  Future<bool> isHealthy() async => !isDegraded;
}''';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          Icons.extension,
          'Step 4: Implementing Custom Adapters',
          'Wrap any runtime (ONNX, TFLite, Core ML, MediaPipe, Fllama, or custom C++ engine).',
        ),
        const SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const Text(
              'Adapter Template:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            ChoiceChip(
              label: const Text('Vision / Classification'),
              selected: _selectedAdapterTemplate == 'Vision',
              selectedColor: const Color(0xFF6C63FF),
              onSelected: (_) =>
                  setState(() => _selectedAdapterTemplate = 'Vision'),
            ),
            ChoiceChip(
              label: const Text('LLM / Generative'),
              selected: _selectedAdapterTemplate == 'LLM',
              selectedColor: const Color(0xFF6C63FF),
              onSelected: (_) =>
                  setState(() => _selectedAdapterTemplate = 'LLM'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildCodeBlock(code),
        const SizedBox(height: 14),
        _buildKeyPointsCard([
          'Implement AIModelAdapter to integrate proprietary models into SATE AI.',
          'Injectors automatically observe and modify isDegraded, currentMemoryMB, and latency.',
          'Supports pure Dart MockAdapter for CI and unit test suites.',
        ]),
      ],
    );
  }

  // STEP 5: Analyzing Stress Reports & Telemetry
  Widget _buildStep5Reports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          Icons.analytics,
          'Step 5: Analyzing Reports and Metrics',
          'Understand test outcomes, failure root causes, resource consumption, and golden baselines.',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _simulatedReportPassed
                  ? const Color(0xFF48CAE4)
                  : Colors.redAccent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          _simulatedReportPassed
                              ? Icons.check_circle
                              : Icons.error_outline,
                          color: _simulatedReportPassed
                              ? const Color(0xFF48CAE4)
                              : Colors.redAccent,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _simulatedReportPassed
                                ? 'STRESS REPORT: PASSED'
                                : 'STRESS REPORT: FAILED (REGRESSION)',
                            style: TextStyle(
                              color: _simulatedReportPassed
                                  ? const Color(0xFF48CAE4)
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _simulatedReportPassed = !_simulatedReportPassed;
                      });
                    },
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Toggle State'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Sample Metrics Preview:',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Expanded(
                    child: _MetricTile(
                      label: 'Pass Rate',
                      value: '100%',
                      subtitle: '5 of 5 tests',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      label: 'Avg Latency',
                      value: '42ms',
                      subtitle: 'p99: 98ms',
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: _MetricTile(
                      label: 'Peak Memory',
                      value: '160 MB',
                      subtitle: 'Headroom: 82%',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildKeyPointsCard([
          'Golden Baselines: Save a golden report via --baseline and detect performance regressions.',
          'Export formats: Export reports to Markdown, interactive HTML with Chart.js, or raw JSON.',
          'Pre-flight Cost Estimator: Run --estimate to predict duration, peak RAM, and battery drain.',
        ]),
      ],
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF48CAE4), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Color(0xFFE2E8F0),
                height: 1.4,
              ),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: IconButton(
              icon: const Icon(Icons.copy, size: 14, color: Colors.white54),
              tooltip: 'Copy Code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Code snippet copied to clipboard!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyPointsCard(List<String> points) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B34),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: points.map((p) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ',
                    style: TextStyle(color: Color(0xFF48CAE4), fontSize: 13)),
                Expanded(
                  child: Text(
                    p,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFF1E1E38),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentStep > 0 ? _previousStep : null,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
              disabledForegroundColor: Colors.white24,
            ),
          ),
          Text(
            'Step ${_currentStep + 1} of 5',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _finishTutorial,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF48CAE4),
                  side: const BorderSide(color: Color(0xFF48CAE4)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: const Text('Apply to Dashboard'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _nextStep,
                icon: Icon(
                  _currentStep == 4 ? Icons.check : Icons.arrow_forward,
                  size: 16,
                ),
                label: Text(_currentStep == 4 ? 'Finish' : 'Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF121224),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: Color(0xFF48CAE4), fontSize: 9)),
        ],
      ),
    );
  }
}
