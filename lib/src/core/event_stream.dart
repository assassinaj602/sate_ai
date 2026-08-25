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
  /// The type of stress event.
  final StressEventType type;

  /// Timestamp when the event occurred.
  final DateTime timestamp;

  /// Constructs a [StressEvent].
  StressEvent({
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Converts the event to a JSON map.
  Map<String, dynamic> toJson();
}

/// Event emitted when the test starts.
class StartedEvent extends StressEvent {
  /// ID of the model being tested.
  final String modelId;

  /// Names of injectors to be run.
  final List<String> injectorNames;

  /// Total count of injectors.
  final int totalInjectors;

  /// Constructs a [StartedEvent].
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
  /// Name of the injector starting.
  final String injectorName;

  /// Current 0-based index of the injector.
  final int index;

  /// Total count of injectors.
  final int total;

  /// Constructs an [InjectorStartingEvent].
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
  /// Name of the completed injector.
  final String injectorName;

  /// Whether the injector test passed.
  final bool passed;

  /// Inference time in milliseconds if available.
  final int? inferenceTimeMs;

  /// Memory usage in MB if available.
  final double? memoryUsageMB;

  /// Error message if degraded/failed.
  final String? errorMessage;

  /// Constructs an [InjectorCompleteEvent].
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
  /// Name of the injector that errored.
  final String injectorName;

  /// Error string description.
  final String error;

  /// Constructs an [InjectorErrorEvent].
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
  /// Log message string.
  final String message;

  /// Log level string (e.g., info, error).
  final String level;

  /// Constructs a [LogEvent].
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
  /// Overall pass/fail status.
  final bool passed;

  /// Total number of tests run.
  final int totalTests;

  /// Number of tests passed.
  final int passedCount;

  /// Number of tests failed.
  final int failedCount;

  /// Total test duration in milliseconds.
  final int durationMs;

  /// Constructs a [FinishedEvent].
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
