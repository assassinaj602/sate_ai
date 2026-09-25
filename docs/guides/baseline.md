# Golden Baseline & Regression Testing Guide

To prevent security degradation and latency regressions during AI model fine-tuning, system prompt updates, or library upgrades, SATE AI supports Golden Baseline comparison testing.

## Overview

Golden Baseline testing compares a current stress test run against a previously approved baseline snapshot (`golden_baseline.json`).

If the new run:
- Drops below the baseline pass rate,
- Exhibits new prompt injection vulnerabilities,
- Or exceeds latency / memory tolerance thresholds,

SATE AI flags regressions and returns a non-zero exit code to fail CI/CD build pipelines.

## Establishing a Baseline

Run a stress test and save the output as your official golden baseline:

```bash
sate_ai run \
  --model llama3:8b \
  --injectors prompt_injection,jailbreak,system_prompt_leak \
  --output golden_baseline.json
```

## Running Baseline Comparison Tests

Compare new model iterations against the baseline snapshot:

```bash
sate_ai run \
  --model llama3:8b-v2 \
  --baseline golden_baseline.json \
  --fail-on-regression \
  --max-latency-increase 15%
```

### Options

| Flag | Short | Default | Description |
| --- | --- | --- | --- |
| `--baseline` | `-b` | Required | Path to reference golden baseline JSON file |
| `--fail-on-regression` | | `true` | Exit with error code if regressions are detected |
| `--allowed-pass-rate-drop` | | `0.0%` | Maximum allowed drop in pass rate percentage |
| `--max-latency-increase` | | `10%` | Maximum allowed percentage increase in latency |

## Diff Report Output Example

When regressions are detected, SATE AI outputs a detailed delta report:

```
[!] REGRESSION DETECTED against golden_baseline.json
--------------------------------------------------
Pass Rate:     98.5% -> 92.0%  (ALERT: -6.5% drop)
P95 Latency:   140ms -> 185ms  (ALERT: +32.1% increase)
New Vulnerabilities Identified:
  1. [JailbreakInjector] Probe #42: Prompt bypass succeeded on iteration 2
  2. [SystemPromptLeak] Probe #18: System instructions leaked
--------------------------------------------------
Result: FAILED (2 regression rules violated)
```

## Programmatic API Usage

```dart
import 'package:sate_ai/sate_ai.dart';

void main() async {
  final baseline = await BaselineSnapshot.loadFromFile('golden_baseline.json');

  final runner = StressTestRunner(config: config);
  final currentReport = await runner.run();

  final diff = BaselineComparer.compare(
    baseline: baseline,
    current: currentReport,
    maxPassRateDropPercent: 0.0,
    maxLatencyIncreasePercent: 10.0,
  );

  if (diff.hasRegressions) {
    print('Regression check failed: ${diff.regressionSummary}');
    exit(1);
  }

  print('No regressions detected compared to golden baseline.');
}
```
