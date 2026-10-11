package io.sate.ai.injectors

import io.sate.ai.core.FaultType
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class MalformedInputInjectorTest {
    @Test
    fun testMetadata() {
        val injector = MalformedInputInjector()
        assertEquals(FaultType.MALFORMED_INPUT, injector.type)
        assertEquals("Malformed Input Injector", injector.name)
        assertTrue(injector.description.isNotEmpty())
    }

    @Test
    fun testInjectAndReset() = runBlocking {
        val injector = MalformedInputInjector()
        injector.inject()
        injector.reset()
    }
}
