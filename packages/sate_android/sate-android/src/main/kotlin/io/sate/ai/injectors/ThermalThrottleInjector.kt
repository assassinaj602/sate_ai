package io.sate.ai.injectors

import io.sate.ai.adapters.ModelAdapter
import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class ThermalThrottleInjector(
    private val model: ModelAdapter,
    private val temperatureStep: Int = 10,
    private val maxTemperature: Int = 85,
) : FaultInjector {
    override val type = FaultType.THERMAL_THROTTLE
    override val name = "Thermal Throttle Injector"
    override val description = "Simulates CPU thermal throttling up to ${maxTemperature}C in steps of ${temperatureStep}C"

    override suspend fun inject() {
        model.simulateMemoryPressure(temperatureStep)
    }

    override suspend fun reset() {
        model.reset()
    }
}
