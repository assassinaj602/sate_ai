# SATE AI Project Showcase

Discover real-world production mobile applications, edge AI pipelines, and academic research battle-hardened with the SATE AI fault injection framework.

View the live interactive gallery at [**assassinaj602.github.io/sate_ai/showcase.html**](https://assassinaj602.github.io/sate_ai/showcase.html).

---

## Featured Projects

| Project | Platform / Runtime | Key Fault Injectors Tested | Impact / Testimonial |
| :--- | :--- | :--- | :--- |
| **SATE AI Mobile Demo** | Flutter / TFLite & ONNX | Memory Pressure, Malformed Input, Thermal Throttle | *"Running automated stress loops during local CI detected unhandled OOM exceptions on 2GB RAM test devices before customer release."* |
| **EdgePulse Observability** | Dart CLI / GGUF (llama.cpp) | Adaptive Chaos, Thermal Throttle, Memory Pressure | *"SATE AI adaptive chaos pushed our edge LLM inference loops to their true thermal and memory limits without triggering unrecoverable kernel hard-kills."* |
| **VisionSentinel Inspection** | Edge Tablet / YOLOv8 & ONNX | Malformed Input, Quantization Drift, Latency | *"Simulating noisy camera sensors and thermal throttling in the lab saved us from expensive defect misclassifications on factory production floors."* |
| **HealthScan Offline Assistant** | Flutter / MediaPipe & ONNX | Confidence Threshold, Memory Pressure | *"Testing under quantization drift uncovered silent false positives when memory drops, allowing us to enforce strict safety fallbacks."* |
| **SATE Web Testbench** | Web & Node.js / TFJS & ONNX Web | WebGL Memory Pressure, Network Latency Drops | *"Enables browser AI engineers to test client-side model stability without needing dedicated desktop benchmarking setups."* |

---

## Add Your Project to the Showcase

Are you using SATE AI to test, benchmark, or harden on-device AI models in your app or research? We would love to feature your project!

### How to Submit

1. **Run SATE AI Stress Tests**: Execute a stress test run using the Flutter SDK or CLI:
   ```bash
   sate_ai --model assets/models/detector.tflite --injectors memoryPressure,thermalThrottle --export-html report.html
   ```
2. **Fork and Submit a Pull Request**:
   - Add your project entry to `SHOWCASE.md`.
   - Add your showcase card into `docs/showcase.html`.
   - Place a screenshot or GIF in `docs/assets/showcase/` or link to your repository asset.
3. **Alternatively, Open an Issue**:
   - Open a GitHub Issue titled `[Showcase]: <Your Project Name>` with the template below.

### Submission Template

```markdown
### Project Details
- **Project Name**: My Edge AI App
- **Website / Repository**: https://github.com/my-org/my-edge-app
- **Platform**: Flutter / Android Native / Web / CLI
- **Model Framework**: TensorFlow Lite / ONNX / MediaPipe / GGUF
- **Injectors Used**: MemoryPressure, ThermalThrottle, QuantizationDrift
- **Screenshot / GIF URL**: https://example.com/demo.gif

### Testimonial
> "What SATE AI helped our team uncover or achieve before deployment."
- Name / Team, Organization
```

---

## Display the Badge

Add the official **Tested with SATE AI** badge to your project README:

```markdown
[![Tested with SATE AI](https://img.shields.io/badge/tested_with-SATE_AI-34d399.svg)](https://github.com/assassinaj602/sate_ai)
```

Preview:

[![Tested with SATE AI](https://img.shields.io/badge/tested_with-SATE_AI-34d399.svg)](https://github.com/assassinaj602/sate_ai)

