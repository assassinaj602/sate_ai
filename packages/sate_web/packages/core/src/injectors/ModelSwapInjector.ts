import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';
import { ModelAdapter } from '../ModelAdapter.js';

export interface ModelSwapInjectorOptions {
  model: ModelAdapter;
  qualityDegradation?: number;
}

export class ModelSwapInjector implements FaultInjector {
  readonly type = FaultType.ModelSwap;
  readonly name = 'Model Swap Injector';
  readonly description: string;
  private readonly model: ModelAdapter;
  private readonly qualityDegradation: number;

  constructor(options: ModelSwapInjectorOptions) {
    this.model = options.model;
    this.qualityDegradation = options.qualityDegradation ?? 0.1;
    this.description = `Simulates model swap corruption with quality degradation of ${this.qualityDegradation}`;
  }

  async inject(): Promise<void> {
    await this.model.simulateMemoryPressure(20);
  }

  async reset(): Promise<void> {
    await this.model.reset();
  }
}
