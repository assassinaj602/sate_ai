package io.sate.ai.core

/// Output from a model adapter after inference.
data class AIOutput(
    val text: String,
    val inferenceTimeMs: Long,
    val confidence: Double? = null,
    val metadata: Map<String, String> = emptyMap(),
)
