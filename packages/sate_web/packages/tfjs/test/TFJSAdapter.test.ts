import { describe, it, expect, vi } from 'vitest';
import { AIInput } from '@sate-ai/core';
import { TFJSAdapter } from '../src/index.js';

describe('TFJSAdapter', () => {
  it('executes inference on model predict function', async () => {
    const mockModel = {
      predict: vi.fn().mockReturnValue({
        dataSync: () => new Float32Array([0.88, 0.12]),
      }),
      dispose: vi.fn(),
    };

    const adapter = new TFJSAdapter({
      modelId: 'mobilenet-v2',
      model: mockModel,
    });

    expect(adapter.modelId).toBe('mobilenet-v2');
    expect(adapter.currentMemoryMB).toBe(0);
    expect(adapter.isDegraded).toBe(false);

    const output = await adapter.runInference(new AIInput({ text: 'image-probe' }));
    expect(mockModel.predict).toHaveBeenCalled();
    expect(output.confidence).toBeCloseTo(0.88);
    expect(output.text).toContain('0.8800');

    await adapter.dispose();
    expect(mockModel.dispose).toHaveBeenCalled();
  });

  it('handles simulated memory pressure and degrades above 150MB', async () => {
    const mockModel = {
      predict: vi.fn().mockReturnValue({
        dataSync: () => new Float32Array([0.9]),
      }),
    };

    const adapter = new TFJSAdapter({
      modelId: 'mobilenet-v2',
      model: mockModel,
    });

    await adapter.simulateMemoryPressure(160);
    expect(adapter.currentMemoryMB).toBe(160);
    expect(adapter.isDegraded).toBe(true);
    expect(await adapter.isHealthy()).toBe(false);

    const output = await adapter.runInference(new AIInput({ text: 'probe' }));
    expect(output.text).toContain('Degraded');
    expect(output.confidence).toBe(0.35);

    await adapter.reset();
    expect(adapter.isDegraded).toBe(false);
    expect(adapter.currentMemoryMB).toBe(0);
  });

  it('handles model execution errors with AIInferenceError', async () => {
    const mockModel = {
      predict: vi.fn().mockImplementation(() => {
        throw new Error('WebGL context lost');
      }),
    };

    const adapter = new TFJSAdapter({
      modelId: 'broken-model',
      model: mockModel,
    });

    await expect(
      adapter.runInference(new AIInput({ text: 'probe' })),
    ).rejects.toThrow('WebGL context lost');
  });
});
