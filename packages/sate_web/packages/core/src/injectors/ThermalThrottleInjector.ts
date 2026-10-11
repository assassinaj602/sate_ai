import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';
import { ModelAdapter } from '../ModelAdapter.js';

export interface ThermalThrottleInjectorOptions {
  model: ModelAdapter;
  temperatureStep?: number;
  maxTemperature?: number;
}

export class ThermalThrottleInjector implements FaultInjector {
  readonly type = FaultType.ThermalThrottle;
  readonly name = 'Thermal Throttle Injector';
  readonly description: string;
  private readonly model: ModelAdapter;
  private readonly temperatureStep: number;

  constructor(options: ThermalThrottleInjectorOptions) {
    this.model = options.model;
    this.temperatureStep = options.temperatureStep ?? 10;
    const max = options.maxTemperature ?? 85;
    this.description = `Simulates CPU thermal throttling up to ${max}C in steps of ${this.temperatureStep}C`;
  }

  async inject(): Promise<void> {
    await this.model.simulateMemoryPressure(this.temperatureStep);
  }

  async reset(): Promise<void> {
    await this.model.reset();
  }
}
