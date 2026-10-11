import { AIInput } from './AIInput.js';
import { AIOutput } from './AIOutput.js';
import { ModelAdapter } from './ModelAdapter.js';

export interface MockModelAdapterOptions {
  modelId?: string;
  inferenceDelayMs?: number;
}

export class MockModelAdapter implements ModelAdapter {
  readonly modelId: string;
  private readonly inferenceDelayMs: number;
  private memoryMB = 0;
  private degraded = false;

  constructor(options: MockModelAdapterOptions = {}) {
    this.modelId = options.modelId ?? 'mock-model';
    this.inferenceDelayMs = options.inferenceDelayMs ?? 50;
  }

  get currentMemoryMB(): number {
    return this.memoryMB;
  }

  get isDegraded(): boolean {
    return this.degraded;
  }

  async runInference(input: AIInput): Promise<AIOutput> {
    await new Promise((resolve) => setTimeout(resolve, this.inferenceDelayMs));
    if (this.degraded) {
      return new AIOutput({
        text: `Degraded output for: ${input.text ?? 'binary'}`,
        inferenceTimeMs: this.inferenceDelayMs * 2,
        confidence: 0.3,
      });
    }
    return new AIOutput({
      text: `Hello from mock model: ${input.text ?? 'binary'}`,
      inferenceTimeMs: this.inferenceDelayMs,
      confidence: 0.95,
    });
  }

  async simulateMemoryPressure(mb: number): Promise<void> {
    this.memoryMB += mb;
    if (this.memoryMB > 150) this.degraded = true;
  }

  async reset(): Promise<void> {
    this.memoryMB = 0;
    this.degraded = false;
  }

  async isHealthy(): Promise<boolean> {
    return !this.degraded && this.memoryMB < 150;
  }
}
