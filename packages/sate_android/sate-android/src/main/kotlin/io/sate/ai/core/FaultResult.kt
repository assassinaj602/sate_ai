package io.sate.ai.core

import kotlinx.serialization.Serializable

/// Result of one injector's test.
@Serializable
data class FaultResult(
    val injectorType: FaultType,
    val passed: Boolean,
    val inferenceTimeMs: Long? = null,
    val memoryUsageMB: Double? = null,
    val errorMessage: String? = null,
)
