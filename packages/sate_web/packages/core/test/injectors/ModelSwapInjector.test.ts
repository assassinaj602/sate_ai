import { describe, it, expect } from 'vitest';
import { ModelSwapInjector, MockModelAdapter, FaultType } from '../../src/index.js';

describe('ModelSwapInjector', () => {
  it('injects model swap pressure and resets successfully', async () => {
    const model = new MockModelAdapter();
    const injector = new ModelSwapInjector({ model, qualityDegradation: 0.2 });
    expect(injector.type).toBe(FaultType.ModelSwap);
    expect(injector.name).toBe('Model Swap Injector');

    await injector.inject();
    expect(model.currentMemoryMB).toBe(20);

    await injector.reset();
    expect(model.currentMemoryMB).toBe(0);
  });
});
