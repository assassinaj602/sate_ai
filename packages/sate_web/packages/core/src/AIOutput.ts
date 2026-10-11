export interface AIOutputOptions {
  text: string;
  inferenceTimeMs: number;
  confidence?: number;
  metadata?: Record<string, string>;
}

export class AIOutput {
  readonly text: string;
  readonly inferenceTimeMs: number;
  readonly confidence: number | undefined;
  readonly metadata: Record<string, string>;

  constructor(options: AIOutputOptions) {
    this.text = options.text;
    this.inferenceTimeMs = options.inferenceTimeMs;
    this.confidence = options.confidence;
    this.metadata = options.metadata ?? {};
  }

  toJSON(): Record<string, unknown> {
    return {
      text: this.text,
      inferenceTimeMs: this.inferenceTimeMs,
      confidence: this.confidence,
      metadata: this.metadata,
    };
  }
}
