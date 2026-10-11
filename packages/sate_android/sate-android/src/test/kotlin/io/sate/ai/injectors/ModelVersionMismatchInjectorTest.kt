package io.sate.ai.injectors

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class ModelVersionMismatchInjectorTest {
    @Test
    fun testMetadata() {
        val model = MockModelAdapter()
        val injector = ModelVersionMismatchInjector(model, expectedVersion = "3.0.0", actualVersion = "2.0.0")
        assertEquals(FaultType.MODEL_VERSION_MISMATCH, injector.type)
        assertEquals("Model Version Mismatch Injector", injector.name)
        assertTrue(injector.description.contains("3.0.0"))
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val model = MockModelAdapter()
        val injector = ModelVersionMismatchInjector(model)
        injector.inject()
        assertTrue(model.currentMemoryMB > 0)
        injector.reset()
        assertEquals(0.0, model.currentMemoryMB)
    }
}
