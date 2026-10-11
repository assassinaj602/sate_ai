package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class QuantizationDriftInjector(
    private val model: ModelAdapter,
    private val driftFactor: Double = 0.1,
) : FaultInjector {
    override val type = FaultType.QUANTIZATION_DRIFT
    override val name = "Quantization Drift Injector"
    override val description = "Simulates numerical quantization drift with factor $driftFactor"

    override suspend fun inject() {
        model.simulateMemoryPressure((driftFactor * 50).toInt())
    }

    override suspend fun reset() {
        model.reset()
    }
}
