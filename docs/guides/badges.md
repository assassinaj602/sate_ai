# CI/CD Status Badges Guide

SATE AI includes built-in SVG badge generation for stress test results, allowing developers to embed real-time model security and performance badges directly in repository `README.md` files or CI dashboards.

## Badge Types

SATE AI generates high-resolution SVG badges in flat or flat-square styles:

1. **Status Badge:** Indicates overall PASS or FAIL based on pass rate thresholds.
2. **Pass Rate Badge:** Displays exact pass percentage (e.g., `pass rate: 98%`).
3. **Latency Badge:** Displays average or P95 response latency (e.g., `p95 latency: 142ms`).
4. **Memory Badge:** Displays peak memory consumption during stress testing (e.g., `peak memory: 412MB`).

## Generating Badges via CLI

Generate an SVG badge directly from a completed stress test report JSON file:

```bash
sate_ai badge \
  --report report.json \
  --output ./badges/status.svg \
  --style flat
```

### Options

| Flag | Short | Default | Description |
| --- | --- | --- | --- |
| `--report` | `-r` | Required | Path to the input `report.json` file |
| `--output` | `-o` | `badge.svg` | Destination file path for generated SVG |
| `--metric` | `-m` | `status` | Metric type (`status`, `pass_rate`, `latency`, `memory`) |
| `--label` | `-l` | Auto | Custom label text for the left side of badge |
| `--style` | `-s` | `flat` | Badge style (`flat`, `flat-square`, `for-the-badge`) |

## Embedding in README

Once generated, reference the badge in your repository markdown:

```markdown
![SATE AI Stress Test Status](./badges/status.svg)
![Pass Rate](./badges/pass_rate.svg)
![P95 Latency](./badges/latency.svg)
```

## GitHub Actions CI/CD Pipeline Integration

Automatically generate and publish badges on every pull request or main build:

```yaml
name: Model Stress Testing & Badge Update

on:
  push:
    branches: [ main ]

jobs:
  stress-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Dart
        uses: dart-lang/setup-dart@v1

      - name: Install SATE AI
        run: dart pub global activate sate_ai

      - name: Run Stress Tests
        run: sate_ai run --model llama3:8b --output report.json

      - name: Generate Badges
        run: |
          sate_ai badge --report report.json --metric status --output badges/status.svg
          sate_ai badge --report report.json --metric pass_rate --output badges/pass_rate.svg

      - name: Commit Badges
        uses: stefanzweifel/git-auto-commit-action@v5
        with:
          commit_message: "chore: update stress test badges [skip ci]"
          file_pattern: badges/*.svg
```

## Programmatic API Usage

```dart
import 'package:sate_ai/sate_ai.dart';

void main() async {
  final report = await ReportDatabase().getLatestReport();
  
  final badgeGenerator = BadgeGenerator();
  
  final svgContent = badgeGenerator.generate(
    report: report,
    metric: BadgeMetric.passRate,
    style: BadgeStyle.flat,
  );
  
  await File('badges/pass_rate.svg').writeAsString(svgContent);
}
```
