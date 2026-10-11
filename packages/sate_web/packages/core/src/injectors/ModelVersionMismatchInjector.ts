import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';
import { ModelAdapter } from '../ModelAdapter.js';

export interface ModelVersionMismatchInjectorOptions {
  model: ModelAdapter;
  expectedVersion?: string;
  actualVersion?: string;
}

export class ModelVersionMismatchInjector implements FaultInjector {
  readonly type = FaultType.ModelVersionMismatch;
  readonly name = 'Model Version Mismatch Injector';
  readonly description: string;
  private readonly model: ModelAdapter;

  constructor(options: ModelVersionMismatchInjectorOptions) {
    this.model = options.model;
    const exp = options.expectedVersion ?? '2.0.0';
    const act = options.actualVersion ?? '1.0.0';
    this.description = `Simulates mismatch between expected (${exp}) and actual (${act}) versions`;
  }

  async inject(): Promise<void> {
    await this.model.simulateMemoryPressure(25);
  }

  async reset(): Promise<void> {
    await this.model.reset();
  }
}
