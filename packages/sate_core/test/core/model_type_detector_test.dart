import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  group('ModelTypeDetector', () {
    test('detects ONNX from .onnx extension', () {
      expect(ModelTypeDetector.detect('model.onnx'),
          equals(DetectedModelType.onnx));
    });

    test('detects TFLite from .tflite extension', () {
      expect(ModelTypeDetector.detect('model.tflite'),
          equals(DetectedModelType.tflite));
    });

    test('detects GGUF from .gguf extension', () {
      expect(ModelTypeDetector.detect('model.gguf'),
          equals(DetectedModelType.gguf));
    });

    test('detects CoreML from .mlmodel extension', () {
      expect(ModelTypeDetector.detect('model.mlmodel'),
          equals(DetectedModelType.coreml));
    });

    test('detects TensorFlow from .pb extension', () {
      expect(ModelTypeDetector.detect('model.pb'),
          equals(DetectedModelType.tensorflow));
    });

    test('returns unknown for unrecognized extensions', () {
      expect(ModelTypeDetector.detect('model.xyz'),
          equals(DetectedModelType.unknown));
    });

    test('handles uppercase extensions', () {
      expect(ModelTypeDetector.detect('model.ONNX'),
          equals(DetectedModelType.onnx));
    });

    test('handles paths with directories', () {
      expect(ModelTypeDetector.detect('/path/to/model.tflite'),
          equals(DetectedModelType.tflite));
    });

    test('handles files without extensions', () {
      expect(
          ModelTypeDetector.detect('model'), equals(DetectedModelType.unknown));
    });

    test('isSupported returns true for supported types', () {
      expect(ModelTypeDetector.isSupported('model.onnx'), isTrue);
      expect(ModelTypeDetector.isSupported('model.tflite'), isTrue);
      expect(ModelTypeDetector.isSupported('model.gguf'), isTrue);
    });

    test('isSupported returns false for unknown types', () {
      expect(ModelTypeDetector.isSupported('model.xyz'), isFalse);
    });

    test('supportedExtensions contains expected extensions', () {
      final extensions = ModelTypeDetector.supportedExtensions;
      expect(extensions, contains('onnx'));
      expect(extensions, contains('tflite'));
      expect(extensions, contains('gguf'));
      expect(extensions, contains('mlmodel'));
    });

    test('DetectedModelType displayName returns correct names', () {
      expect(DetectedModelType.onnx.displayName, equals('ONNX Runtime'));
      expect(DetectedModelType.tflite.displayName, equals('TensorFlow Lite'));
      expect(DetectedModelType.gguf.displayName, equals('Fllama (llama.cpp)'));
      expect(DetectedModelType.unknown.displayName,
          equals('Unknown (MockAdapter)'));
    });
  });

  group('ModelFactory', () {
    test('creates MockAdapter for unknown types', () {
      final model = ModelFactory.create(
        filePath: 'model.xyz',
        modelId: 'test',
        autoDetect: true,
      );
      expect(model, isA<MockAdapter>());
    });

    test('creates MockAdapter when autoDetect is false', () {
      final model = ModelFactory.create(
        filePath: 'model.onnx',
        modelId: 'test',
        autoDetect: false,
      );
      expect(model, isA<MockAdapter>());
    });

    test('creates adapter for ONNX with bytes', () {
      final model = ModelFactory.create(
        filePath: 'model.onnx',
        modelId: 'test',
        autoDetect: true,
      );
      expect(model, isA<AIModelAdapter>());
    });
  });
}
