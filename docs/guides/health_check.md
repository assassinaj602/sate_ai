# System & Model Health Check Guide

Before executing long-running stress tests or CI/CD model verification pipelines, SATE AI provides a comprehensive health check mechanism to verify model server availability, API credential validity, system memory reserves, and network latency.

## Overview

The `SateAI.healthCheck()` diagnostic scanner performs automated verification checks against:
- Model provider availability (Ollama, OpenAI, Anthropic, Custom HTTP).
- Model deployment status (ensuring target model is loaded and responsive).
- System environment dependencies (SQLite native libraries, disk space, available RAM).
- Network connectivity and round-trip latency.

## Running Health Check via CLI

Use the `sate_ai health` command:

```bash
sate_ai health --model llama3:8b --provider ollama
```

### Options

| Flag | Short | Default | Description |
| --- | --- | --- | --- |
| `--model` | `-m` | Optional | Target model to ping and test generation against |
| `--provider` | `-p` | `ollama` | Provider backend (`ollama`, `openai`, `anthropic`, `custom`) |
| `--url` | `-u` | Auto | Provider API base URL (e.g., `http://localhost:11434`) |
| `--strict` | `-s` | `false` | Exit with error code on any warning level issue |

### Sample Output

```
[+] SATE AI Health Diagnostic Scanner v0.14.0
--------------------------------------------------
[✓] SQLite native library (sqlite3 FFI): OK
[✓] Model Provider Endpoint (http://localhost:11434): OK (12ms)
[✓] Target Model Availability (llama3:8b): LOADED
[✓] Sample Probe Inference Test: PASS (180ms)
[✓] System Memory Reserve: OK (14.2 GB available)
--------------------------------------------------
Status: ALL CHECKS PASSED
```

## Programmatic Health Check API

Integrate health checking programmatically before launching automated test suites:

```dart
import 'package:sate_ai/sate_ai.dart';

void main() async {
  final healthStatus = await SateAI.healthCheck(
    config: HealthCheckConfig(
      provider: ProviderType.ollama,
      modelName: 'llama3:8b',
      baseUrl: 'http://localhost:11434',
    ),
  );

  if (!healthStatus.isHealthy) {
    print('Health check failed: ${healthStatus.errorMessage}');
    for (final issue in healthStatus.issues) {
      print(' - [${issue.severity}] ${issue.message}');
    }
    return;
  }

  print('System healthy! Latency: ${healthStatus.pingLatencyMs}ms');
}
```

## CI/CD Pipeline Health Pre-Check Step

Use the health check command as a pre-flight step in GitHub Actions:

```yaml
- name: Verify Model Server Health
  run: sate_ai health --model llama3:8b --provider ollama --strict
```
