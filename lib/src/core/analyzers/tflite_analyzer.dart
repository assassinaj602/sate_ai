import 'dart:typed_data';
import '../quantization_report.dart';

/// Lightweight pure-Dart TFLite model quantization analyzer.
///
/// Inspects raw FlatBuffer binary bytes without requiring native dependencies.
class TfliteQuantizationAnalyzer {
  /// Checks whether bytes contain the TFLite FlatBuffer magic signature ("TFL3").
  static bool hasTfliteMagic(Uint8List bytes) {
    if (bytes.length < 8) return false;
    return bytes[4] == 0x54 && // 'T'
        bytes[5] == 0x46 && // 'F'
        bytes[6] == 0x4C && // 'L'
        bytes[7] == 0x33; // '3'
  }

  /// Analyzes a TFLite model binary and returns a [QuantizationReport].
  static QuantizationReport analyze(Uint8List bytes,
      {String modelId = 'tflite_model'}) {
    final layers = <QuantizedLayer>[];

    if (bytes.length < 8) {
      return QuantizationReport(
        modelId: modelId,
        format: 'tflite',
        layers: [],
        totalSizeBytes: bytes.length,
      );
    }

    bool validMagic = hasTfliteMagic(bytes);

    // FlatBuffer TensorType enum scanning in binary offset stream:
    // 0 = FLOAT32
    // 1 = FLOAT16
    // 3 = UINT8
    // 7 = INT16
    // 9 = INT8

    int layerIndex = 0;
    int pos = 0;

    // Scan for FlatBuffer field table patterns
    while (pos < bytes.length - 2) {
      // Look for tensor type enum byte indicators in FlatBuffer metadata
      final val = bytes[pos];
      if (val == 0 || val == 1 || val == 3 || val == 7 || val == 9) {
        // Simple byte alignment check to reduce false positives
        if (pos % 2 == 0) {
          QuantizationPrecision precision = QuantizationPrecision.unknown;
          bool warning = false;
          String? warningReason;

          switch (val) {
            case 0:
              precision = QuantizationPrecision.float32;
              break;
            case 1:
              precision = QuantizationPrecision.float16;
              break;
            case 3:
              precision = QuantizationPrecision.uint8;
              warning = true;
              warningReason =
                  '8-bit unsigned integer quantization may cause accuracy loss';
              break;
            case 7:
              precision = QuantizationPrecision.int16;
              warning = true;
              warningReason = '16-bit integer quantization detected';
              break;
            case 9:
              precision = QuantizationPrecision.int8;
              warning = true;
              warningReason =
                  '8-bit signed integer quantization may cause accuracy loss';
              break;
          }

          if (precision != QuantizationPrecision.unknown) {
            layerIndex++;
            final sizeEst = (bytes.length / (layerIndex + 4)).round();
            layers.add(QuantizedLayer(
              name: 'tflite_tensor_$layerIndex',
              precision: precision,
              sizeBytes: sizeEst,
              hasPrecisionWarning: warning,
              warningReason: warningReason,
            ));
            pos += 4; // Skip ahead after finding a match
            continue;
          }
        }
      }
      pos++;
    }

    if (layers.isEmpty && validMagic) {
      // Default baseline fallback for valid TFLite header
      layers.add(QuantizedLayer(
        name: 'tflite_tensor_0',
        precision: QuantizationPrecision.float32,
        sizeBytes: bytes.length,
        hasPrecisionWarning: false,
      ));
    }

    return QuantizationReport(
      modelId: modelId,
      format: validMagic ? 'tflite' : 'unknown',
      layers: layers,
      totalSizeBytes: bytes.length,
    );
  }
}
