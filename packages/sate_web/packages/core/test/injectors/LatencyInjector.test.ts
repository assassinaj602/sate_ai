import { describe, it, expect } from 'vitest';
import { LatencyInjector, MockModelAdapter, FaultType } from '../../src/index.js';

describe('LatencyInjector', () => {
  it('initializes and injects latency pressure', async () => {
    const model = new MockModelAdapter();
    const injector = new LatencyInjector({ model, incrementMs: 10, maxLatencyMs: 100 });
    expect(injector.type).toBe(FaultType.Latency);
    expect(injector.name).toBe('Latency Injector');

    await injector.inject();
    expect(model.currentMemoryMB).toBe(10);

    await injector.reset();
    expect(model.currentMemoryMB).toBe(0);
  });
});
