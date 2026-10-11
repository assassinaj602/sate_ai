package io.sate.ai.core

import io.sate.ai.adapters.ModelAdapter
import kotlinx.coroutines.withTimeoutOrNull
import java.time.Instant

class StressRunner(
    private val model: ModelAdapter,
    private val injectors: List<FaultInjector>,
    private val timeoutMs: Long = 30_000,
) {
    suspend fun run(): StressReport {
        val start = Instant.now()
        val results = mutableListOf<FaultResult>()
        val failures = mutableListOf<Failure>()
        var allPassed = true

        for (injector in injectors) {
            try {
                val result = withTimeoutOrNull(timeoutMs) {
                    runOne(injector)
                } ?: FaultResult(
                    injectorType = injector.type,
                    passed = false,
                    errorMessage = "Timeout after ${timeoutMs}ms",
                )
                results.add(result)
                if (!result.passed) allPassed = false
            } catch (e: Exception) {
                allPassed = false
                failures.add(Failure(injector.type, e.message ?: "unknown error"))
                results.add(FaultResult(injector.type, passed = false, errorMessage = e.message))
            } finally {
                injector.reset()
            }
        }

        val end = Instant.now()
        return StressReport(
            modelId = model.modelId,
            passed = allPassed,
            results = results,
            failures = failures,
            startTimeIso = start.toString(),
            endTimeIso = end.toString(),
            totalDurationMs = end.toEpochMilli() - start.toEpochMilli(),
        )
    }

    private suspend fun runOne(injector: FaultInjector): FaultResult {
        injector.inject()
        val inferenceStart = System.currentTimeMillis()
        val output = model.runInference(AIInput(text = "stress-test-probe"))
        val inferenceMs = System.currentTimeMillis() - inferenceStart
        val degraded = model.isDegraded
        return FaultResult(
            injectorType = injector.type,
            passed = !degraded,
            inferenceTimeMs = inferenceMs,
            memoryUsageMB = model.currentMemoryMB.takeIf { it > 0 },
            errorMessage = if (degraded) "Model entered degraded state" else null,
        )
    }
}
