import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';
import { ModelAdapter } from '../ModelAdapter.js';

export interface DataCorruptionInjectorOptions {
  model: ModelAdapter;
  corruptionIntensity?: number;
}

export class DataCorruptionInjector implements FaultInjector {
  readonly type = FaultType.DataCorruption;
  readonly name = 'Data Corruption Injector';
  readonly description: string;
  private readonly model: ModelAdapter;
  private readonly corruptionIntensity: number;

  constructor(options: DataCorruptionInjectorOptions) {
    this.model = options.model;
    this.corruptionIntensity = options.corruptionIntensity ?? 0.1;
    this.description = `Injects noise/corruption into input payloads with intensity ${this.corruptionIntensity}`;
  }

  async inject(): Promise<void> {
    await this.model.simulateMemoryPressure(Math.floor(this.corruptionIntensity * 100));
  }

  async reset(): Promise<void> {
    await this.model.reset();
  }
}
