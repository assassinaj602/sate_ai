# Summary & Quick Reference

## 📑 Summary of SATE AI Recipes

| Recipe | Key Concepts | Applicable Injectors | Primary Output |
|---|---|---|---|
| [**Recipe 1: Chatbot Testing**](recipe-1-chatbot-testing.md) | LLM KV-cache memory, bad prompt tokens, autoregressive drift | `MemoryPressure`, `MalformedInput`, `QuantizationDrift` | Markdown logs, context trimming |
| [**Recipe 2: Image Classifier Testing**](recipe-2-image-classifier-testing.md) | Vision model FPS, device heat throttling, fallback swaps | `ThermalThrottle`, `Latency`, `ModelSwap` | Execution latency benchmarks |
| [**Recipe 3: Speech-to-Text Testing**](recipe-3-speech-to-text-testing.md) | Audio buffer framing, noise handling, certainty scores | `MalformedInput`, `Latency`, `ConfidenceThreshold` | Confidence thresholds |
| [**Recipe 4: ONNX Runtime Testing**](recipe-4-onnx-runtime-testing.md) | Cross-platform ONNX tensors, native C++ memory management | All injectors (`OnnxAdapter`) | HTML stress reports |
| [**Recipe 5: TensorFlow Lite Testing**](recipe-5-tflite-testing.md) | INT8/FP16 quantized weights, GPU delegate fallback | All injectors (`TFLiteAdapter`) | Golden baselines |

---

## 🔗 Related Resources

- [SATE AI GitHub Repository](https://github.com/assassinaj602/sate_ai)
- [Common Setup & Fixtures](common-setup.md)
- [Multi-Injector Integration Guide](integration-guide.md)
- [Cookbook Landing Page](index.md)
