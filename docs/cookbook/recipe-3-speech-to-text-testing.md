# Recipe 3: Testing a Speech-to-Text Model

This recipe covers stress testing on-device speech-to-text (STT) and voice transcription pipelines (e.g. Whisper.tflite, Vosk, or custom acoustic models).

---

## 🎯 Testing Goals

1. **Audio Buffer Corruption / Bad Inputs**: Inject silent, clipped, clipped floating-point, or gigantic raw PCM audio arrays.
2. **Confidence Thresholding**: Reject transcription results with low acoustic certainty and request user repetition.
3. **Streaming Latency Under Load**: Measure real-time transcription delay when audio chunks arrive faster than inference time.

---

## 💻 Code Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  test('Speech-to-Text testing for malformed audio buffers and low confidence', () async {
    final model = MockAdapter(modelId: 'whisper-tiny-en.tflite');

    final injectors = [
      MalformedInputInjector(),
      LatencyInjector(
        model: model,
        latency: const Duration(milliseconds: 250),
      ),
      ConfidenceThresholdInjector(
        model: model,
        threshold: 0.60, // Require at least 60% confidence for valid speech
      ),
    ];

    final report = await SateAI.stress(
      model: model,
      injectors: injectors,
      timeout: const Duration(seconds: 25),
    );

    expect(report.passed, isTrue);

    // Verify confidence injector passed
    final confResult = report.results.firstWhere(
      (r) => r.injectorType == FaultType.confidenceValidation,
    );
    expect(confResult.passed, isTrue);
  });
}
```

---

## 🎙️ Audio Preprocessing Tips

- **Sample Rate Validation**: Ensure your audio recorder matches the model's required rate (usually 16kHz mono).
- **Buffer Slicing**: Avoid passing unpadded raw PCM chunks directly to inference; use fixed window framing.
- **Handling Silence**: The confidence validator ensures pure silence does not hallucinate false words.
