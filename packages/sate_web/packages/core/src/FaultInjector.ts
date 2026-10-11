import { FaultType } from './FaultType.js';

export interface FaultInjector {
  readonly type: FaultType;
  readonly name: string;
  readonly description: string;

  inject(): Promise<void>;
  reset(): Promise<void>;
}
