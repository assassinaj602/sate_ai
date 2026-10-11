import {
  ModelAdapter,
  AIInput,
  AIOutput,
  AIInferenceError,
} from '@sate-ai/core';

export interface ONNXTensorLike {
  data: Float32Array | Int32Array | BigInt64Array | Uint8Array | number[];
  dims?: readonly number[];
  type?: string;
  size?: number;
}

export type ONNXFeedsLike = Record<string, ONNXTensorLike | unknown>;
export type ONNXFetchesLike = Record<string, ONNXTensorLike>;

export interface ONNXInferenceSessionLike {
  run: (feeds: ONNXFeedsLike) => Promise<ONNXFetchesLike>;
  inputNames?: readonly string[];
  outputNames?: readonly string[];
  release?: () => Promise<void>;
}

export interface ONNXAdapterOptions {
  modelId: string;
  session: ONNXInferenceSessionLike;
  inputName?: string;
  outputName?: string;
}

export class ONNXAdapter implements ModelAdapter {
  readonly modelId: string;
  private readonly session: ONNXInferenceSessionLike;
  private readonly inputName: string;
  private readonly outputName: string;
  private simulatedMemoryMB = 0;
  private degraded = false;

  constructor(options: ONNXAdapterOptions) {
    this.modelId = options.modelId;
    this.session = options.session;
    this.inputName = options.inputName ?? options.session.inputNames?.[0] ?? 'input';
    this.outputName = options.outputName ?? options.session.outputNames?.[0] ?? 'output';
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
          text: 'Degraded ONNX prediction',
          inferenceTimeMs: Date.now() - start,
          confidence: 0.3,
        });
      }

      const rawInput = input.binary ?? input.text;
      const feeds: ONNXFeedsLike = {
        [this.inputName]: rawInput,
      };

      const results = await this.session.run(feeds);
      let confidence = 0.95;
      let outputText = 'ONNX inference successful';

      const outputTensor = results[this.outputName] ?? Object.values(results)[0];
      if (outputTensor && outputTensor.data) {
        const data = outputTensor.data;
        if (data.length > 0) {
          confidence = Number(data[0]);
          outputText = `ONNX output: ${confidence.toFixed(4)}`;
        }
      }

      return new AIOutput({
        text: outputText,
        inferenceTimeMs: Math.max(1, Date.now() - start),
        confidence,
      });
    } catch (err) {
      throw new AIInferenceError(
        `ONNX inference failed: ${err instanceof Error ? err.message : String(err)}`,
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

  async release(): Promise<void> {
    if (typeof this.session.release === 'function') {
      await this.session.release();
    }
  }
}
