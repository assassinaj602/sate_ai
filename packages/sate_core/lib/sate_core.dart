/// SATE AI pure Dart core.
///
/// Framework-agnostic fault injection, stress testing, and reporting
/// for on-device AI models. No Flutter dependency.
library sate_core;

// Core types
export 'src/core/fault_type.dart';
export 'src/core/fault_injector.dart';
export 'src/core/report.dart';
export 'src/core/stress_runner.dart';
export 'src/core/event_stream.dart';
export 'src/core/stress_scheduler.dart';
export 'src/core/report_comparator.dart';
export 'src/core/batch_runner.dart';
export 'src/core/benchmark_report.dart';
export 'src/core/health_check_result.dart';
export 'src/core/badge_generator.dart';
export 'src/core/badge_type.dart';
export 'src/core/baseline_manager.dart';
export 'src/core/inference_profiler.dart';
export 'src/core/metric_deviation.dart';
export 'src/core/model_factory.dart';
export 'src/core/model_type_detector.dart';
export 'src/core/profile_result.dart';
export 'src/core/report_database.dart';
export 'src/core/template_engine.dart';
export 'src/core/template_loader.dart';
export 'src/core/webhook_payload.dart';
export 'src/core/webhook_notifier.dart';
export 'src/core/quantization_report.dart';

// Adapters
export 'src/adapters/model_adapter.dart';
export 'src/adapters/mock_adapter.dart';

// Injectors
export 'src/injectors/memory_pressure_injector.dart';
export 'src/injectors/malformed_input_injector.dart';
export 'src/injectors/quantization_drift_injector.dart';
export 'src/injectors/thermal_throttle_injector.dart';
export 'src/injectors/latency_injector.dart';
export 'src/injectors/model_swap_injector.dart';
export 'src/injectors/confidence_threshold_injector.dart';
export 'src/injectors/gpu_memory_pressure_injector.dart';
export 'src/injectors/data_corruption_injector.dart';
export 'src/injectors/model_version_mismatch_injector.dart';
export 'src/injectors/network_latency_drop_injector.dart';

// Analyzers
export 'src/core/analyzers/quantization_analyzer.dart';
export 'src/core/analyzers/onnx_analyzer.dart';
export 'src/core/analyzers/tflite_analyzer.dart';

// i18n
export 'src/i18n/i18n.dart';
export 'src/i18n/report_language.dart';
export 'src/i18n/report_localizer.dart';
