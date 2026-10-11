import { describe, it, expect } from 'vitest';
import { ThermalThrottleInjector, MockModelAdapter, FaultType } from '../../src/index.js';

describe('ThermalThrottleInjector', () => {
  it('simulates temperature step and triggers pressure on model', async () => {
    const model = new MockModelAdapter();
    const injector = new ThermalThrottleInjector({ model, temperatureStep: 15 });
    expect(injector.type).toBe(FaultType.ThermalThrottle);
    expect(injector.name).toBe('Thermal Throttle Injector');

    await injector.inject();
    expect(model.currentMemoryMB).toBe(15);

    await injector.reset();
    expect(model.currentMemoryMB).toBe(0);
  });
});
