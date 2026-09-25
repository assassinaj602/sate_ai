# Batch Runner & Auto-Detection Guide

SATE AI includes a batch execution runner capable of automatically detecting installed models and running concurrent or sequential stress testing suites across multiple models or target endpoints.

## Overview

Batch mode allows teams to:
- Test an entire suite of models (e.g., `llama3:8b`, `mistral:7b`, `phi3:mini`) in a single run.
- Automatically discover locally available Ollama models.
- Compare security vulnerability scores across multiple model providers.
- Export aggregated comparative matrix reports.

## Automatic Model Detection

SATE AI can query local endpoints (such as Ollama or local vLLM instances) to auto-detect installed models:

```bash
sate_ai batch --auto-detect --provider ollama
```

This discovers all pulled models and presents a batch execution menu or executes stress tests across all discovered models sequentially.

## Batch Configuration File (`batch.yaml`)

Define complex multi-model stress testing workflows in a declarative YAML or JSON file:

```yaml
version: 1.0
batch_name: "Weekly Security Baseline Audit"

defaults:
  concurrency: 4
  injectors:
    - prompt_injection
    - jailbreak
    - red_teaming
  output_dir: "./batch_reports"

targets:
  - model: "ollama/llama3:8b"
    label: "Llama-3-8B-Local"
  
  - model: "ollama/mistral:7b"
    label: "Mistral-7B-Local"
  
  - model: "openai/gpt-4o-mini"
    api_key_env: "OPENAI_API_KEY"
    label: "GPT-4o-Mini-Cloud"
```

## Running Batch Execution via CLI

Run the batch runner by providing a configuration file:

```bash
sate_ai batch --config batch.yaml --export-matrix matrix.html
```

### Options

| Flag | Short | Default | Description |
| --- | --- | --- | --- |
| `--config` | `-c` | `batch.yaml` | Path to batch configuration file |
| `--auto-detect` | `-a` | `false` | Automatically discover local models |
| `--parallel` | `-p` | `false` | Run model stress tests in parallel |
| `--output-dir` | `-o` | `./reports` | Directory where individual reports are saved |
| `--export-matrix` | `-m` | `matrix.html` | Export consolidated comparison matrix |

## Programmatic Batch Runner API

```dart
import 'package:sate_ai/sate_ai.dart';

void main() async {
  final batchRunner = BatchRunner(
    targets: [
      BatchTarget(modelName: 'llama3:8b', provider: ProviderType.ollama),
      BatchTarget(modelName: 'mistral:7b', provider: ProviderType.ollama),
    ],
    config: StressTestConfig(
      injectors: [PromptInjectionInjector(), JailbreakInjector()],
    ),
  );

  final batchSummary = await batchRunner.runAll();

  for (final result in batchSummary.results) {
    print('${result.modelName}: ${result.passRate}% pass rate');
  }

  await batchSummary.exportComparisonMatrix('matrix.html');
}
```
