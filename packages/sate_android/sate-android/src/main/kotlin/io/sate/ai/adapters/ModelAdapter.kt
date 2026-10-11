package io.sate.ai.adapters

import io.sate.ai.core.AIInput
import io.sate.ai.core.AIOutput

/// Interface for wrapping an on-device AI model.
interface ModelAdapter {
    val modelId: String
    val currentMemoryMB: Double
    val isDegraded: Boolean

    suspend fun runInference(input: AIInput): AIOutput
    suspend fun simulateMemoryPressure(mb: Int)
    suspend fun reset()
    suspend fun isHealthy(): Boolean
}

/// Exception thrown when inference fails.
class AIInferenceError(message: String, cause: Throwable? = null) : Exception(message, cause)
