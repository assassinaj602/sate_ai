package io.sate.ai.injectors

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class NetworkLatencyDropInjectorTest {
    @Test
    fun testMetadata() {
        val model = MockModelAdapter()
        val injector = NetworkLatencyDropInjector(model, dropProbability = 0.4)
        assertEquals(FaultType.NETWORK_FAILURE, injector.type)
        assertEquals("Network Latency Drop Injector", injector.name)
        assertTrue(injector.description.contains("0.4"))
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val model = MockModelAdapter()
        val injector = NetworkLatencyDropInjector(model, dropProbability = 2.0)
        injector.inject()
        assertTrue(model.isDegraded)
        injector.reset()
        assertTrue(!model.isDegraded)
    }
}
