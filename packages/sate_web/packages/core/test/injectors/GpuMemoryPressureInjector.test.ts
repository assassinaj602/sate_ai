import { describe, it, expect } from 'vitest';
import { GpuMemoryPressureInjector, MockModelAdapter, FaultType } from '../../src/index.js';

describe('GpuMemoryPressureInjector', () => {
  it('injects GPU memory pressure and resets', async () => {
    const model = new MockModelAdapter();
    const injector = new GpuMemoryPressureInjector({ model, limitMb: 120 });
    expect(injector.type).toBe(FaultType.GpuMemoryPressure);
    expect(injector.name).toBe('GPU Memory Pressure Injector');

    await injector.inject();
    expect(model.currentMemoryMB).toBe(120);

    await injector.reset();
    expect(model.currentMemoryMB).toBe(0);
  });
});
