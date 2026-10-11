export interface AIInputOptions {
  text?: string;
  binary?: Uint8Array;
  metadata?: Record<string, string>;
}

export class AIInput {
  readonly text: string | undefined;
  readonly binary: Uint8Array | undefined;
  readonly metadata: Record<string, string>;

  constructor(options: AIInputOptions) {
    if (!options.text && !options.binary) {
      throw new Error('Either text or binary must be provided');
    }
    this.text = options.text;
    this.binary = options.binary;
    this.metadata = options.metadata ?? {};
  }
}
