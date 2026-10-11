package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class NetworkLatencyDropInjector(
    private val model: ModelAdapter,
    private val dropProbability: Double = 0.2,
) : FaultInjector {
    override val type = FaultType.NETWORK_FAILURE
    override val name = "Network Latency Drop Injector"
    override val description = "Simulates network packet drop and latency with probability $dropProbability"

    override suspend fun inject() {
        model.simulateMemoryPressure((dropProbability * 100).toInt())
    }

    override suspend fun reset() {
        model.reset()
    }
}
