// ignore_for_file: avoid_print, prefer_const_constructors
import 'dart:io';
import 'package:args/args.dart';
import 'package:sate_ai/sate_ai_cli.dart';

import 'sse_server.dart';

void log(String message) {
  print(message);
}

List<FaultInjector> _buildInjectors(ArgResults results, AIModelAdapter model) {
  final injectorsStr = results['injectors'] as String;
  final injectorNames = injectorsStr.split(',').map((s) => s.trim()).toList();
  final injectors = <FaultInjector>[];

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
      case 'confidencevalidation':
        injectors
            .add(ConfidenceThresholdInjector(model: model, threshold: 0.5));
        break;
      default:
        log('Unknown injector: $name');
        exit(1);
    }
  }
  return injectors;
}

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('model',
        abbr: 'm',
        help: 'Path to the model file (e.g., model.gguf)',
        defaultsTo: 'cli-model')
    ..addOption('injectors',
        abbr: 'i',
        help: 'Comma-separated list of injectors to use',
        defaultsTo: 'memoryPressure,malformedInput')
    ..addOption('output',
        abbr: 'o', help: 'Output file path for the report (JSON or Markdown)')
    ..addFlag('markdown', help: 'Output in Markdown format (instead of JSON)')
    ..addFlag('html',
        help: 'Output in HTML format (generates a self-contained HTML page)')
    ..addFlag('serve', help: 'Start the real-time monitoring server (SSE)')
    ..addOption('port',
        abbr: 'p',
        help: 'Port for the SSE server (default: 8080)',
        defaultsTo: '8080')
    ..addOption('schedule',
        help:
            'Cron expression for scheduling automated tests (e.g., "0 2 * * *" for daily at 2am)')
    ..addOption('report-dir',
        help: 'Directory to store scheduled test reports',
        defaultsTo: 'stress_reports')
    ..addFlag('baseline', help: 'Save the current report as a golden baseline')
    ..addFlag('compare',
        help: 'Compare the current report against the golden baseline')
    ..addOption('tolerance',
        abbr: 'tol',
        help: 'Tolerance percentage for baseline comparison',
        defaultsTo: '10.0')
    ..addOption('timeout',
        abbr: 't', help: 'Timeout in seconds for each test', defaultsTo: '30')
    ..addFlag('help', abbr: 'h', help: 'Show this help', negatable: false);

  try {
    final results = parser.parse(arguments);
    if (results['help'] as bool) {
      log('SATE AI CLI - Run stress tests on your AI model');
      log('');
      log(parser.usage);
      exit(0);
    }

    if (results['serve'] as bool) {
      final port = int.parse(results['port'] as String);
      final server = SSEServer(port: port);
      await server.start();
      print('Press Ctrl+C to stop...');
      await ProcessSignal.sigint.watch().first;
      await server.close();
      return;
    }

    if (results['schedule'] != null) {
      final schedule = results['schedule'] as String;
      final reportDir = results['report-dir'] as String;
      final timeoutSeconds = int.parse(results['timeout'] as String);

      final model = MockAdapter(modelId: 'scheduled-model');
      final injectors = _buildInjectors(results, model);

      final scheduler = StressScheduler(
        cronExpression: schedule,
        model: model,
        injectors: injectors,
        timeout: Duration(seconds: timeoutSeconds),
        reportDirectory: reportDir,
      );

      await scheduler.start();
      print('Press Ctrl+C to stop scheduler...');
      await ProcessSignal.sigint.watch().first;
      scheduler.stop();
      return;
    }

    final timeoutSeconds = int.parse(results['timeout'] as String);
    final outputFile = results['output'] as String?;
    final useMarkdown = results['markdown'] as bool;
    final useHtml = results['html'] as bool;

    final model = MockAdapter(modelId: 'cli-model');
    final injectors = _buildInjectors(results, model);

    log('Running stress test with injectors: ${injectors.map((i) => i.name).join(', ')}');

    final report = await SateAI.stress(
      model: model,
      injectors: injectors,
      timeout: Duration(seconds: timeoutSeconds),
    );

    if (outputFile != null) {
      final content = useMarkdown
          ? report.toMarkdown()
          : useHtml
              ? report.toHtml()
              : report.toJsonString();
      await File(outputFile).writeAsString(content);
      log('Report written to $outputFile');
    } else {
      if (useMarkdown) {
        log(report.toMarkdown());
      } else if (useHtml) {
        log(report.toHtml());
      } else {
        log(report.toJsonString());
      }
    }

    final saveBaseline = results['baseline'] as bool;
    final compareBaseline = results['compare'] as bool;
    final tolerance = double.parse(results['tolerance'] as String);

    final baselineManager = BaselineManager(tolerancePercent: tolerance);

    if (saveBaseline) {
      final path = await baselineManager.saveBaseline(report);
      log('✅ Baseline saved to: $path');
    }

    if (compareBaseline) {
      final comparison = await baselineManager.checkAgainstBaseline(report);
      if (comparison == null) {
        log('ℹ️ No baseline found. Saved current report as baseline.');
      } else {
        if (comparison.passed) {
          log('✅ Baseline comparison passed. No regressions detected.');
        } else {
          log('❌ Baseline comparison failed. Regressions detected!');
          log('');
          log(comparison.toMarkdown());
          exit(1);
        }
      }
    }

    exit(report.passed ? 0 : 1);
  } on FormatException catch (e) {
    log('Error parsing arguments: ${e.message}');
    log('');
    log(parser.usage);
    exit(1);
  }
}
