import { describe, it, expect, vi } from 'vitest';
import { AIInput } from '@sate-ai/core';
import { ONNXAdapter } from '../src/index.js';

describe('ONNXAdapter', () => {
  it('executes inference on ONNX session run', async () => {
    const mockSession = {
      run: vi.fn().mockResolvedValue({
        output: {
          data: new Float32Array([0.91, 0.09]),
        },
      }),
      inputNames: ['input_ids'],
      outputNames: ['output'],
      release: vi.fn().mockResolvedValue(undefined),
    };

    const adapter = new ONNXAdapter({
      modelId: 'bert-tiny-onnx',
      session: mockSession,
    });

    expect(adapter.modelId).toBe('bert-tiny-onnx');
    expect(adapter.currentMemoryMB).toBe(0);
    expect(adapter.isDegraded).toBe(false);

    const output = await adapter.runInference(new AIInput({ text: 'text sequence' }));
    expect(mockSession.run).toHaveBeenCalledWith({
      input_ids: 'text sequence',
    });
    expect(output.confidence).toBeCloseTo(0.91);
    expect(output.text).toContain('0.9100');

    await adapter.release();
    expect(mockSession.release).toHaveBeenCalled();
  });

  it('handles simulated memory pressure and degrades above 150MB', async () => {
    const mockSession = {
      run: vi.fn().mockResolvedValue({
        output: {
          data: new Float32Array([0.95]),
        },
      }),
    };

    const adapter = new ONNXAdapter({
      modelId: 'resnet50-onnx',
      session: mockSession,
    });

    await adapter.simulateMemoryPressure(180);
    expect(adapter.currentMemoryMB).toBe(180);
    expect(adapter.isDegraded).toBe(true);
    expect(await adapter.isHealthy()).toBe(false);

    const output = await adapter.runInference(new AIInput({ text: 'sample' }));
    expect(output.text).toContain('Degraded');
    expect(output.confidence).toBe(0.3);

    await adapter.reset();
    expect(adapter.isDegraded).toBe(false);
    expect(adapter.currentMemoryMB).toBe(0);
  });

  it('wraps execution failure in AIInferenceError', async () => {
    const mockSession = {
      run: vi.fn().mockRejectedValue(new Error('CUDA device out of memory')),
    };

    const adapter = new ONNXAdapter({
      modelId: 'error-model',
      session: mockSession,
    });

    await expect(
      adapter.runInference(new AIInput({ text: 'failing sample' })),
    ).rejects.toThrow('CUDA device out of memory');
  });
});
