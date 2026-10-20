# Video 2: Adding a Custom Injector

> **Episode**: 02 of 05  
> **Target Duration**: 4 minutes 15 seconds  
> **Level**: Intermediate  
> **Topics**: The FaultInjector Interface, Lifecycle Methods (setUp, inject, tearDown), Building a BatteryDrainInjector  

---

## 📋 Production Script & Timeline

| Time | Segment | Visual On Screen | Audio / Narration |
| :---: | :--- | :--- | :--- |
| **00:00 - 00:35** | **Introduction** | Architecture diagram highlighting `FaultInjector` contract. | "Welcome back to Episode 2. SATE AI ships with 12 built-in injectors, but every edge system has unique hardware constraints. In this video, you will learn how to build your own custom fault injector in less than fifty lines of code." |
| **00:35 - 01:30** | **The Lifecycle** | Visual flow showing `setUp()` -> `inject()` -> `tearDown()`. | "Every injector in SATE AI extends the `FaultInjector` base class and adheres to a strict three-phase lifecycle: `setUp` prepares background stress before tests begin, `inject` intercepts and mutates input tensors right before inference, and `tearDown` cleans up resources to ensure no leaks between test cases." |
| **01:30 - 03:00** | **Implementing BatteryDrainInjector** | Writing the class in Dart with background Isolate execution. | "Let us build a `BatteryDrainInjector`. In `setUp`, we spin up a background worker compute isolate that performs matrix computations to simulate high CPU draw. In `inject`, we verify whether the model adjusts its execution frequency. In `tearDown`, we cleanly terminate the isolate." |
| **03:00 - 03:50** | **Integration Testing** | Running `flutter test test/battery_drain_test.dart`. | "Now we wire our custom injector directly into `StressRunner`. When we run the test suite, notice how SATE AI automatically orchestrates the isolate lifecycle and collects telemetry alongside all built-in metrics." |
| **03:50 - 04:15** | **Outro & Next Episode** | Graphic card promoting Episode 3: Custom Model Adapters. | "You now have the power to simulate any hardware failure mode you can imagine. In Episode 3, we flip the coin and learn how to connect custom machine learning runtimes using `AIModelAdapter`." |

---

## 💻 Code Example: Implementing a Custom Injector

```dart
import 'dart:async';
import 'dart:isolate';
import 'package:sate_core/sate_core.dart';

/// Simulates high battery discharge by keeping background CPU cores active.
class BatteryDrainInjector extends FaultInjector {
  final int workerThreads;
  final List<Isolate> _activeWorkers = [];
  bool _isRunning = false;

  BatteryDrainInjector({this.workerThreads = 2});

  @override
  String get name => 'BatteryDrainInjector';

  @override
  Future<void> setUp() async {
    _isRunning = true;
    for (int i = 0; i < workerThreads; i++) {
      final isolate = await Isolate.spawn(_spinWorker, _isRunning);
      _activeWorkers.add(isolate);
    }
  }

  @override
  Future<Map<String, dynamic>> inject(Map<String, dynamic> input) async {
    // Optionally tag telemetry with artificial battery status
    final modifiedInput = Map<String, dynamic>.from(input);
    modifiedInput['_battery_level'] = 0.08; // 8% critical battery state
    return modifiedInput;
  }

  @override
  Future<void> tearDown() async {
    _isRunning = false;
    for (final worker in _activeWorkers) {
      worker.kill(priority: Isolate.immediate);
    }
    _activeWorkers.clear();
  }

  static void _spinWorker(bool running) {
    while (running) {
      // Burn lightweight compute cycles to emulate heavy background discharge
      int acc = 0;
      for (int i = 0; i < 50000; i++) {
        acc += i;
      }
    }
  }
}
```

---

## 🎙️ Complete Voiceover Transcript

**[00:00]** Welcome back. While SATE AI provides injectors for memory, temperature, and corrupted tensors, real-world edge devices often face unique sensor and hardware anomalies.

**[00:35]** To build a custom injector, you implement three core methods: `setUp`, `inject`, and `tearDown`. The `setUp` method initializes background conditions. The `inject` method mutates inputs or applies delays. The `tearDown` method guarantees clean resource deallocation.

**[01:30]** In this example, we construct a `BatteryDrainInjector`. We spawn background isolates during `setUp` to simulate CPU core load, flag low-battery states in the payload during `inject`, and terminate all worker threads safely in `tearDown`.

**[03:00]** We attach our custom injector to `StressRunner`, and it integrates seamlessly with the rest of our test suite.

**[03:50]** Next time, we will explore connecting custom ML runtimes like PyTorch Mobile or custom C++ engines via `AIModelAdapter`.
