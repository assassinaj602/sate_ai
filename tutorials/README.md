# SATE AI Video Tutorial Series: Hands-On On-Device AI Chaos Engineering

Welcome to the official 5-part video tutorial series for **SATE AI** (Stress and Adversarial Testing Engine for AI). Each episode is concise (3 to 5 minutes) and focuses on practical, hands-on implementation to help you harden on-device machine learning models against production failures.

---

## 📺 Video Playlist Overview

| # | Title | Duration | Level | Focus | Video Guide & Transcript |
| :-: | :--- | :---: | :---: | :--- | :--- |
| **01** | **Getting Started with SATE AI** | 3:45 | Beginner | Installation, first stress test, reading reports | [View Script & Transcript](video-1-getting-started.md) |
| **02** | **Building a Custom Fault Injector** | 4:15 | Intermediate | The `FaultInjector` contract, lifecycle, testing | [View Script & Transcript](video-2-custom-injector.md) |
| **03** | **Creating a Custom Model Adapter** | 4:30 | Intermediate | The `AIModelAdapter` interface, custom runtimes | [View Script & Transcript](video-3-custom-adapter.md) |
| **04** | **CI/CD Integration & Automation** | 4:00 | Advanced | Headless CLI, GitHub Action, automated gating | [View Script & Transcript](video-4-ci-cd-integration.md) |
| **05** | **Advanced Telemetry & Web Dashboard** | 4:45 | Advanced | Real-time DevTools, SQLite storage, debugging | [View Script & Transcript](video-5-advanced-features.md) |

---

## 🎬 Prerequisites & Quick Setup

To follow along with all tutorials, ensure your environment meets these requirements:

```bash
# 1. Install Flutter (3.10+ recommended) or Dart (3.0+)
flutter --version

# 2. Add SATE AI to your Flutter application
flutter pub add sate_ai

# 3. Or install the headless CLI globally
dart pub global activate sate_cli

# 4. Verify installation
sate --help
```

---

## 🌐 Online Interactive Hub

All video episodes, interactive code playgrounds, and searchable transcripts are hosted on our documentation website:
- **Interactive Portal**: <https://assassinaj602.github.io/sate_ai/tutorials.html>
- **Full Video Repository**: Available on the [SATE AI YouTube Channel](https://youtube.com/@sate_ai_official)
