import { describe, it, expect } from 'vitest';
import { NetworkLatencyDropInjector, MockModelAdapter, FaultType } from '../../src/index.js';

describe('NetworkLatencyDropInjector', () => {
  it('injects network latency drop and resets', async () => {
    const model = new MockModelAdapter();
    const injector = new NetworkLatencyDropInjector({ model, dropProbability: 0.3 });
    expect(injector.type).toBe(FaultType.NetworkFailure);
    expect(injector.name).toBe('Network Latency Drop Injector');

    await injector.inject();
    expect(model.currentMemoryMB).toBe(30);

    await injector.reset();
    expect(model.currentMemoryMB).toBe(0);
  });
});
