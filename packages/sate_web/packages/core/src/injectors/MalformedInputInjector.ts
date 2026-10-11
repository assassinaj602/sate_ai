import { FaultInjector } from '../FaultInjector.js';
import { FaultType } from '../FaultType.js';

export class MalformedInputInjector implements FaultInjector {
  readonly type = FaultType.MalformedInput;
  readonly name = 'Malformed Input Injector';
  readonly description = 'Injects empty, oversized, and binary garbage inputs';

  async inject(): Promise<void> {}
  async reset(): Promise<void> {}
}
