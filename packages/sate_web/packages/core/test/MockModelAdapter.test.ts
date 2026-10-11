import { describe, it, expect } from 'vitest';
import { MockModelAdapter, AIInput } from '../src/index.js';

describe('MockModelAdapter', () => {
  it('runs inference with default config', async () => {
    const model = new MockModelAdapter();
    expect(model.modelId).toBe('mock-model');
    expect(model.currentMemoryMB).toBe(0);
    expect(model.isDegraded).toBe(false);

    const output = await model.runInference(new AIInput({ text: 'test query' }));
    expect(output.text).toContain('Hello from mock model');
    expect(output.confidence).toBe(0.95);
    expect(output.inferenceTimeMs).toBeGreaterThanOrEqual(0);
  });

  it('handles simulated memory pressure and degrades above 150MB', async () => {
    const model = new MockModelAdapter();
    await model.simulateMemoryPressure(50);
    expect(model.currentMemoryMB).toBe(50);
    expect(model.isDegraded).toBe(false);
    expect(await model.isHealthy()).toBe(true);

    await model.simulateMemoryPressure(110);
    expect(model.currentMemoryMB).toBe(160);
    expect(model.isDegraded).toBe(true);
    expect(await model.isHealthy()).toBe(false);

    const output = await model.runInference(new AIInput({ text: 'stress test' }));
    expect(output.text).toContain('Degraded output');
    expect(output.confidence).toBe(0.3);
  });

  it('resets state correctly', async () => {
    const model = new MockModelAdapter();
    await model.simulateMemoryPressure(200);
    expect(model.isDegraded).toBe(true);

    await model.reset();
    expect(model.currentMemoryMB).toBe(0);
    expect(model.isDegraded).toBe(false);
    expect(await model.isHealthy()).toBe(true);
  });
});
