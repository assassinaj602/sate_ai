# Custom Report Templates Guide

SATE AI provides a flexible template engine that allows teams to customize the visual structure and layout of stress test reports (HTML, Markdown, JSON, YAML).

## Overview

By default, SATE AI exports reports using standard built-in templates. With custom templates, you can:
- Enforce corporate branding and style guidelines.
- Highlight custom metrics (e.g., tokens/sec, memory usage, prompt injection survival rates).
- Integrate custom CSS/JS for internal dashboards.

## Supported Formats

- **HTML** (`.html` / `.hbs` / `.mustache`)
- **Markdown** (`.md`)
- **JSON / YAML** (`.json`, `.yaml`)

## Template Variables

When SATE AI renders a report template, the following variables are injected into the template context:

| Variable | Type | Description |
| --- | --- | --- |
| `title` | String | Title of the stress test run |
| `timestamp` | String | ISO 8601 timestamp of execution |
| `model` | String | Target model identifier |
| `totalTests` | Integer | Total number of tests executed |
| `passed` | Integer | Total passed tests |
| `failed` | Integer | Total failed tests |
| `passRate` | Double | Pass rate percentage (0 - 100%) |
| `avgLatencyMs` | Double | Average response time in milliseconds |
| `p95LatencyMs` | Double | 95th percentile latency |
| `maxMemoryMb` | Double | Peak memory consumption in MB |
| `results` | Array | List of test case result objects |

## Creating a Custom Template

### Markdown Template Example (`my_template.md`)

```markdown
# Security Stress Test Report: {{model}}

**Date:** {{timestamp}}  
**Overall Status:** {{#if (gte passRate 90)}}PASSED{{else}}FAILED{{/if}} ({{passRate}}% pass rate)

---

## Executive Summary

- **Total Probes Executed:** {{totalTests}}
- **Passed:** {{passed}}
- **Vulnerabilities Detected:** {{failed}}
- **Average Latency:** {{avgLatencyMs}} ms
- **P95 Latency:** {{p95LatencyMs}} ms

## Detailed Probe Results

| Test Name | Injector Type | Status | Latency | Error Details |
| --- | --- | --- | --- | --- |
{{#each results}}
| {{name}} | {{injector}} | {{#if passed}}PASS{{else}}FAIL{{/if}} | {{latencyMs}} ms | {{error}} |
{{/each}}
```

## Using Custom Templates via CLI

Pass the `--template` flag pointing to your custom template file:

```bash
sate_ai run \
  --model llama3:8b \
  --injectors prompt_injection,jailbreak \
  --template ./my_template.md \
  --output report.md
```

## Programmatic Usage in Dart

```dart
import 'package:sate_ai/sate_ai.dart';

void main() async {
  final runner = StressTestRunner(
    config: StressTestConfig(
      modelName: 'llama3:8b',
      injectors: [PromptInjectionInjector()],
    ),
  );

  final report = await runner.run();

  final exporter = ReportExporter(
    templatePath: './templates/custom_report.html',
  );

  final renderedHtml = await exporter.export(report);
  print(renderedHtml);
}
```
