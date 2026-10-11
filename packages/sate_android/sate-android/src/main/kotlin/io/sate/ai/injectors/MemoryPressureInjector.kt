package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class MemoryPressureInjector(
    private val model: ModelAdapter,
    private val limitMb: Int = 100,
) : FaultInjector {
    override val type = FaultType.MEMORY_PRESSURE
    override val name = "Memory Pressure Injector"
    override val description = "Allocates $limitMb MB to simulate memory pressure"

    override suspend fun inject() {
        model.simulateMemoryPressure(limitMb)
    }

    override suspend fun reset() {
        model.reset()
    }
}
