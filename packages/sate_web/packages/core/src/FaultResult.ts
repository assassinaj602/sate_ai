import { FaultType } from './FaultType.js';

export interface FaultResultOptions {
  injectorType: FaultType;
  passed: boolean;
  inferenceTimeMs?: number;
  memoryUsageMB?: number;
  errorMessage?: string;
}

export class FaultResult {
  readonly injectorType: FaultType;
  readonly passed: boolean;
  readonly inferenceTimeMs: number | undefined;
  readonly memoryUsageMB: number | undefined;
  readonly errorMessage: string | undefined;

  constructor(options: FaultResultOptions) {
    this.injectorType = options.injectorType;
    this.passed = options.passed;
    this.inferenceTimeMs = options.inferenceTimeMs;
    this.memoryUsageMB = options.memoryUsageMB;
    this.errorMessage = options.errorMessage;
  }

  toJSON(): Record<string, unknown> {
    return {
      injectorType: this.injectorType,
      passed: this.passed,
      inferenceTimeMs: this.inferenceTimeMs,
      memoryUsageMB: this.memoryUsageMB,
      errorMessage: this.errorMessage,
    };
  }
}
