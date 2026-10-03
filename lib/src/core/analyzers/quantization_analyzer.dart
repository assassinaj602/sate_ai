import 'dart:io';
import 'dart:typed_data';
import '../quantization_report.dart';
import 'onnx_analyzer.dart';
import 'tflite_analyzer.dart';

/// Facade for analyzing model quantization level and layer precision.
class QuantizationAnalyzer {
  /// Analyzes model binary [bytes] with optional format override or auto-detection.
  static QuantizationReport analyzeBytes(
    Uint8List bytes, {
    String modelId = 'model',
    String? format,
  }) {
    final detectedFormat = (format ?? _detectFormat(bytes, modelId)).toLowerCase();

    if (detectedFormat == 'onnx' || modelId.toLowerCase().endsWith('.onnx')) {
      return OnnxQuantizationAnalyzer.analyze(bytes, modelId: modelId);
    } else if (detectedFormat == 'tflite' ||
        modelId.toLowerCase().endsWith('.tflite') ||
        TfliteQuantizationAnalyzer.hasTfliteMagic(bytes)) {
      return TfliteQuantizationAnalyzer.analyze(bytes, modelId: modelId);
    } else {
      // General/fallback analyzer
      return _analyzeFallback(bytes, modelId);
    }
  }

  /// Analyzes a local model [file].
  static Future<QuantizationReport> analyzeFile(File file, {String? format}) async {
    if (!await file.exists()) {
      throw FileSystemException('Model file does not exist', file.path);
    }

    final bytes = await file.readAsBytes();
    final modelId = file.path.split(Platform.pathSeparator).last;
    return analyzeBytes(bytes, modelId: modelId, format: format);
  }

  /// Auto-detects format from binary magic bytes or file extension heuristic.
  static String _detectFormat(Uint8List bytes, String modelId) {
    if (TfliteQuantizationAnalyzer.hasTfliteMagic(bytes)) {
      return 'tflite';
    }
    if (modelId.toLowerCase().endsWith('.onnx')) {
      return 'onnx';
    }
    if (modelId.toLowerCase().endsWith('.tflite')) {
      return 'tflite';
    }
    return 'unknown';
  }

  static QuantizationReport _analyzeFallback(Uint8List bytes, String modelId) {
    return QuantizationReport(
      modelId: modelId,
      format: 'unknown',
      layers: [
        QuantizedLayer(
          name: 'raw_bytes_layer',
          precision: QuantizationPrecision.unknown,
          sizeBytes: bytes.length,
          hasPrecisionWarning: false,
        ),
      ],
      totalSizeBytes: bytes.length,
    );
  }
}
