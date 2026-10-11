# SATE AI Web & TypeScript SDK

TypeScript and JavaScript SDK for SATE AI, providing on-device fault injection and stress testing for AI models running in web browsers and Node.js runtimes.

## Monorepo Packages

This workspace contains three packages:

- **`@sate-ai/core`**: Framework-agnostic fault injection interfaces, runner, report generation, and 11 built-in fault injectors.
- **`@sate-ai/tfjs`**: Model adapter for TensorFlow.js models (`tf.LayersModel` and `tf.GraphModel`).
- **`@sate-ai/onnx`**: Model adapter for ONNX Runtime Web (`ort.InferenceSession`).

## Requirements

- Node.js 18+ (tested on Node 20+)
- npm 9+

## Installation

Install via npm:

```bash
# Core package
npm install @sate-ai/core

# TensorFlow.js adapter
npm install @sate-ai/tfjs

# ONNX Runtime Web adapter
npm install @sate-ai/onnx
```

## Quick Start (Core)

```typescript
import {
  StressRunner,
  MockModelAdapter,
  MemoryPressureInjector,
  MalformedInputInjector,
  LatencyInjector,
} from '@sate-ai/core';

const model = new MockModelAdapter();

const runner = new StressRunner({
  model,
  injectors: [
    new MemoryPressureInjector({ model, limitMb: 50 }),
    new MalformedInputInjector(),
    new LatencyInjector({ model, maxLatencyMs: 100 }),
  ],
  timeoutMs: 15000,
});

const report = await runner.stress();
console.log(report.toMarkdown());
```

## Using with TensorFlow.js

```typescript
import * as tf from '@tensorflow/tfjs';
import { StressRunner, MemoryPressureInjector } from '@sate-ai/core';
import { TFJSAdapter } from '@sate-ai/tfjs';

const tfModel = await tf.loadLayersModel('model.json');

const model = new TFJSAdapter({
  modelId: 'my-tfjs-classifier',
  model: tfModel,
});

const runner = new StressRunner({
  model,
  injectors: [new MemoryPressureInjector({ model, limitMb: 100 })],
});

const report = await runner.stress();
```

## Using with ONNX Runtime Web

```typescript
import * as ort from 'onnxruntime-web';
import { StressRunner, LatencyInjector } from '@sate-ai/core';
import { ONNXAdapter } from '@sate-ai/onnx';

const session = await ort.InferenceSession.create('model.onnx');

const model = new ONNXAdapter({
  modelId: 'my-onnx-model',
  session,
});

const runner = new StressRunner({
  model,
  injectors: [new LatencyInjector({ model, maxLatencyMs: 80 })],
});

const report = await runner.stress();
```

## Fault Injectors

The library provides 11 built-in fault injectors:

1. `MemoryPressureInjector`: Simulates sudden memory spikes and OOM thresholds.
2. `MalformedInputInjector`: Injects empty, oversized, and corrupted inputs.
3. `QuantizationDriftInjector`: Simulates precision loss and confidence drift from quantization.
4. `ThermalThrottleInjector`: Simulates CPU/GPU throttling under heat conditions.
5. `LatencyInjector`: Introduces artificial delays to test timeout resilience.
6. `ModelSwapInjector`: Simulates hot-swapping or fallbacks to degraded models.
7. `ConfidenceThresholdInjector`: Validates behavior when model confidence drops below tolerance.
8. `GpuMemoryPressureInjector`: Tests GPU VRAM pressure limits.
9. `DataCorruptionInjector`: Introduces payload corruption and bit-flips.
10. `ModelVersionMismatchInjector`: Simulates incompatible model schema versions.
11. `NetworkLatencyDropInjector`: Simulates packet drops and network latency for remote or hybrid models.

## Development

```bash
# Install workspace dependencies
npm install

# Build all packages
npm run build

# Run all test suites
npm run test

# Run linter
npm run lint
```

## License

MIT
