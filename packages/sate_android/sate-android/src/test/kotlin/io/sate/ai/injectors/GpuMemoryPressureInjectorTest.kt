package io.sate.ai.injectors

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class GpuMemoryPressureInjectorTest {
    @Test
    fun testMetadata() {
        val model = MockModelAdapter()
        val injector = GpuMemoryPressureInjector(model, limitMb = 120)
        assertEquals(FaultType.GPU_MEMORY_PRESSURE, injector.type)
        assertEquals("GPU Memory Pressure Injector", injector.name)
        assertTrue(injector.description.contains("120"))
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val model = MockModelAdapter()
        val injector = GpuMemoryPressureInjector(model, limitMb = 200)
        injector.inject()
        assertTrue(model.isDegraded)
        injector.reset()
        assertTrue(!model.isDegraded)
    }
}
