import { describe, it, expect } from 'vitest';
import { MemoryPressureInjector, MockModelAdapter, FaultType } from '../../src/index.js';

describe('MemoryPressureInjector', () => {
  it('initializes with properties and executes inject and reset', async () => {
    const model = new MockModelAdapter();
    const injector = new MemoryPressureInjector({ model, limitMb: 50 });
    expect(injector.type).toBe(FaultType.MemoryPressure);
    expect(injector.name).toBe('Memory Pressure Injector');
    expect(injector.description).toContain('50 MB');

    await injector.inject();
    expect(model.currentMemoryMB).toBe(50);

    await injector.reset();
    expect(model.currentMemoryMB).toBe(0);
  });
});
