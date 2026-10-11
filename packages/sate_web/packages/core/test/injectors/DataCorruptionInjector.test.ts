import { describe, it, expect } from 'vitest';
import { DataCorruptionInjector, MockModelAdapter, FaultType } from '../../src/index.js';

describe('DataCorruptionInjector', () => {
  it('injects corruption pressure and resets', async () => {
    const model = new MockModelAdapter();
    const injector = new DataCorruptionInjector({ model, corruptionIntensity: 0.3 });
    expect(injector.type).toBe(FaultType.DataCorruption);
    expect(injector.name).toBe('Data Corruption Injector');

    await injector.inject();
    expect(model.currentMemoryMB).toBe(30);

    await injector.reset();
    expect(model.currentMemoryMB).toBe(0);
  });
});
