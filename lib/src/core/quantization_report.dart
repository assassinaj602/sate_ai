/// Quantization precision observed for a single tensor/layer.
enum QuantizationPrecision {
  /// 32-bit float (baseline, no quantization).
  float32,

  /// 16-bit float (half precision, mild quantization).
  float16,

  /// 8-bit signed integer (standard post-training quantization).
  int8,

  /// 8-bit unsigned integer (standard post-training quantization).
  uint8,

  /// 16-bit integer (rare, aggressive quantization).
  int16,

  /// Unknown precision.
  unknown,
}

/// Extension methods for [QuantizationPrecision].
extension QuantizationPrecisionX on QuantizationPrecision {
  /// Whether this precision is quantized (below float32).
  bool get isQuantized => this != QuantizationPrecision.float32;

  /// Whether this precision is considered "aggressive" (likely to lose
  /// accuracy on sensitive layers).
  bool get isAggressive =>
      this == QuantizationPrecision.int8 ||
      this == QuantizationPrecision.uint8 ||
      this == QuantizationPrecision.int16;
}

/// Result of analyzing a single quantized (or unquantized) tensor/layer.
class QuantizedLayer {
  /// Layer or tensor name.
  final String name;

  /// Detected precision.
  final QuantizationPrecision precision;

  /// Estimated size in bytes (best-effort).
  final int sizeBytes;

  /// Whether this layer triggers a potential precision warning.
  final bool hasPrecisionWarning;

  /// Reason for the warning (if any).
  final String? warningReason;

  /// Creates a [QuantizedLayer].
  QuantizedLayer({
    required this.name,
    required this.precision,
    required this.sizeBytes,
    this.hasPrecisionWarning = false,
    this.warningReason,
  });

  /// Converts this [QuantizedLayer] to a JSON-encodable Map.
  Map<String, dynamic> toJson() => {
        'name': name,
        'precision': precision.name,
        'sizeBytes': sizeBytes,
        'hasPrecisionWarning': hasPrecisionWarning,
        'warningReason': warningReason,
      };

  /// Restores a [QuantizedLayer] from JSON.
  factory QuantizedLayer.fromJson(Map<String, dynamic> json) {
    return QuantizedLayer(
      name: json['name'] as String? ?? 'unknown',
      precision: QuantizationPrecision.values.firstWhere(
        (e) => e.name == json['precision'],
        orElse: () => QuantizationPrecision.unknown,
      ),
      sizeBytes: json['sizeBytes'] as int? ?? 0,
      hasPrecisionWarning: json['hasPrecisionWarning'] as bool? ?? false,
      warningReason: json['warningReason'] as String?,
    );
  }
}

/// Result of analyzing the quantization of a whole model.
class QuantizationReport {
  /// Model identifier (usually the file name).
  final String modelId;

  /// Detected format (onnx, tflite, unknown).
  final String format;

  /// All detected layers/tensors.
  final List<QuantizedLayer> layers;

  /// Total model size in bytes.
  final int totalSizeBytes;

  /// When the report was generated.
  final DateTime timestamp;

  /// Creates a [QuantizationReport].
  QuantizationReport({
    required this.modelId,
    required this.format,
    required this.layers,
    required this.totalSizeBytes,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Count of layers that use a quantized precision.
  int get quantizedLayerCount =>
      layers.where((l) => l.precision.isQuantized).length;

  /// Count of layers flagged with a precision warning.
  int get warningCount => layers.where((l) => l.hasPrecisionWarning).length;

  /// Whether the model has any quantized layers at all.
  bool get hasQuantization => quantizedLayerCount > 0;

  /// Overall precision, derived from the most common precision across layers.
  QuantizationPrecision get dominantPrecision {
    if (layers.isEmpty) return QuantizationPrecision.unknown;
    final counts = <QuantizationPrecision, int>{};
    for (final l in layers) {
      counts[l.precision] = (counts[l.precision] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// Converts this [QuantizationReport] to a JSON-encodable Map.
  Map<String, dynamic> toJson() => {
        'modelId': modelId,
        'format': format,
        'totalSizeBytes': totalSizeBytes,
        'timestamp': timestamp.toIso8601String(),
        'layerCount': layers.length,
        'quantizedLayerCount': quantizedLayerCount,
        'warningCount': warningCount,
        'dominantPrecision': dominantPrecision.name,
        'layers': layers.map((l) => l.toJson()).toList(),
      };

  /// Restores a [QuantizationReport] from JSON.
  factory QuantizationReport.fromJson(Map<String, dynamic> json) {
    return QuantizationReport(
      modelId: json['modelId'] as String? ?? '',
      format: json['format'] as String? ?? 'unknown',
      totalSizeBytes: json['totalSizeBytes'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      layers: (json['layers'] as List<dynamic>?)
              ?.map((l) => QuantizedLayer.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Renders a Markdown summary.
  String toMarkdown() {
    final buf = StringBuffer();
    buf.writeln('# Quantization Analysis: $modelId');
    buf.writeln();
    buf.writeln('- Format: $format');
    buf.writeln('- Total size: $totalSizeBytes bytes');
    buf.writeln('- Layers detected: ${layers.length}');
    buf.writeln('- Quantized layers: $quantizedLayerCount');
    buf.writeln('- Dominant precision: ${dominantPrecision.name}');
    buf.writeln('- Precision warnings: $warningCount');
    buf.writeln();
    if (layers.isEmpty) {
      buf.writeln(
          'No layers detected. The model may be encrypted or use an unsupported format.');
      return buf.toString();
    }
    buf.writeln('## Layers');
    buf.writeln();
    buf.writeln('| Name | Precision | Size (bytes) | Warning |');
    buf.writeln('|------|-----------|--------------|---------|');
    for (final l in layers) {
      buf.writeln(
        '| ${l.name} | ${l.precision.name} | ${l.sizeBytes} | '
        '${l.hasPrecisionWarning ? (l.warningReason ?? "yes") : "-"} |',
      );
    }
    return buf.toString();
  }
}
