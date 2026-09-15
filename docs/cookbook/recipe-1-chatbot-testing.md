# Recipe 1: Testing a Chatbot Model

This recipe demonstrates how to test on-device Large Language Models (LLMs) such as Llama 3, Phi-3, Gemma, or Mistral running inside Flutter apps using `FllamaAdapter` or `MockAdapter`.

---

## 🎯 Testing Goals

1. **Memory Exhaustion Resilience**: Verify that the app avoids crashing with an unhandled OOM when KV-cache expands during long chat conversations.
2. **Malformed Prompt Handling**: Ensure special tokens, emojis, null bytes, and gigantic prompt lengths are sanitized or rejected cleanly.
3. **Quantization Precision Validation**: Track output confidence/drift as the model continues autoregressive token generation.

---

## 💻 Code Example

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sate_ai/sate_ai.dart';

void main() {
  test('LLM Chatbot stress resilience under memory pressure and bad prompts', () async {
    // 1. Initialize model adapter (or use FllamaAdapter with real GGUF weights)
    final model = MockAdapter(modelId: 'phi-3-mini-4k-instruct.gguf');

    // 2. Configure target fault injectors
    final injectors = [
      MemoryPressureInjector(
        model: model,
        limitMb: 350.0, // Allocate up to 350MB to simulate high RAM pressure
      ),
      MalformedInputInjector(),
      QuantizationDriftInjector(
        model: model,
        driftFactor: 0.08,
        degradationThreshold: 0.35,
      ),
    ];

    // 3. Execute stress suite
    final report = await SateAI.stress(
      model: model,
      injectors: injectors,
      timeout: const Duration(seconds: 45),
      retryCount: 2,
    );

    // 4. Verify results
    expect(report.passed, isTrue, reason: 'Chatbot should handle all injected faults gracefully');
    expect(report.results.length, equals(3));

    // Export report for CI inspection
    print(report.toMarkdown());
  });
}
```

---

## 🔍 Expected Behavior & Troubleshooting

- **Graceful Memory Handling**: When memory exceeds 300MB, the model wrapper should purge old conversation history from context rather than crashing the Flutter engine.
- **Malformed Input Catching**: Injecting binary payload into the tokenizer should result in an `AIInferenceError` caught gracefully by the UI layer.
- **Drift Detection**: When token generation confidence drops below 0.35, the app should trigger a fallback response or query summarization.
