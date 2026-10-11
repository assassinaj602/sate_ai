import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';
import { ModelAdapter } from '../ModelAdapter.js';

export interface LatencyInjectorOptions {
  model: ModelAdapter;
  baseDelayMs?: number;
  incrementMs?: number;
  maxLatencyMs?: number;
}

export class LatencyInjector implements FaultInjector {
  readonly type = FaultType.Latency;
  readonly name = 'Latency Injector';
  readonly description: string;
  private readonly model: ModelAdapter;
  private readonly incrementMs: number;

  constructor(options: LatencyInjectorOptions) {
    this.model = options.model;
    this.incrementMs = options.incrementMs ?? 5;
    const max = options.maxLatencyMs ?? 50;
    this.description = `Simulates increasing latency by ${this.incrementMs}ms up to ${max}ms`;
  }

  async inject(): Promise<void> {
    await this.model.simulateMemoryPressure(this.incrementMs);
  }

  async reset(): Promise<void> {
    await this.model.reset();
  }
}
