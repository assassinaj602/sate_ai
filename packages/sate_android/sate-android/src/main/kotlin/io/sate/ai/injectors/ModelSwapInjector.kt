package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class ModelSwapInjector(
    private val model: ModelAdapter,
    private val initialQuality: Double = 1.0,
    private val qualityDegradation: Double = 0.1,
    private val qualityThreshold: Double = 0.3,
) : FaultInjector {
    override val type = FaultType.MODEL_SWAP
    override val name = "Model Swap Injector"
    override val description = "Simulates model swap corruption with quality degradation of $qualityDegradation"

    override suspend fun inject() {
        model.simulateMemoryPressure(20)
    }

    override suspend fun reset() {
        model.reset()
    }
}
