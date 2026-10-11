package io.sate.ai.core

import io.sate.ai.adapters.MockModelAdapter
import io.sate.ai.injectors.MemoryPressureInjector
import io.sate.ai.injectors.MalformedInputInjector
import kotlinx.coroutines.runBlocking
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class StressRunnerTest {
    @Test
    fun runsAllInjectors() = runBlocking {
        val model = MockModelAdapter()
        val runner = StressRunner(
            model = model,
            injectors = listOf(
                MemoryPressureInjector(model, 50),
                MalformedInputInjector(),
            ),
        )
        val report = runner.run()
        assertEquals(2, report.results.size)
        assertTrue(report.passed)
    }

    @Test
    fun detectsMemoryPressureDegradation() = runBlocking {
        val model = MockModelAdapter()
        val runner = StressRunner(
            model = model,
            injectors = listOf(MemoryPressureInjector(model, 200)),
        )
        val report = runner.run()
        assertTrue(report.results.first().passed == false)
    }
}
