import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';
import { ModelAdapter } from '../ModelAdapter.js';

export interface ConfidenceThresholdInjectorOptions {
  model: ModelAdapter;
  threshold?: number;
}

export class ConfidenceThresholdInjector implements FaultInjector {
  readonly type = FaultType.ConfidenceValidation;
  readonly name = 'Confidence Threshold Injector';
  readonly description: string;
  private readonly model: ModelAdapter;
  private readonly threshold: number;

  constructor(options: ConfidenceThresholdInjectorOptions) {
    this.model = options.model;
    this.threshold = options.threshold ?? 0.7;
    this.description = `Fails if model confidence drops below ${this.threshold}`;
  }

  async inject(): Promise<void> {
    await this.model.simulateMemoryPressure(10);
  }

  async reset(): Promise<void> {
    await this.model.reset();
  }
}
