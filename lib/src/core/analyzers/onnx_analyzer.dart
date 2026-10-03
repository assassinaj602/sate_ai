import 'dart:typed_data';
import '../quantization_report.dart';

/// Lightweight pure-Dart ONNX model quantization analyzer.
///
/// Inspects raw ONNX Protobuf bytes without requiring native dependencies.
class OnnxQuantizationAnalyzer {
  /// Analyzes an ONNX model binary and returns a [QuantizationReport].
  static QuantizationReport analyze(Uint8List bytes,
      {String modelId = 'onnx_model'}) {
    final layers = <QuantizedLayer>[];

    // ONNX models are Protobuf binary files.
    // Check basic validity: non-empty and reasonably sized.
    if (bytes.length < 8) {
      return QuantizationReport(
        modelId: modelId,
        format: 'onnx',
        layers: [],
        totalSizeBytes: bytes.length,
      );
    }

    // Heuristic binary scan for ONNX TensorProto / NodeProto entries.
    // In ONNX protobuf schemas:
    // TensorProto field tag 2 (data_type) is varint.
    // Enum mappings for ONNX TensorProto.DataType:
    // 1: FLOAT (float32)
    // 2: UINT8 (uint8)
    // 3: INT8 (int8)
    // 5: INT16 (int16)
    // 10: FLOAT16 (float16)

    int layerIndex = 0;
    int pos = 0;

    while (pos < bytes.length - 4) {
      // Look for protobuf field tag 0x10 (field #2, varint type) or field tag 0x0a (string field for name)
      if (bytes[pos] == 0x10) {
        // TensorProto.data_type varint
        final dtValue = bytes[pos + 1];
        QuantizationPrecision precision = QuantizationPrecision.unknown;
        bool warning = false;
        String? warningReason;

        switch (dtValue) {
          case 1:
            precision = QuantizationPrecision.float32;
            break;
          case 2:
            precision = QuantizationPrecision.uint8;
            warning = true;
            warningReason =
                '8-bit unsigned integer quantization may reduce model accuracy';
            break;
          case 3:
            precision = QuantizationPrecision.int8;
            warning = true;
            warningReason =
                '8-bit signed integer quantization may reduce model accuracy';
            break;
          case 5:
            precision = QuantizationPrecision.int16;
            warning = true;
            warningReason = '16-bit integer quantization detected';
            break;
          case 10:
            precision = QuantizationPrecision.float16;
            warning = false;
            break;
        }

        if (precision != QuantizationPrecision.unknown) {
          layerIndex++;
          final sizeEstimate = (bytes.length / (layerIndex + 5)).round();
          layers.add(QuantizedLayer(
            name: 'onnx_tensor_$layerIndex',
            precision: precision,
            sizeBytes: sizeEstimate,
            hasPrecisionWarning: warning,
            warningReason: warningReason,
          ));
        }
        pos += 2;
      } else {
        pos++;
      }
    }

    // Fallback if no specific layers extracted from raw bytes heuristic
    if (layers.isEmpty) {
      // Perform fallback string/byte heuristics for ONNX format marker
      final hasFloat32 = _containsMarker(bytes, [0x08, 0x01]);
      final hasInt8 = _containsMarker(bytes, [0x08, 0x03]);

      if (hasInt8 || hasFloat32) {
        layers.add(QuantizedLayer(
          name: 'tensor_0',
          precision: hasInt8
              ? QuantizationPrecision.int8
              : QuantizationPrecision.float32,
          sizeBytes: bytes.length,
          hasPrecisionWarning: hasInt8,
          warningReason:
              hasInt8 ? 'Post-training int8 quantization detected' : null,
        ));
      }
    }

    return QuantizationReport(
      modelId: modelId,
      format: 'onnx',
      layers: layers,
      totalSizeBytes: bytes.length,
    );
  }

  static bool _containsMarker(Uint8List bytes, List<int> pattern) {
    if (bytes.length < pattern.length) return false;
    for (int i = 0; i <= bytes.length - pattern.length; i++) {
      bool match = true;
      for (int j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) {
          match = false;
          break;
        }
      }
      if (match) return true;
    }
    return false;
  }
}
