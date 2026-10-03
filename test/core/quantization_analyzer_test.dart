import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('QuantizationPrecisionX Extension', () {
    test('isQuantized identifies non-float32 precisions', () {
      expect(QuantizationPrecision.float32.isQuantized, isFalse);
      expect(QuantizationPrecision.float16.isQuantized, isTrue);
      expect(QuantizationPrecision.int8.isQuantized, isTrue);
      expect(QuantizationPrecision.uint8.isQuantized, isTrue);
    });

    test('isAggressive identifies integer precisions', () {
      expect(QuantizationPrecision.float32.isAggressive, isFalse);
      expect(QuantizationPrecision.float16.isAggressive, isFalse);
      expect(QuantizationPrecision.int8.isAggressive, isTrue);
      expect(QuantizationPrecision.uint8.isAggressive, isTrue);
      expect(QuantizationPrecision.int16.isAggressive, isTrue);
    });
  });

  group('QuantizedLayer Serialization', () {
    test('toJson and fromJson work bidirectionally', () {
      final layer = QuantizedLayer(
        name: 'conv1_weights',
        precision: QuantizationPrecision.int8,
        sizeBytes: 1024,
        hasPrecisionWarning: true,
        warningReason: '8-bit int quantization',
      );

      final json = layer.toJson();
      final restored = QuantizedLayer.fromJson(json);

      expect(restored.name, equals(layer.name));
      expect(restored.precision, equals(layer.precision));
      expect(restored.sizeBytes, equals(layer.sizeBytes));
      expect(restored.hasPrecisionWarning, isTrue);
      expect(restored.warningReason, equals('8-bit int quantization'));
    });
  });

  group('QuantizationReport', () {
    test('dominantPrecision calculates correctly', () {
      final report = QuantizationReport(
        modelId: 'test_model',
        format: 'onnx',
        layers: [
          QuantizedLayer(
              name: 'l1', precision: QuantizationPrecision.int8, sizeBytes: 100),
          QuantizedLayer(
              name: 'l2', precision: QuantizationPrecision.int8, sizeBytes: 100),
          QuantizedLayer(
              name: 'l3', precision: QuantizationPrecision.float32, sizeBytes: 100),
        ],
        totalSizeBytes: 300,
      );

      expect(report.dominantPrecision, equals(QuantizationPrecision.int8));
      expect(report.quantizedLayerCount, equals(2));
      expect(report.hasQuantization, isTrue);
    });

    test('toMarkdown renders full markdown report', () {
      final report = QuantizationReport(
        modelId: 'resnet50.onnx',
        format: 'onnx',
        layers: [
          QuantizedLayer(
            name: 'conv2d_1',
            precision: QuantizationPrecision.int8,
            sizeBytes: 2048,
            hasPrecisionWarning: true,
            warningReason: 'Int8 warning',
          ),
        ],
        totalSizeBytes: 2048,
      );

      final markdown = report.toMarkdown();
      expect(markdown, contains('# Quantization Analysis: resnet50.onnx'));
      expect(markdown, contains('- Format: onnx'));
      expect(markdown, contains('conv2d_1'));
      expect(markdown, contains('Int8 warning'));
    });

    test('toJson and fromJson serialize QuantizationReport', () {
      final report = QuantizationReport(
        modelId: 'model.tflite',
        format: 'tflite',
        layers: [
          QuantizedLayer(
              name: 'layer_0', precision: QuantizationPrecision.float16, sizeBytes: 500),
        ],
        totalSizeBytes: 500,
      );

      final json = report.toJson();
      final restored = QuantizationReport.fromJson(json);

      expect(restored.modelId, equals('model.tflite'));
      expect(restored.format, equals('tflite'));
      expect(restored.layers.length, equals(1));
      expect(restored.layers.first.precision, equals(QuantizationPrecision.float16));
    });
  });

  group('OnnxQuantizationAnalyzer', () {
    test('analyzes raw ONNX Protobuf bytes correctly', () {
      // Mock ONNX bytes containing field 0x10 and data_type enum 3 (int8)
      final bytes = Uint8List.fromList([
        0x08, 0x01, 0x10, 0x03, 0x00, 0x00, 0x10, 0x01, 0x00, 0x00
      ]);

      final report = OnnxQuantizationAnalyzer.analyze(bytes, modelId: 'test.onnx');
      expect(report.format, equals('onnx'));
      expect(report.layers.length, greaterThanOrEqualTo(1));
    });

    test('handles empty bytes gracefully', () {
      final report = OnnxQuantizationAnalyzer.analyze(Uint8List(0));
      expect(report.layers, isEmpty);
      expect(report.totalSizeBytes, equals(0));
    });
  });

  group('TfliteQuantizationAnalyzer', () {
    test('hasTfliteMagic detects valid TFLite header', () {
      final validBytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x00,
        0x54, 0x46, 0x4C, 0x33, // 'TFL3'
        0x00, 0x00
      ]);

      final invalidBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07]);

      expect(TfliteQuantizationAnalyzer.hasTfliteMagic(validBytes), isTrue);
      expect(TfliteQuantizationAnalyzer.hasTfliteMagic(invalidBytes), isFalse);
    });

    test('analyzes TFLite bytes with FlatBuffer tags', () {
      final tfliteBytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x00,
        0x54, 0x46, 0x4C, 0x33, // TFL3 magic
        0x09 // int8 tensor type enum
      ]);

      final report = TfliteQuantizationAnalyzer.analyze(tfliteBytes, modelId: 'model.tflite');
      expect(report.format, equals('tflite'));
      expect(report.hasQuantization, isTrue);
    });
  });

  group('QuantizationAnalyzer Facade', () {
    test('auto-detects ONNX format by file extension', () {
      final bytes = Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]);
      final report = QuantizationAnalyzer.analyzeBytes(bytes, modelId: 'my_model.onnx');
      expect(report.format, equals('onnx'));
    });

    test('analyzeFile throws FileSystemException if file missing', () async {
      final nonExistentFile = File('non_existent_model_12345.onnx');
      expect(
        () => QuantizationAnalyzer.analyzeFile(nonExistentFile),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('analyzeFile reads and analyzes existing file', () async {
      final tempFile = File('temp_test_model.tflite');
      final bytes = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x00,
        0x54, 0x46, 0x4C, 0x33, // TFL3
        0x09 // int8
      ]);
      await tempFile.writeAsBytes(bytes);

      final report = await QuantizationAnalyzer.analyzeFile(tempFile);
      expect(report.format, equals('tflite'));

      await tempFile.delete();
    });
  });
}
