import { AIInput } from './AIInput.js';
import { FaultInjector } from './FaultInjector.js';
import { FaultResult } from './FaultResult.js';
import { ModelAdapter } from './ModelAdapter.js';
import { StressReport, Failure } from './StressReport.js';

export interface StressRunnerOptions {
  model: ModelAdapter;
  injectors: FaultInjector[];
  timeoutMs?: number;
}

export class StressRunner {
  private readonly model: ModelAdapter;
  private readonly injectors: FaultInjector[];
  private readonly timeoutMs: number;

  constructor(options: StressRunnerOptions) {
    this.model = options.model;
    this.injectors = options.injectors;
    this.timeoutMs = options.timeoutMs ?? 30000;
  }

  async stress(): Promise<StressReport> {
    const start = new Date();
    const results: FaultResult[] = [];
    const failures: Failure[] = [];
    let allPassed = true;

    for (const injector of this.injectors) {
      try {
        const result = await this.runOneWithTimeout(injector);
        results.push(result);
        if (!result.passed) allPassed = false;
      } catch (err) {
        allPassed = false;
        failures.push({
          injectorType: injector.type,
          message: err instanceof Error ? err.message : String(err),
        });
        results.push(
          new FaultResult({
            injectorType: injector.type,
            passed: false,
            errorMessage: err instanceof Error ? err.message : String(err),
          }),
        );
      } finally {
        await injector.reset();
      }
    }

    const end = new Date();
    return new StressReport({
      modelId: this.model.modelId,
      passed: allPassed,
      results,
      failures,
      startTimeIso: start.toISOString(),
      endTimeIso: end.toISOString(),
      totalDurationMs: end.getTime() - start.getTime(),
    });
  }

  private async runOneWithTimeout(injector: FaultInjector): Promise<FaultResult> {
    let timer: NodeJS.Timeout;
    const timeoutPromise = new Promise<never>((_, reject) => {
      timer = setTimeout(() => reject(new Error(`Timeout after ${this.timeoutMs}ms`)), this.timeoutMs);
    });
    try {
      return await Promise.race([this.runOne(injector), timeoutPromise]);
    } finally {
      clearTimeout(timer!);
    }
  }

  private async runOne(injector: FaultInjector): Promise<FaultResult> {
    await injector.inject();
    const start = Date.now();
    await this.model.runInference(new AIInput({ text: 'stress-test-probe' }));
    const inferenceMs = Date.now() - start;
    const degraded = this.model.isDegraded;
    return new FaultResult({
      injectorType: injector.type,
      passed: !degraded,
      inferenceTimeMs: inferenceMs,
      memoryUsageMB: this.model.currentMemoryMB > 0 ? this.model.currentMemoryMB : undefined,
      errorMessage: degraded ? 'Model entered degraded state' : undefined,
    });
  }
}
