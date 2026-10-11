package io.sate.ai.injectors

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class DataCorruptionInjectorTest {
    @Test
    fun testMetadata() {
        val model = MockModelAdapter()
        val injector = DataCorruptionInjector(model, corruptionIntensity = 0.25)
        assertEquals(FaultType.DATA_CORRUPTION, injector.type)
        assertEquals("Data Corruption Injector", injector.name)
        assertTrue(injector.description.contains("0.25"))
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val model = MockModelAdapter()
        val injector = DataCorruptionInjector(model, corruptionIntensity = 2.0)
        injector.inject()
        assertTrue(model.isDegraded)
        injector.reset()
        assertTrue(!model.isDegraded)
    }
}
