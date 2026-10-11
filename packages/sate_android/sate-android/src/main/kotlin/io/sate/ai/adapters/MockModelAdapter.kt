package io.sate.ai.adapters

import io.sate.ai.core.AIInput
import io.sate.ai.core.AIOutput
import kotlinx.coroutines.delay

class MockModelAdapter(
    override val modelId: String = "mock-model",
    private val inferenceDelayMs: Long = 50,
) : ModelAdapter {
    private var memoryMB: Double = 0.0
    private var degraded: Boolean = false

    override val currentMemoryMB: Double get() = memoryMB
    override val isDegraded: Boolean get() = degraded

    override suspend fun runInference(input: AIInput): AIOutput {
        delay(inferenceDelayMs)
        if (degraded) {
            return AIOutput(
                text = "Degraded output for: ${input.text ?: "binary"}",
                inferenceTimeMs = inferenceDelayMs * 2,
                confidence = 0.3,
            )
        }
        return AIOutput(
            text = "Hello from mock model: ${input.text ?: "binary"}",
            inferenceTimeMs = inferenceDelayMs,
            confidence = 0.95,
        )
    }

    override suspend fun simulateMemoryPressure(mb: Int) {
        memoryMB += mb
        if (memoryMB > 150) degraded = true
    }

    override suspend fun reset() {
        memoryMB = 0.0
        degraded = false
    }

    override suspend fun isHealthy(): Boolean = !degraded && memoryMB < 150
}
