import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:dotenv/dotenv.dart';

/// SATE AI Community Automation Script
/// This script automates GitHub setup, issue creation, and social media posting
class SATEAICommunityAutomator {
  final String githubToken;
  final String repoOwner;
  final String repoName;
  final String githubApiUrl;

  SATEAICommunityAutomator({
    required this.githubToken,
    this.repoOwner = 'assassinaj602',
    this.repoName = 'sate_ai',
  }) : githubApiUrl = 'https://api.github.com/repos/$repoOwner/$repoName';

  /// Main automation entry point
  Future<void> run() async {
    print('🚀 Starting SATE AI Community Automation...\n');

    try {
      // Step 1: Create Issues
      print('📝 Creating Good First Issues...');
      await _createAllIssues();

      // Step 2: Setup Labels
      print('🏷️ Setting up Labels...');
      await _setupLabels();

      // Step 3: Create Project Board
      print('📊 Creating Project Board...');
      await _createProjectBoard();

      // Step 4: Enable Discussions
      print('💬 Enabling Discussions...');
      await _enableDiscussions();

      // Step 5: Generate Social Media Posts
      print('📢 Generating Social Media Content...');
      _generateSocialMediaPosts();

      print('\n✅ Community automation complete! 🎉');
      print('📋 Next steps:');
      print('1. Review created issues: https://github.com/$repoOwner/$repoName/issues');
      print('2. Check project board: https://github.com/$repoOwner/$repoName/projects');
      print('3. Enable Discussions manually in Settings → General → Features');
      print('4. Copy and paste social media posts from above');
    } catch (e) {
      print('❌ Error: $e');
      exit(1);
    }
  }

  /// Create all Good First Issues
  Future<void> _createAllIssues() async {
    final issues = _getGoodFirstIssues();
    
    for (final issue in issues) {
      await _createIssue(issue);
      await Future.delayed(const Duration(seconds: 1)); // Rate limiting
    }
    
    print('✅ Created ${issues.length} issues');
  }

