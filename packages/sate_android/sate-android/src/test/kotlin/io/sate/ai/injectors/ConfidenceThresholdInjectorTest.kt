package io.sate.ai.injectors

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ConfidenceThresholdInjectorTest {
    @Test
    fun testMetadata() {
        val model = MockModelAdapter()
        val injector = ConfidenceThresholdInjector(model, threshold = 0.8)
        assertEquals(FaultType.CONFIDENCE_VALIDATION, injector.type)
        assertEquals("Confidence Threshold Injector", injector.name)
        assertTrue(injector.description.contains("0.8"))
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val model = MockModelAdapter()
        val injector = ConfidenceThresholdInjector(model)
        injector.inject()
        assertTrue(model.currentMemoryMB > 0)
        injector.reset()
        assertEquals(0.0, model.currentMemoryMB)
    }
}
