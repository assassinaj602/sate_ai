import { describe, it, expect } from 'vitest';
import {
  StressRunner,
  MockModelAdapter,
  MemoryPressureInjector,
  MalformedInputInjector,
} from '../src/index.js';

describe('StressRunner', () => {
  it('runs all injectors and produces a report', async () => {
    const model = new MockModelAdapter();
    const runner = new StressRunner({
      model,
      injectors: [
        new MemoryPressureInjector({ model, limitMb: 50 }),
        new MalformedInputInjector(),
      ],
    });
    const report = await runner.stress();
    expect(report.results.length).toBe(2);
    expect(report.passed).toBe(true);
  });

  it('detects memory pressure degradation', async () => {
    const model = new MockModelAdapter();
    const runner = new StressRunner({
      model,
      injectors: [new MemoryPressureInjector({ model, limitMb: 200 })],
    });
    const report = await runner.stress();
    expect(report.passed).toBe(false);
  });

  it('respects timeout', async () => {
    const model = new MockModelAdapter({ inferenceDelayMs: 500 });
    const runner = new StressRunner({
      model,
      injectors: [new MalformedInputInjector()],
      timeoutMs: 50,
    });
    const report = await runner.stress();
    expect(report.passed).toBe(false);
  });
});

