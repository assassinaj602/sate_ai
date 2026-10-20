# Video 4: CI/CD Integration & Automation

> **Episode**: 04 of 05  
> **Target Duration**: 4 minutes 00 seconds  
> **Level**: Advanced  
> **Topics**: Headless CLI Execution, GitHub Composite Action, CI Regression Gating  

---

## 📋 Production Script & Timeline

| Time | Segment | Visual On Screen | Audio / Narration |
| :---: | :--- | :--- | :--- |
| **00:00 - 00:35** | **Introduction** | Terminal showing green CI pipeline checkmarks next to PR. | "Welcome to Episode 4. Writing stress tests is essential, but if they only run on your local laptop, regressions will still slip into production. In this video, you will learn how to automate SATE AI in your CI/CD pipelines using our headless CLI and GitHub Action." |
| **00:35 - 01:45** | **The Headless CLI** | Running `dart pub global activate sate_cli` and executing `sate test`. | "Because SATE AI core is written in pure Dart, the CLI runs in headless server environments without needing the Flutter SDK. You can run automated tests, auto-detect model types, run pre-flight cost estimations, and generate JUnit reports with a single command." |
| **01:45 - 03:00** | **GitHub Composite Action** | Writing `.github/workflows/ai_stress.yml` using `sate-ai-test` composite action. | "Setting this up on GitHub Actions takes four lines of YAML. We use the official `sate-ai-test` composite action. It automatically sets up Dart, runs our stress test suite, exports HTML and JUnit reports, and uploads test artifacts directly to the workflow summary." |
| **03:00 - 03:40** | **Automated Quality Gates** | Setting threshold `--fail-below 0.95` and `--max-p99 120`. | "You can define strict quality gates: for example, failing the pull request if the model pass rate drops below 95% under thermal throttling, or if P99 latency exceeds 120 milliseconds. This guarantees your models never regress in production." |
| **03:40 - 04:00** | **Outro & Next Episode** | Graphic card promoting Episode 5: Advanced Features & Web Dashboard. | "Your AI pipelines are now automatically guarded on every commit. In our final episode, we explore advanced features: the interactive DevTools web dashboard and SQLite report persistence." |

---

## 💻 Workflow Example: GitHub Actions Pipeline

```yaml
name: On-Device AI Resilience Suite

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  stress-test:
    name: Model Fault Injection Gating
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Dart SDK
        uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Run SATE AI Stress Action
        uses: ./.github/actions/sate-ai-test
        with:
          model-path: 'assets/models/mobilenet_v2.tflite'
          stress-profile: 'balanced'
          iterations: '50'
          fail-threshold: '0.95'
          export-format: 'junit,html'

      - name: Publish Test Results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: stress-report
          path: 'build/reports/'
```

---

## 🎙️ Complete Voiceover Transcript

**[00:00]** Welcome to Episode 4. Reliability testing is most effective when automated as part of every pull request.

**[00:35]** The `sate_cli` package provides a headless runner that operates without GUI dependencies. You can install it via `dart pub global activate sate_cli` and execute stress suites directly from the terminal.

**[01:45]** Here is how you configure our GitHub composite action. In your workflow file, add the `sate-ai-test` step, specify your model path, and choose your stress profile.

**[03:00]** SATE AI enforces automated quality gates: if memory pressure causes unhandled failures or latency violates your threshold, the check fails and blocks merging until fixed.

**[03:40]** In Episode 5, we will explore our interactive DevTools web dashboard and persistent report storage.
