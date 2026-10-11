package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class ConfidenceThresholdInjector(
    private val model: ModelAdapter,
    private val threshold: Double = 0.7,
) : FaultInjector {
    override val type = FaultType.CONFIDENCE_VALIDATION
    override val name = "Confidence Threshold Injector"
    override val description = "Fails if model confidence drops below $threshold"

    override suspend fun inject() {
        model.simulateMemoryPressure(10)
    }

    override suspend fun reset() {
        model.reset()
    }
}
