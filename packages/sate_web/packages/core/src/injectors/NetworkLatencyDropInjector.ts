import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';
import { ModelAdapter } from '../ModelAdapter.js';

export interface NetworkLatencyDropInjectorOptions {
  model: ModelAdapter;
  dropProbability?: number;
}

export class NetworkLatencyDropInjector implements FaultInjector {
  readonly type = FaultType.NetworkFailure;
  readonly name = 'Network Latency Drop Injector';
  readonly description: string;
  private readonly model: ModelAdapter;
  private readonly dropProbability: number;

  constructor(options: NetworkLatencyDropInjectorOptions) {
    this.model = options.model;
    this.dropProbability = options.dropProbability ?? 0.2;
    this.description = `Simulates network packet drop and latency with probability ${this.dropProbability}`;
  }

  async inject(): Promise<void> {
    await this.model.simulateMemoryPressure(Math.floor(this.dropProbability * 100));
  }

  async reset(): Promise<void> {
    await this.model.reset();
  }
}
