import { describe, it, expect } from 'vitest';
import { MalformedInputInjector, FaultType } from '../../src/index.js';

describe('MalformedInputInjector', () => {
  it('initializes with properties and executes without throwing', async () => {
    const injector = new MalformedInputInjector();
    expect(injector.type).toBe(FaultType.MalformedInput);
    expect(injector.name).toBe('Malformed Input Injector');
    expect(injector.description).toBeDefined();

    await expect(injector.inject()).resolves.toBeUndefined();
    await expect(injector.reset()).resolves.toBeUndefined();
  });
});
