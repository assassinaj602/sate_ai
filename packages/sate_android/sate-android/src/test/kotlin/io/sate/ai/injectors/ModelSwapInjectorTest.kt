package io.sate.ai.injectors

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ModelSwapInjectorTest {
    @Test
    fun testMetadata() {
        val model = MockModelAdapter()
        val injector = ModelSwapInjector(model, qualityDegradation = 0.15)
        assertEquals(FaultType.MODEL_SWAP, injector.type)
        assertEquals("Model Swap Injector", injector.name)
        assertTrue(injector.description.contains("0.15"))
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val model = MockModelAdapter()
        val injector = ModelSwapInjector(model)
        injector.inject()
        assertTrue(model.currentMemoryMB > 0)
        injector.reset()
        assertEquals(0.0, model.currentMemoryMB)
    }
}
