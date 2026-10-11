import { describe, it, expect } from 'vitest';
import { QuantizationDriftInjector, FaultType } from '../../src/index.js';

describe('QuantizationDriftInjector', () => {
  it('gradually reduces confidence upon injection and can reset', async () => {
    const injector = new QuantizationDriftInjector({ driftFactor: 0.2, degradationThreshold: 0.5 });
    expect(injector.type).toBe(FaultType.QuantizationDrift);
    expect(injector.name).toBe('Quantization Drift Injector');
    expect(injector.isDegraded).toBe(false);

    await injector.inject();
    await injector.inject();
    await injector.inject();
    expect(injector.isDegraded).toBe(true);

    await injector.reset();
    expect(injector.isDegraded).toBe(false);
  });
});
