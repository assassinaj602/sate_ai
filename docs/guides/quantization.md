# Model Quantization Analyzer Guide

SATE AI provides a lightweight, pure-Dart static quantization analyzer for ONNX and TFLite models. It inspects model binary signatures and header metadata to detect layer precision levels and flag potential precision issues before running stress tests.

## Key Features

- **Zero Native Dependencies**: Pure Dart byte stream parsing for ONNX Protobuf and TFLite FlatBuffers.
- **Precision Detection**: Identifies `float32`, `float16`, `int8`, `uint8`, and `int16` layers.
- **Warning System**: Flags aggressive quantization (`int8`, `uint8`, `int16`) that may cause precision/accuracy degradation on sensitive layers.
- **Markdown & JSON Reports**: Generates structured reports with layer details, total model size, and dominant precision.

## Dart API Usage

```dart
import 'dart:io';
import 'package:sate_ai/sate_ai.dart';

void main() async {
  final modelFile = File('models/mobilenet.tflite');
  
  // Analyze quantization
  final report = await QuantizationAnalyzer.analyzeFile(modelFile);
  
  print('Format: ${report.format}');
  print('Dominant Precision: ${report.dominantPrecision.name}');
  print('Quantized Layers: ${report.quantizedLayerCount}');
  print('Warnings: ${report.warningCount}');

  // Export to Markdown
  print(report.toMarkdown());
}
```

## CLI Usage

Analyze quantization directly from the command line:

```bash
# Analyze ONNX or TFLite model and print Markdown report
sate_ai --analyze-quantization path/to/model.tflite --markdown

# Export analysis report to a file
sate_ai --analyze-quantization path/to/model.onnx --quant-output report.md --markdown
```
