import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';

export interface QuantizationDriftInjectorOptions {
  driftFactor?: number;
  degradationThreshold?: number;
}

export class QuantizationDriftInjector implements FaultInjector {
  readonly type = FaultType.QuantizationDrift;
  readonly name = 'Quantization Drift Injector';
  readonly description: string;
  private currentConfidence = 1.0;
  private readonly driftFactor: number;
  private readonly degradationThreshold: number;

  constructor(options: QuantizationDriftInjectorOptions = {}) {
    this.driftFactor = options.driftFactor ?? 0.1;
    this.degradationThreshold = options.degradationThreshold ?? 0.3;
    this.description = `Gradually reduces confidence by ${this.driftFactor}`;
  }

  async inject(): Promise<void> {
    this.currentConfidence = Math.max(0, this.currentConfidence - this.driftFactor);
  }

  async reset(): Promise<void> {
    this.currentConfidence = 1.0;
  }

  get isDegraded(): boolean {
    return this.currentConfidence < this.degradationThreshold;
  }
}
