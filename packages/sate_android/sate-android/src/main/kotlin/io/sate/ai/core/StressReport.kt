package io.sate.ai.core

import kotlinx.serialization.Serializable
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Serializable
data class Failure(
    val injectorType: FaultType,
    val message: String,
)

@Serializable
data class StressReport(
    val modelId: String,
    val passed: Boolean,
    val results: List<FaultResult>,
    val failures: List<Failure>,
    val startTimeIso: String,
    val endTimeIso: String,
    val totalDurationMs: Long,
) {
    val passCount: Int get() = results.count { it.passed }
    val failureCount: Int get() = results.count { !it.passed }

    fun toJsonString(): String = Json.encodeToString(this)

    fun toMarkdown(): String {
        val sb = StringBuilder()
        sb.appendLine("# SATE AI Stress Report: $modelId")
        sb.appendLine()
        sb.appendLine("- Status: ${if (passed) "PASS" else "FAIL"}")
        sb.appendLine("- Total tests: ${results.size}")
        sb.appendLine("- Passed: $passCount")
        sb.appendLine("- Failed: $failureCount")
        sb.appendLine("- Duration: ${totalDurationMs}ms")
        sb.appendLine()
        sb.appendLine("## Results")
        for (r in results) {
            sb.appendLine("- ${r.injectorType.displayName}: ${if (r.passed) "PASS" else "FAIL"}" +
                (r.errorMessage?.let { " ($it)" } ?: ""))
        }
        return sb.toString()
    }

    companion object {
        fun fromJsonString(json: String): StressReport = Json.decodeFromString(json)
    }
}
