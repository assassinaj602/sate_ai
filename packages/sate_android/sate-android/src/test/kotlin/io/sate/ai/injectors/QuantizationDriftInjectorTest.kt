package io.sate.ai.injectors

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class QuantizationDriftInjectorTest {
    @Test
    fun testMetadata() {
        val model = MockModelAdapter()
        val injector = QuantizationDriftInjector(model, driftFactor = 0.2)
        assertEquals(FaultType.QUANTIZATION_DRIFT, injector.type)
        assertEquals("Quantization Drift Injector", injector.name)
        assertTrue(injector.description.contains("0.2"))
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val model = MockModelAdapter()
        val injector = QuantizationDriftInjector(model, driftFactor = 4.0)
        injector.inject()
        assertTrue(model.isDegraded)
        injector.reset()
        assertTrue(!model.isDegraded)
    }
}
