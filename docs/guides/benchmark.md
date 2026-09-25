# Benchmarking & Latency Percentiles Guide

Evaluating AI model security requires understanding latency degradation and resource utilization under high concurrent probe loads. SATE AI includes comprehensive benchmarking tools to capture high-resolution percentile metrics and latency distribution curves.

## Key Metrics Captured

- **P50 (Median Latency):** The latency threshold within which 50% of response probes complete.
- **P90 / P95 / P99 Latency:** Tail latencies representing 90th, 95th, and 99th percentile response times under stress.
- **Tokens Per Second (TPS):** Mean and peak throughput generation rates.
- **First-Token Latency (TTFT):** Time to first token response in streaming configurations.
- **Peak RAM / VRAM Usage:** Hardware memory consumption during concurrent stress testing.

## Running a Benchmark Test via CLI

Use the `sate_ai benchmark` command to evaluate model throughput under stress:

```bash
sate_ai benchmark \
  --model llama3:8b \
  --concurrency 10 \
  --total-requests 500 \
  --warmup 10 \
  --output benchmark_results.json
```

### Command Flags

| Flag | Short | Default | Description |
| --- | --- | --- | --- |
| `--model` | `-m` | Required | Model target (e.g., `ollama/llama3:8b`, `openai/gpt-4o`) |
| `--concurrency` | `-c` | `5` | Number of simultaneous stress test worker threads |
| `--total-requests` | `-n` | `100` | Total number of stress test requests to issue |
| `--warmup` | `-w` | `5` | Number of unrecorded warmup requests before measurement |
| `--timeout` | `-t` | `30s` | Individual request timeout duration |
| `--output` | `-o` | Console | JSON/HTML benchmark report output path |

## Analyzing Benchmark Output

SATE AI outputs structured latency percentile distributions:

```json
{
  "model": "llama3:8b",
  "concurrency": 10,
  "total_requests": 500,
  "successful_requests": 500,
  "failed_requests": 0,
  "requests_per_sec": 42.8,
  "latency_stats": {
    "min_ms": 45.2,
    "mean_ms": 112.4,
    "p50_ms": 98.0,
    "p90_ms": 165.5,
    "p95_ms": 189.2,
    "p99_ms": 245.0,
    "max_ms": 310.1,
    "std_dev_ms": 34.1
  },
  "memory_stats": {
    "initial_mb": 120.4,
    "peak_mb": 412.8,
    "final_mb": 135.0
  }
}
```

## Programmatic Benchmark API Usage

```dart
import 'package:sate_ai/sate_ai.dart';

void main() async {
  final benchmark = StressTestBenchmark(
    adapter: OllamaAdapter(model: 'llama3:8b'),
    concurrency: 10,
    totalRequests: 500,
    warmupRequests: 10,
  );

  final result = await benchmark.run();

  print('P95 Latency: ${result.latencyStats.p95} ms');
  print('Throughput: ${result.requestsPerSecond} req/sec');
  print('Peak Memory: ${result.memoryStats.peakMb} MB');
}
```
