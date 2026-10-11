package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class GpuMemoryPressureInjector(
    private val model: ModelAdapter,
    private val limitMb: Int = 100,
) : FaultInjector {
    override val type = FaultType.GPU_MEMORY_PRESSURE
    override val name = "GPU Memory Pressure Injector"
    override val description = "Simulates GPU VRAM pressure of $limitMb MB"

    override suspend fun inject() {
        model.simulateMemoryPressure(limitMb)
    }

    override suspend fun reset() {
        model.reset()
    }
}
