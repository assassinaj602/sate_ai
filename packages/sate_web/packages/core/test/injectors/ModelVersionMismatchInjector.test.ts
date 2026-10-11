import { describe, it, expect } from 'vitest';
import { ModelVersionMismatchInjector, MockModelAdapter, FaultType } from '../../src/index.js';

describe('ModelVersionMismatchInjector', () => {
  it('injects version mismatch pressure and resets', async () => {
    const model = new MockModelAdapter();
    const injector = new ModelVersionMismatchInjector({ model, expectedVersion: '2.0.0', actualVersion: '1.0.0' });
    expect(injector.type).toBe(FaultType.ModelVersionMismatch);
    expect(injector.name).toBe('Model Version Mismatch Injector');

    await injector.inject();
    expect(model.currentMemoryMB).toBe(25);

    await injector.reset();
    expect(model.currentMemoryMB).toBe(0);
  });
});
