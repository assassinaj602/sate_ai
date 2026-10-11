package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class DataCorruptionInjector(
    private val model: ModelAdapter,
    private val corruptionIntensity: Double = 0.1,
) : FaultInjector {
    override val type = FaultType.DATA_CORRUPTION
    override val name = "Data Corruption Injector"
    override val description = "Injects noise/corruption into input payloads with intensity $corruptionIntensity"

    override suspend fun inject() {
        model.simulateMemoryPressure((corruptionIntensity * 100).toInt())
    }

    override suspend fun reset() {
        model.reset()
    }
}