  /// Create a single issue
  Future<void> _createIssue(Map<String, dynamic> issueData) async {
    final url = Uri.parse('$githubApiUrl/issues');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $githubToken',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'title': issueData['title'],
        'body': issueData['body'],
        'labels': issueData['labels'],
        'assignees': issueData['assignees'] ?? [],
      }),
    );

    if (response.statusCode == 201) {
      print('  ✓ Created: ${issueData['title']}');
    } else {
      print('  ✗ Failed: ${issueData['title']} - ${response.statusCode}');
      print('  Response: ${response.body}');
    }
  }

  /// Get Good First Issues list
  List<Map<String, dynamic>> _getGoodFirstIssues() {
    return [
      {
        'title': 'Add ONNX Runtime Adapter',
        'labels': ['good first issue', 'enhancement'],
        'body': '''
## Description
Implement `OnnxAdapter` that wraps the ONNX Runtime Flutter plugin.

## Tasks
- [ ] Create `lib/src/adapters/onnx_adapter.dart`
- [ ] Implement `AIModelAdapter` interface
- [ ] Add tests in `test/adapters/onnx_adapter_test.dart`
- [ ] Document usage in README

## Required Knowledge
- ONNX Runtime
- Flutter plugin integration
- Unit testing

## Difficulty
🟡 Medium

## Time Estimate
3-5 hours

## Acceptance Criteria
- [ ] Adapter loads ONNX models
- [ ] Inference works correctly
- [ ] Memory tracking implemented
- [ ] Tests pass (minimum 80% coverage)

## Resources
- ONNX Runtime Flutter: https://pub.dev/packages/onnxruntime
- AIModelAdapter interface: lib/src/adapters/model_adapter.dart
''',
      },
      {
        'title': 'Implement Quantization Drift Injector',
        'labels': ['good first issue', 'enhancement'],
        'body': '''
## Description
Create a fault injector that simulates quantization drift in AI models.

## Acceptance Criteria
- [ ] Injector reduces model precision gradually
- [ ] Detects when output quality degrades below threshold
- [ ] Tests verify degradation detection

## Files to Create
- `lib/src/injectors/quantization_drift_injector.dart`
- `test/injectors/quantization_drift_test.dart`

## Implementation Hints
- Use MockAdapter as reference
- Simulate precision loss by modifying output
- Track degradation over multiple inferences

## Difficulty
🟢 Easy

## Time Estimate
2-3 hours

## Resources
- MockAdapter: lib/src/adapters/mock_adapter.dart
- Existing injectors: lib/src/injectors/
''',
      },
      {
        'title': 'Improve README with More Examples',
        'labels': ['good first issue', 'documentation'],
        'body': '''
## Description
Add more comprehensive examples to the README.

## Tasks
- [ ] Add example with custom injector
- [ ] Add example with CI/CD integration
- [ ] Add example with multiple fault types
- [ ] Create troubleshooting section

## Required Skills
- Markdown
- Dart/Flutter basics
- Technical writing

## Difficulty
🟢 Easy

## Time Estimate
1-2 hours

## Acceptance Criteria
- [ ] All examples are runnable
- [ ] Code snippets are correct
- [ ] Documentation is clear and comprehensive
''',
      },
      {
        'title': 'Add TensorFlow Lite Adapter',
        'labels': ['good first issue', 'enhancement'],
        'body': '''
## Description
Implement `TFLiteAdapter` for TensorFlow Lite models.

## Tasks
- [ ] Create adapter using tflite_flutter package
- [ ] Implement input/output handling
- [ ] Add memory tracking
- [ ] Write integration tests

## Required Knowledge
- TensorFlow Lite
- Flutter tflite plugin
- Unit testing

## Difficulty
🟡 Medium

## Time Estimate
4-6 hours

## Acceptance Criteria
- [ ] Adapter loads .tflite models
- [ ] Inference works correctly
- [ ] Memory tracking implemented
- [ ] Tests pass (minimum 80% coverage)

## Resources
- tflite_flutter: https://pub.dev/packages/tflite_flutter
- AIModelAdapter interface: lib/src/adapters/model_adapter.dart
''',
      },
      {
        'title': 'Thermal Throttle Injector',
        'labels': ['good first issue', 'enhancement'],
        'body': '''
## Description
Simulate thermal throttling of the device CPU/GPU.

## Tasks
- [ ] Create injector that simulates CPU/GPU throttling
- [ ] Detect performance degradation
- [ ] Add tests
- [ ] Document thermal simulation approach

## Files to Create
- `lib/src/injectors/thermal_throttle_injector.dart`
- `test/injectors/thermal_throttle_test.dart`

## Implementation Hints
- Simulate throttling by introducing artificial delays
- Track inference time degradation
- Use device info to get CPU temperature (optional)

## Difficulty
🟢 Easy

## Time Estimate
2-3 hours

## Resources
- Existing injectors: lib/src/injectors/
- device_info_plus: https://pub.dev/packages/device_info_plus
''',
      },
      {
        'title': 'Add Confidence Score Validation',
        'labels': ['good first issue', 'enhancement'],
        'body': '''
## Description
Add confidence score validation to detect model degradation.

## Tasks
- [ ] Track confidence scores over time
- [ ] Detect when confidence drops below threshold
- [ ] Report confidence degradation
- [ ] Add tests

## Files to Create
- `lib/src/monitors/confidence_monitor.dart`
- `test/monitors/confidence_monitor_test.dart`

## Implementation Hints
- Extend AIModelAdapter to track confidence
- Use rolling window for detection
- Add configuration for threshold

## Difficulty
🟢 Easy

## Time Estimate
2-3 hours
''',
      },
      {
        'title': 'Create Web Dashboard for Reports',
        'labels': ['good first issue', 'enhancement'],
        'body': '''
## Description
Create a web dashboard to visualize stress test reports.

## Tasks
- [ ] Parse JSON reports
- [ ] Display test results
- [ ] Show memory usage graphs
- [ ] Export reports

## Files to Create
- `web/index.html`
- `web/dashboard.js`

## Required Knowledge
- HTML/CSS/JavaScript
- JSON parsing
- Chart.js or similar

## Difficulty
🔴 Hard

## Time Estimate
8-10 hours

## Acceptance Criteria
- [ ] Dashboard loads JSON reports
- [ ] Shows pass/fail status
- [ ] Displays memory usage chart
- [ ] Responsive design
''',
      },
    ];
  }

  /// Setup GitHub Labels
  Future<void> _setupLabels() async {
    final labels = {
      'good first issue': '#7057ff',
      'help wanted': '#008672',
      'enhancement': '#a2eeef',
      'bug': '#d73a4a',
      'documentation': '#0075ca',
      'testing': '#f9d0c4',
      'hacktoberfest': '#d93f0b',
    };

    for (final entry in labels.entries) {
      await _createLabel(entry.key, entry.value);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('✅ Setup ${labels.length} labels');
  }

  /// Create a label
  Future<void> _createLabel(String name, String color) async {
    final url = Uri.parse('$githubApiUrl/labels');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $githubToken',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'color': color.substring(1), // Remove # from hex
        'description': 'Generated by automation script',
      }),
    );

    if (response.statusCode == 201) {
      print('  ✓ Created label: $name');
    } else if (response.statusCode == 422) {
      print('  ℹ️ Label already exists: $name');
    } else {
      print('  ✗ Failed to create label: $name - ${response.statusCode}');
    }
  }

  /// Create Project Board
  Future<void> _createProjectBoard() async {
    final url = Uri.parse('https://api.github.com/repos/$repoOwner/$repoName/projects');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $githubToken',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': 'SATE AI Development',
        'body': 'Project board for tracking SATE AI development',
        'columns': [
          {'name': '📋 Backlog'},
          {'name': '🔍 Research'},
          {'name': '🏗️ In Progress'},
          {'name': '👀 Review'},
          {'name': '✅ Done'},
        ],
      }),
    );

    if (response.statusCode == 201) {
      print('✅ Project board created successfully');
    } else {
      print('⚠️ Project board creation failed: ${response.statusCode}');
      print('  Response: ${response.body}');
    }
  }

  /// Enable Discussions
  Future<void> _enableDiscussions() async {
    // Note: This requires GitHub API v3 with discussions
    // You may need to enable this manually
    print('ℹ️ Discussions must be enabled manually in Settings → General → Features');
    print('   https://github.com/$repoOwner/$repoName/settings');
  }

  /// Generate Social Media Posts
  void _generateSocialMediaPosts() {
    print('\n' + '=' * 80);
    print('📢 SOCIAL MEDIA POSTS (Copy & Paste)');
    print('=' * 80);

    // Twitter/X Thread
    print('\n🐦 TWITTER/X THREAD:');
    print('-' * 40);
    print('''
🧵 SATE AI is now LIVE on GitHub!

A fault injection framework for testing on-device AI models in Flutter.

✅ 59 tests passing
✅ 0 lint issues  
✅ Memory & malformed input injectors
✅ Mock adapter for CI/CD
✅ Dark theme demo app

GitHub: https://github.com/$repoOwner/$repoName

1/🧵
''');

    print('''
The problem: On-device AI is exploding (Llama 3, Phi-3, Gemma) but NOBODY tests what happens when they fail.

Memory pressure? Garbage output? Quantization drift? All untested.

SATE AI changes that.

2/🧵
''');

    print('''
Built with:
- 100% Dart/Flutter
- 59 unit tests
- Plugin-based architecture
- Ready for contributors

First 7 "good first issues" are up!

3/🧵
''');

    print('''
Help me build the future of AI testing!

Star ⭐, share, or contribute: https://github.com/$repoOwner/$repoName

#Flutter #AI #Testing #MachineLearning #OpenSource
''');

    // LinkedIn Post
    print('\n💼 LINKEDIN POST:');
    print('-' * 40);
    print('''
🚀 I'm thrilled to announce that SATE AI is now open source on GitHub!

What is SATE AI?
A fault injection framework for testing on-device AI models in Flutter.

Why I built this:
On-device AI is exploding, but there's NO tooling to test reliability.
When your model runs on a phone, it WILL fail:
- Memory pressure → OOM
- Malformed input → Crashes
- Quantization drift → Garbage outputs

SATE AI catches these BEFORE your users do.

📊 Stats:
✅ 59 passing tests
✅ 0 lint issues
✅ Mock adapter for CI/CD
✅ Dark theme demo app

👥 Looking for contributors!
First 7 "good first issues" are ready.

🔗 https://github.com/$repoOwner/$repoName

Let's make on-device AI testing a standard practice! 🎯

#Flutter #AI #MachineLearning #OpenSource #SoftwareTesting #DevCommunity
''');

    // Reddit Post
    print('\n🔴 REDDIT POST (r/FlutterDev):');
    print('-' * 40);
    print('''
Title: [Showcase] SATE AI - Fault injection for on-device AI models in Flutter

Text:
I built a framework to test what happens when your AI model fails on user devices.

What it does:
- ✅ Memory pressure simulation (OOM prevention testing)
- ✅ Malformed input injection (crash testing)
- ✅ Mock adapter for CI/CD (test without real models)
- ✅ Dark theme demo app
- ✅ 7 Good First Issues ready for contributors

Technical details:
- 59 passing tests
- 0 lint issues
- MIT license
- Ready for contributors

GitHub: https://github.com/$repoOwner/$repoName

Would love feedback from the community! What other fault types should I add?

#Flutter #AI #Testing
''');

    // Show HN Post
    print('\n📰 SHOW HN POST:');
    print('-' * 40);
    print('''
Title: SATE AI - Fault injection for on-device AI models in Flutter

Text:
I've been building on-device AI apps and realized NOBODY tests what happens when models fail.

Memory pressure? Garbage output? Quantization drift? All untested.

So I built SATE AI - a fault injection framework that simulates real-world failures.

Features:
- 59 passing tests
- Zero lint issues
- Mock adapter for testing
- Plugin-based architecture
- 7 Good First Issues for contributors

Works with any AI model adapter (ONNX, TFLite, Fllama, etc.)

Would love feedback from the community!

https://github.com/$repoOwner/$repoName
''');

    print('\n' + '=' * 80);
    print('📋 Don\'t forget to:');
    print('1. Replace [YOUR_TOKEN] with your GitHub token');
    print('2. Review all generated content before posting');
    print('3. Add personal touches to social media posts');
    print('=' * 80);
  }
}

/// Main entry point
Future<void> main() async {
  // Load environment variables
  final env = DotEnv()..load();
  
  // Get GitHub token from environment or prompt
  String? token = env['GITHUB_TOKEN'];
  if (token == null) {
    stdout.write('🔑 Enter your GitHub Personal Access Token: ');
    token = stdin.readLineSync()!;
  }

  if (token.isEmpty) {
    print('❌ GitHub token is required!');
    print('Create one at: https://github.com/settings/tokens');
    print('Required scopes: repo, project, write:discussion');
    exit(1);
  }

  final automator = SATEAICommunityAutomator(
    githubToken: token,
  );

  await automator.run();
}
