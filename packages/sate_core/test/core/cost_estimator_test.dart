import 'package:sate_core/sate_core.dart';
import 'package:test/test.dart';

void main() {
  group('CostEstimator', () {
    test('returns zero cost when injectors list is empty', () {
      final model = MockAdapter(modelId: 'zero-test-model');
      const estimator = CostEstimator();

      final estimate = estimator.estimate(
        model: model,
        injectors: [],
      );

      expect(estimate.totalInjectors, equals(0));
      expect(estimate.estimatedDuration, equals(Duration.zero));
      expect(estimate.estimatedBatteryDrainMah, equals(0.0));
      expect(estimate.estimatedBatteryDrainPercent, equals(0.0));
      expect(estimate.estimatedInferenceCycles, equals(0));
    });

    test('calculates duration scaling with injector count and retries', () {
      final model = MockAdapter(modelId: 'duration-model');
      const estimator = CostEstimator(
        estimatedInferenceTime: Duration(milliseconds: 100),
      );

      final injectors = [
        MalformedInputInjector(),
        LatencyInjector(model: model),
      ];

      final estimateSingle = estimator.estimate(
        model: model,
        injectors: injectors,
        retryCount: 1,
      );

      final estimateRetry = estimator.estimate(
        model: model,
        injectors: injectors,
        retryCount: 3,
      );

      expect(estimateSingle.totalInjectors, equals(2));
      expect(estimateSingle.estimatedInferenceCycles, equals(2));
      expect(estimateRetry.estimatedInferenceCycles, equals(6));
      expect(estimateRetry.estimatedDuration,
          greaterThan(estimateSingle.estimatedDuration));
    });

    test('estimates peak memory accurately with MemoryPressureInjector', () {
      final model = MockAdapter(modelId: 'memory-model');
      const estimator = CostEstimator();

      final injectors = [
        MemoryPressureInjector(model: model, limitMb: 250),
        MalformedInputInjector(),
      ];

      final estimate = estimator.estimate(
        model: model,
        injectors: injectors,
      );

      // Baseline (min 10) + 250 MB
      expect(estimate.estimatedPeakMemoryMB, greaterThanOrEqualTo(250.0));
      expect(estimate.memoryUsagePercentage, greaterThan(0.0));
    });

    test('estimates peak memory with GpuMemoryPressureInjector', () {
      final model = MockAdapter(modelId: 'gpu-model');
      const estimator = CostEstimator();

      final injectors = [
        GpuMemoryPressureInjector(limitMb: 180),
      ];

      final estimate = estimator.estimate(
        model: model,
        injectors: injectors,
      );

      expect(estimate.estimatedPeakMemoryMB, greaterThanOrEqualTo(180.0));
    });

    test(
        'estimates battery consumption proportional to duration and hardware profile',
        () {
      final model = MockAdapter(modelId: 'battery-model');
      const mobileEstimator = CostEstimator(
        hardwareProfile: DeviceHardwareProfile.mobile,
      );
      const edgeEstimator = CostEstimator(
        hardwareProfile: DeviceHardwareProfile.edgeIoT,
      );

      final injectors = [
        MalformedInputInjector(),
        LatencyInjector(model: model),
        ThermalThrottleInjector(model: model),
      ];

      final mobileEstimate = mobileEstimator.estimate(
        model: model,
        injectors: injectors,
      );

      final edgeEstimate = edgeEstimator.estimate(
        model: model,
        injectors: injectors,
      );

      expect(mobileEstimate.estimatedBatteryDrainMah, greaterThan(0.0));
      expect(edgeEstimate.estimatedBatteryDrainMah, greaterThan(0.0));
      // Edge profile has higher inference current (1400mA vs 850mA), so drain rate is higher
      expect(edgeEstimate.estimatedBatteryDrainMah,
          greaterThan(mobileEstimate.estimatedBatteryDrainMah));
    });

    test('computes cloud cost when model is marked as cloud-hosted', () {
      final model = MockAdapter(modelId: 'cloud-llm');
      const estimator = CostEstimator(
        estimatedTokensPerInference: 500,
        cloudPricePerMillionTokensUsd: 2.0, // $2 per 1M tokens
      );

      final injectors = [
        MalformedInputInjector(),
        LatencyInjector(model: model),
      ];

      final estimateLocal = estimator.estimate(
        model: model,
        injectors: injectors,
        isCloudModel: false,
      );

      final estimateCloud = estimator.estimate(
        model: model,
        injectors: injectors,
        isCloudModel: true,
      );

      expect(estimateLocal.estimatedCloudCostUsd, equals(0.0));
      expect(estimateCloud.estimatedCloudCostUsd, greaterThan(0.0));
      expect(estimateCloud.estimatedTokenCount,
          equals(1000)); // 2 cycles * 500 tokens
    });

    test('serializes to JSON and reconstructs identically', () {
      final model = MockAdapter(modelId: 'json-model');
      const estimator = CostEstimator();

      final original = estimator.estimate(
        model: model,
        injectors: [
          MemoryPressureInjector(model: model, limitMb: 120),
          MalformedInputInjector(),
        ],
        isCloudModel: true,
      );

      final jsonMap = original.toJson();
      expect(jsonMap['modelId'], equals('json-model'));
      expect(jsonMap['totalInjectors'], equals(2));
      expect(jsonMap['estimatedPeakMemoryMB'], greaterThan(120.0));

      final restored = StressCostEstimate.fromJson(jsonMap);
      expect(restored.modelId, equals(original.modelId));
      expect(restored.totalInjectors, equals(original.totalInjectors));
      expect(restored.estimatedPeakMemoryMB,
          equals(original.estimatedPeakMemoryMB));
      expect(restored.estimatedBatteryDrainMah,
          closeTo(original.estimatedBatteryDrainMah, 0.001));
      expect(restored.estimatedCloudCostUsd,
          equals(original.estimatedCloudCostUsd));
    });

    test('formats Markdown table with all key estimate metrics and warnings',
        () {
      final model = MockAdapter(modelId: 'report-model');
      const estimator = CostEstimator(
        hardwareProfile: DeviceHardwareProfile(
          deviceTotalMemoryMb: 500.0, // Low memory to trigger warning
        ),
      );

      final estimate = estimator.estimate(
        model: model,
        injectors: [
          MemoryPressureInjector(model: model, limitMb: 450), // > 85% of 500MB
        ],
        isCloudModel: true,
      );

      final markdown = estimate.toMarkdown();
      expect(markdown, contains('# SATE AI Stress Test Cost Estimate'));
      expect(markdown, contains('Target Model:'));
      expect(markdown, contains('Projected Duration'));
      expect(markdown, contains('Peak Memory Usage'));
      expect(markdown, contains('Battery Consumption'));
      expect(markdown, contains('Cloud API Cost'));
      expect(markdown, contains('Warning:'));
    });

    test(
        'accounts for AdaptiveChaosInjector base interval in duration projection',
        () {
      final model = MockAdapter(modelId: 'adaptive-model');
      const estimator = CostEstimator(
        estimatedInferenceTime: Duration(milliseconds: 50),
      );

      final adaptiveInjector = AdaptiveChaosInjector(
        model: model,
        baseInterval: const Duration(milliseconds: 300),
      );

      final estimate = estimator.estimate(
        model: model,
        injectors: [adaptiveInjector],
      );

      // (50ms inference + 50ms overhead + 300ms baseInterval) + 200ms fixed runner overhead = 600ms
      expect(
          estimate.estimatedDuration.inMilliseconds, greaterThanOrEqualTo(500));
    });
  });
}
