import { FaultResult } from './FaultResult.js';
import { FaultType, FAULT_TYPE_DISPLAY } from './FaultType.js';

export interface Failure {
  injectorType: FaultType;
  message: string;
}

export interface StressReportOptions {
  modelId: string;
  passed: boolean;
  results: FaultResult[];
  failures: Failure[];
  startTimeIso: string;
  endTimeIso: string;
  totalDurationMs: number;
}

export class StressReport {
  readonly modelId: string;
  readonly passed: boolean;
  readonly results: FaultResult[];
  readonly failures: Failure[];
  readonly startTimeIso: string;
  readonly endTimeIso: string;
  readonly totalDurationMs: number;

  constructor(options: StressReportOptions) {
    this.modelId = options.modelId;
    this.passed = options.passed;
    this.results = options.results;
    this.failures = options.failures;
    this.startTimeIso = options.startTimeIso;
    this.endTimeIso = options.endTimeIso;
    this.totalDurationMs = options.totalDurationMs;
  }

  get passCount(): number {
    return this.results.filter((r) => r.passed).length;
  }

  get failureCount(): number {
    return this.results.filter((r) => !r.passed).length;
  }

  toJSON(): Record<string, unknown> {
    return {
      modelId: this.modelId,
      passed: this.passed,
      results: this.results.map((r) => r.toJSON()),
      failures: this.failures,
      startTimeIso: this.startTimeIso,
      endTimeIso: this.endTimeIso,
      totalDurationMs: this.totalDurationMs,
    };
  }

  toJSONString(): string {
    return JSON.stringify(this.toJSON(), null, 2);
  }

  toMarkdown(): string {
    const lines: string[] = [];
    lines.push(`# SATE AI Stress Report: ${this.modelId}`);
    lines.push('');
    lines.push(`- Status: ${this.passed ? 'PASS' : 'FAIL'}`);
    lines.push(`- Total tests: ${this.results.length}`);
    lines.push(`- Passed: ${this.passCount}`);
    lines.push(`- Failed: ${this.failureCount}`);
    lines.push(`- Duration: ${this.totalDurationMs}ms`);
    lines.push('');
    lines.push('## Results');
    for (const r of this.results) {
      const display = FAULT_TYPE_DISPLAY[r.injectorType];
      const status = r.passed ? 'PASS' : 'FAIL';
      const err = r.errorMessage ? ` (${r.errorMessage})` : '';
      lines.push(`- ${display}: ${status}${err}`);
    }
    return lines.join('\n');
  }

  static fromJSON(json: Record<string, unknown>): StressReport {
    return new StressReport({
      modelId: json.modelId as string,
      passed: json.passed as boolean,
      results: (json.results as Record<string, unknown>[]).map((r) =>
        new FaultResult({
          injectorType: r.injectorType as FaultType,
          passed: r.passed as boolean,
          inferenceTimeMs: r.inferenceTimeMs as number | undefined,
          memoryUsageMB: r.memoryUsageMB as number | undefined,
          errorMessage: r.errorMessage as string | undefined,
        }),
      ),
      failures: json.failures as Failure[],
      startTimeIso: json.startTimeIso as string,
      endTimeIso: json.endTimeIso as string,
      totalDurationMs: json.totalDurationMs as number,
    });
  }
}
