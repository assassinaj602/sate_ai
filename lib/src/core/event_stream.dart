/// Events emitted during stress test execution.
enum StressEventType {
  /// Test is starting.
  started,

  /// An injector is about to run.
  injectorStarting,

  /// An injector has completed.
  injectorComplete,

  /// An error occurred during injection.
  injectorError,

  /// A log message from the test.
  log,

  /// The test has finished.
  finished,
}

/// Base class for all stress test events.
sealed class StressEvent {
  final StressEventType type;
  final DateTime timestamp;

  StressEvent({
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson();
}

/// Event emitted when the test starts.
class StartedEvent extends StressEvent {
  final String modelId;
  final List<String> injectorNames;
  final int totalInjectors;

  StartedEvent({
    required this.modelId,
    required this.injectorNames,
    required this.totalInjectors,
  }) : super(type: StressEventType.started);

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'modelId': modelId,
        'injectorNames': injectorNames,
        'totalInjectors': totalInjectors,
      };
}

/// Event emitted when an injector starts.
class InjectorStartingEvent extends StressEvent {
  final String injectorName;
  final int index;
  final int total;

  InjectorStartingEvent({
    required this.injectorName,
    required this.index,
    required this.total,
  }) : super(type: StressEventType.injectorStarting);

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'injectorName': injectorName,
        'index': index,
        'total': total,
      };
}

/// Event emitted when an injector completes.
class InjectorCompleteEvent extends StressEvent {
  final String injectorName;
  final bool passed;
  final int? inferenceTimeMs;
  final double? memoryUsageMB;
  final String? errorMessage;

  InjectorCompleteEvent({
    required this.injectorName,
    required this.passed,
    this.inferenceTimeMs,
    this.memoryUsageMB,
    this.errorMessage,
  }) : super(type: StressEventType.injectorComplete);

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'injectorName': injectorName,
        'passed': passed,
        'inferenceTimeMs': inferenceTimeMs,
        'memoryUsageMB': memoryUsageMB,
        'errorMessage': errorMessage,
      };
}

/// Event emitted when an injector errors.
class InjectorErrorEvent extends StressEvent {
  final String injectorName;
  final String error;

  InjectorErrorEvent({
    required this.injectorName,
    required this.error,
  }) : super(type: StressEventType.injectorError);

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'injectorName': injectorName,
        'error': error,
      };
}

/// Event emitted for log messages.
class LogEvent extends StressEvent {
  final String message;
  final String level;

  LogEvent({
    required this.message,
    this.level = 'info',
  }) : super(type: StressEventType.log);

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'level': level,
      };
}

/// Event emitted when the test finishes.
class FinishedEvent extends StressEvent {
  final bool passed;
  final int totalTests;
  final int passedCount;
  final int failedCount;
  final int durationMs;

  FinishedEvent({
    required this.passed,
    required this.totalTests,
    required this.passedCount,
    required this.failedCount,
    required this.durationMs,
  }) : super(type: StressEventType.finished);

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'timestamp': timestamp.toIso8601String(),
        'passed': passed,
        'totalTests': totalTests,
        'passedCount': passedCount,
        'failedCount': failedCount,
        'durationMs': durationMs,
      };
}

/// Type alias for event stream callbacks.
typedef EventCallback = void Function(StressEvent event);
