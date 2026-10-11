import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';
import { ModelAdapter } from '../ModelAdapter.js';

export interface MemoryPressureInjectorOptions {
  model: ModelAdapter;
  limitMb?: number;
}

export class MemoryPressureInjector implements FaultInjector {
  readonly type = FaultType.MemoryPressure;
  readonly name = 'Memory Pressure Injector';
  readonly description: string;
  private readonly model: ModelAdapter;
  private readonly limitMb: number;

  constructor(options: MemoryPressureInjectorOptions) {
    this.model = options.model;
    this.limitMb = options.limitMb ?? 100;
    this.description = `Allocates ${this.limitMb} MB to simulate memory pressure`;
  }

  async inject(): Promise<void> {
    await this.model.simulateMemoryPressure(this.limitMb);
  }

  async reset(): Promise<void> {
    await this.model.reset();
  }
}
