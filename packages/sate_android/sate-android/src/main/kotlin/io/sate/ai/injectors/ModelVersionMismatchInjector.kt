package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class ModelVersionMismatchInjector(
    private val model: ModelAdapter,
    private val expectedVersion: String = "2.0.0",
    private val actualVersion: String = "1.0.0",
) : FaultInjector {
    override val type = FaultType.MODEL_VERSION_MISMATCH
    override val name = "Model Version Mismatch Injector"
    override val description = "Simulates mismatch between expected ($expectedVersion) and actual ($actualVersion) versions"

    override suspend fun inject() {
        model.simulateMemoryPressure(25)
    }

    override suspend fun reset() {
        model.reset()
    }
}
