package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class LatencyInjector(
    private val model: ModelAdapter,
    private val baseDelayMs: Long = 10,
    private val incrementMs: Long = 5,
    private val maxLatencyMs: Long = 50,
) : FaultInjector {
    override val type = FaultType.LATENCY
    override val name = "Latency Injector"
    override val description = "Simulates increasing latency by ${incrementMs}ms up to ${maxLatencyMs}ms"

    override suspend fun inject() {
        model.simulateMemoryPressure(incrementMs.toInt())
    }

    override suspend fun reset() {
        model.reset()
    }
}
