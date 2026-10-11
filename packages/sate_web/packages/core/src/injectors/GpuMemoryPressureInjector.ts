import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';
import { ModelAdapter } from '../ModelAdapter.js';

export interface GpuMemoryPressureInjectorOptions {
  model: ModelAdapter;
  limitMb?: number;
}

export class GpuMemoryPressureInjector implements FaultInjector {
  readonly type = FaultType.GpuMemoryPressure;
  readonly name = 'GPU Memory Pressure Injector';
  readonly description: string;
  private readonly model: ModelAdapter;
  private readonly limitMb: number;

  constructor(options: GpuMemoryPressureInjectorOptions) {
    this.model = options.model;
    this.limitMb = options.limitMb ?? 100;
    this.description = `Simulates GPU VRAM pressure of ${this.limitMb} MB`;
  }

  async inject(): Promise<void> {
    await this.model.simulateMemoryPressure(this.limitMb);
  }

  async reset(): Promise<void> {
    await this.model.reset();
  }
}
