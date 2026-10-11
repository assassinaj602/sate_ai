package io.sate.ai.core

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class StressReportTest {
    @Test
    fun formatsMarkdownCorrectly() {
        val report = StressReport(
            modelId = "test-model",
            passed = true,
            results = listOf(
                FaultResult(FaultType.MEMORY_PRESSURE, passed = true, inferenceTimeMs = 50),
                FaultResult(FaultType.MALFORMED_INPUT, passed = true, inferenceTimeMs = 40),
            ),
            failures = emptyList(),
            startTimeIso = "2026-10-11T12:00:00Z",
            endTimeIso = "2026-10-11T12:00:05Z",
            totalDurationMs = 5000,
        )
        val md = report.toMarkdown()
        assertTrue(md.contains("# SATE AI Stress Report: test-model"))
        assertTrue(md.contains("Status: PASS"))
        assertEquals(2, report.passCount)
        assertEquals(0, report.failureCount)
    }

    @Test
    fun serializesAndDeserializesJson() {
        val report = StressReport(
            modelId = "test-model",
            passed = false,
            results = listOf(
                FaultResult(FaultType.MEMORY_PRESSURE, passed = false, errorMessage = "Out of memory"),
            ),
            failures = listOf(Failure(FaultType.MEMORY_PRESSURE, "Out of memory")),
            startTimeIso = "2026-10-11T12:00:00Z",
            endTimeIso = "2026-10-11T12:00:01Z",
            totalDurationMs = 1000,
        )
        val json = report.toJsonString()
        val deserialized = StressReport.fromJsonString(json)
        assertEquals(report.modelId, deserialized.modelId)
        assertEquals(report.passed, deserialized.passed)
        assertEquals(1, deserialized.failureCount)
    }
}
