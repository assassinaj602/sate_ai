import { AIInput } from './AIInput.js';
import { AIOutput } from './AIOutput.js';

export interface ModelAdapter {
  readonly modelId: string;
  readonly currentMemoryMB: number;
  readonly isDegraded: boolean;

  runInference(input: AIInput): Promise<AIOutput>;
  simulateMemoryPressure(mb: number): Promise<void>;
  reset(): Promise<void>;
  isHealthy(): Promise<boolean>;
}

export class AIInferenceError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = 'AIInferenceError';
  }
}
