package io.sate.ai.injectors

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ThermalThrottleInjectorTest {
    @Test
    fun testMetadata() {
        val model = MockModelAdapter()
        val injector = ThermalThrottleInjector(model, temperatureStep = 15, maxTemperature = 90)
        assertEquals(FaultType.THERMAL_THROTTLE, injector.type)
        assertEquals("Thermal Throttle Injector", injector.name)
        assertTrue(injector.description.contains("90"))
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val model = MockModelAdapter()
        val injector = ThermalThrottleInjector(model, temperatureStep = 200)
        injector.inject()
        assertTrue(model.isDegraded)
        injector.reset()
        assertTrue(!model.isDegraded)
    }
}
