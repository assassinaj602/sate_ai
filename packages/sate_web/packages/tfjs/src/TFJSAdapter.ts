import {
  ModelAdapter,
  AIInput,
  AIOutput,
  AIInferenceError,
} from '@sate-ai/core';

export interface TFJSTensorLike {
  dataSync?: () => Float32Array | Int32Array | number[];
  data?: () => Promise<Float32Array | Int32Array | number[]>;
  dispose?: () => void;
  shape?: number[];
}

export interface TFJSModelLike {
  predict?: (inputs: unknown) => unknown;
  execute?: (inputs: unknown) => unknown;
  dispose?: () => void;
}

export interface TFJSAdapterOptions {
  modelId: string;
  model: TFJSModelLike;
  inputShape?: number[];
  warmupRuns?: number;
}

export class TFJSAdapter implements ModelAdapter {
  readonly modelId: string;
  private readonly model: TFJSModelLike;
  private readonly inputShape: number[];
  private simulatedMemoryMB = 0;
  private degraded = false;

  constructor(options: TFJSAdapterOptions) {
    this.modelId = options.modelId;
    this.model = options.model;
    this.inputShape = options.inputShape ?? [1, 224, 224, 3];
  }

  get currentMemoryMB(): number {
    return this.simulatedMemoryMB;
  }

  get isDegraded(): boolean {
    return this.degraded;
  }

  async runInference(input: AIInput): Promise<AIOutput> {
    const start = Date.now();
    try {
      if (this.degraded) {
        await new Promise((resolve) => setTimeout(resolve, 100));
        return new AIOutput({
          text: 'Degraded TFJS prediction',
          inferenceTimeMs: Date.now() - start,
          confidence: 0.35,
        });
      }

      let predictionResult: unknown;
      const rawInput = input.binary ?? input.text;
      if (typeof this.model.predict === 'function') {
        predictionResult = this.model.predict(rawInput);
      } else if (typeof this.model.execute === 'function') {
        predictionResult = this.model.execute(rawInput);
      } else {
        predictionResult = null;
      }

      let confidence = 0.95;
      let outputText = 'Prediction completed';

      if (predictionResult && typeof predictionResult === 'object') {
        const tensorResult = predictionResult as TFJSTensorLike;
        if (typeof tensorResult.dataSync === 'function') {
          const data = tensorResult.dataSync();
          if (data && data.length > 0) {
            confidence = Number(data[0]);
            outputText = `Predicted: ${confidence.toFixed(4)}`;
          }
        }
      }

      return new AIOutput({
        text: outputText,
        inferenceTimeMs: Math.max(1, Date.now() - start),
        confidence,
      });
    } catch (err) {
      throw new AIInferenceError(
        `TFJS inference failed: ${err instanceof Error ? err.message : String(err)}`,
        err,
      );
    }
  }

  async simulateMemoryPressure(mb: number): Promise<void> {
    this.simulatedMemoryMB += mb;
    if (this.simulatedMemoryMB > 150) {
      this.degraded = true;
    }
  }

  async reset(): Promise<void> {
    this.simulatedMemoryMB = 0;
    this.degraded = false;
  }

  async isHealthy(): Promise<boolean> {
    return !this.degraded && this.simulatedMemoryMB < 150;
  }

  async dispose(): Promise<void> {
    if (typeof this.model.dispose === 'function') {
      this.model.dispose();
    }
  }
}
