package io.sate.ai.adapters

import io.sate.ai.core.AIInput
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class MockModelAdapterTest {
    @Test
    fun testNormalInference() = runBlocking {
        val adapter = MockModelAdapter("test-mock", inferenceDelayMs = 10)
        val output = adapter.runInference(AIInput(text = "hello"))
        assertTrue(output.text.contains("hello"))
        assertEquals(0.95, output.confidence)
        assertTrue(adapter.isHealthy())
    }

    @Test
    fun testDegradationOnMemoryPressure() = runBlocking {
        val adapter = MockModelAdapter("test-mock")
        adapter.simulateMemoryPressure(200)
        assertTrue(adapter.isDegraded)
        assertFalse(adapter.isHealthy())

        val output = adapter.runInference(AIInput(text = "test"))
        assertTrue(output.text.contains("Degraded"))
        assertEquals(0.3, output.confidence)

        adapter.reset()
        assertFalse(adapter.isDegraded)
        assertTrue(adapter.isHealthy())
    }
}
