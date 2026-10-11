package io.sate.ai.injectors

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class LatencyInjectorTest {
    @Test
    fun testMetadata() {
        val model = MockModelAdapter()
        val injector = LatencyInjector(model, baseDelayMs = 15, incrementMs = 10, maxLatencyMs = 60)
        assertEquals(FaultType.LATENCY, injector.type)
        assertEquals("Latency Injector", injector.name)
        assertTrue(injector.description.contains("60"))
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val model = MockModelAdapter()
        val injector = LatencyInjector(model, incrementMs = 200)
        injector.inject()
        assertTrue(model.isDegraded)
        injector.reset()
        assertTrue(!model.isDegraded)
    }
}
