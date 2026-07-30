import 'dart:io';
import 'package:args/args.dart';
import 'package:sate_ai/sate_ai.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('model',
        abbr: 'm',
        help: 'Path to the model file (e.g., model.gguf)',
        mandatory: true)
    ..addOption('injectors',
        abbr: 'i',
        help: 'Comma-separated list of injectors to use',
        defaultsTo: 'memoryPressure,malformedInput')
    ..addOption('output',
        abbr: 'o', help: 'Output file path for the report (JSON or Markdown)')
    ..addFlag('markdown',
        abbr: 'md', help: 'Output in Markdown format (instead of JSON)')
    ..addOption('timeout',
        abbr: 't', help: 'Timeout in seconds for each test', defaultsTo: '30')
    ..addFlag('help', abbr: 'h', help: 'Show this help', negatable: false);

  try {
    final results = parser.parse(arguments);
    if (results['help'] as bool) {
      print('SATE AI CLI - Run stress tests on your AI model');
      print('');
      print(parser.usage);
      exit(0);
    }

    final modelPath = results['model'] as String;
    final injectorsStr = results['injectors'] as String;
    final timeoutSeconds = int.parse(results['timeout'] as String);
    final outputFile = results['output'] as String?;
    final useMarkdown = results['markdown'] as bool;

    // Parse injectors
    final injectorNames = injectorsStr.split(',').map((s) => s.trim()).toList();
    final injectors = <FaultInjector>[];

    // Load model adapter (for now we use MockAdapter in CLI, but we can extend later)
    final model = MockAdapter(modelId: modelPath);

    // Build injectors from names
    for (final name in injectorNames) {
      switch (name.toLowerCase()) {
        case 'memorypressure':
          injectors.add(MemoryPressureInjector(model: model, limitMb: 150));
          break;
        case 'malformedinput':
          injectors.add(MalformedInputInjector());
          break;
        case 'quantizationdrift':
          injectors.add(QuantizationDriftInjector(model: model));
          break;
        case 'thermalthrottle':
          injectors.add(ThermalThrottleInjector(model: model));
          break;
        case 'latency':
          injectors.add(LatencyInjector(model: model));
          break;
        case 'modelswap':
          injectors.add(ModelSwapInjector(model: model));
          break;
        default:
          print('Unknown injector: $name');
          exit(1);
      }
    }

    print(
        'Running stress test with injectors: ${injectors.map((i) => i.name).join(', ')}');

    // Run the test
    final report = await SateAI.stress(
      model: model,
      injectors: injectors,
      timeout: Duration(seconds: timeoutSeconds),
    );

    // Output
    if (outputFile != null) {
      final content = useMarkdown ? report.toMarkdown() : report.toJsonString();
      await File(outputFile).writeAsString(content);
      print('Report written to $outputFile');
    } else {
      if (useMarkdown) {
        print(report.toMarkdown());
      } else {
        print(report.toJsonString());
      }
    }

    // Exit with appropriate code
    exit(report.passed ? 0 : 1);
  } on FormatException catch (e) {
    print('Error parsing arguments: ${e.message}');
    print('');
    print(parser.usage);
    exit(1);
  }
}
