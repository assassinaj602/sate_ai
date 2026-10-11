import { describe, it, expect } from 'vitest';
import { ConfidenceThresholdInjector, MockModelAdapter, FaultType } from '../../src/index.js';

describe('ConfidenceThresholdInjector', () => {
  it('injects threshold pressure and resets successfully', async () => {
    const model = new MockModelAdapter();
    const injector = new ConfidenceThresholdInjector({ model, threshold: 0.8 });
    expect(injector.type).toBe(FaultType.ConfidenceValidation);
    expect(injector.name).toBe('Confidence Threshold Injector');

    await injector.inject();
    expect(model.currentMemoryMB).toBe(10);

    await injector.reset();
    expect(model.currentMemoryMB).toBe(0);
  });
});
