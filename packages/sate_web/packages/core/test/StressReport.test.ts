import { describe, it, expect } from 'vitest';
import { StressReport, FaultResult, FaultType, FAULT_TYPE_DISPLAY } from '../src/index.js';

describe('StressReport', () => {
  it('computes summary, passCount, failureCount correctly for clean run', () => {
    const report = new StressReport({
      modelId: 'test-model',
      passed: true,
      results: [
        new FaultResult({
          injectorType: FaultType.MemoryPressure,
          passed: true,
          inferenceTimeMs: 40,
        }),
        new FaultResult({
          injectorType: FaultType.Latency,
          passed: true,
          inferenceTimeMs: 15,
        }),
      ],
      failures: [],
      startTimeIso: new Date().toISOString(),
      endTimeIso: new Date().toISOString(),
      totalDurationMs: 120,
    });

    expect(report.passed).toBe(true);
    expect(report.modelId).toBe('test-model');
    expect(report.results.length).toBe(2);
    expect(report.passCount).toBe(2);
    expect(report.failureCount).toBe(0);
    expect(report.failures.length).toBe(0);
  });

  it('computes summary correctly for failed run', () => {
    const report = new StressReport({
      modelId: 'failing-model',
      passed: false,
      results: [
        new FaultResult({
          injectorType: FaultType.MemoryPressure,
          passed: false,
          errorMessage: 'OOM detected',
        }),
        new FaultResult({
          injectorType: FaultType.MalformedInput,
          passed: true,
        }),
      ],
      failures: [
        {
          injectorType: FaultType.MemoryPressure,
          message: 'OOM detected',
        },
      ],
      startTimeIso: new Date().toISOString(),
      endTimeIso: new Date().toISOString(),
      totalDurationMs: 250,
    });

    expect(report.passed).toBe(false);
    expect(report.results.length).toBe(2);
    expect(report.passCount).toBe(1);
    expect(report.failureCount).toBe(1);
    expect(report.failures.length).toBe(1);
  });

  it('serializes to JSON format and deserializes back', () => {
    const report = new StressReport({
      modelId: 'json-model',
      passed: true,
      results: [
        new FaultResult({
          injectorType: FaultType.ThermalThrottle,
          passed: true,
          inferenceTimeMs: 30,
        }),
      ],
      failures: [],
      startTimeIso: '2026-01-01T00:00:00.000Z',
      endTimeIso: '2026-01-01T00:00:01.000Z',
      totalDurationMs: 1000,
    });

    const json = report.toJSON();
    expect(json.modelId).toBe('json-model');
    expect(json.passed).toBe(true);
    expect(Array.isArray(json.results)).toBe(true);

    const jsonString = report.toJSONString();
    expect(typeof jsonString).toBe('string');

    const reconstructed = StressReport.fromJSON(json);
    expect(reconstructed.modelId).toBe('json-model');
    expect(reconstructed.passed).toBe(true);
    expect(reconstructed.results.length).toBe(1);
  });

  it('renders a Markdown report', () => {
    const report = new StressReport({
      modelId: 'md-model',
      passed: true,
      results: [
        new FaultResult({
          injectorType: FaultType.ModelSwap,
          passed: true,
        }),
      ],
      failures: [],
      startTimeIso: new Date().toISOString(),
      endTimeIso: new Date().toISOString(),
      totalDurationMs: 80,
    });

    const md = report.toMarkdown();
    expect(md).toContain('# SATE AI Stress Report: md-model');
    expect(md).toContain(FAULT_TYPE_DISPLAY[FaultType.ModelSwap]);
    expect(md).toContain('PASS');
  });
});
