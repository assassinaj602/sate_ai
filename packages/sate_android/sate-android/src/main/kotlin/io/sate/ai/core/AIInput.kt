package io.sate.ai.core

/// Input passed to a model adapter for inference.
data class AIInput(
    val text: String? = null,
    val binary: ByteArray? = null,
    val metadata: Map<String, String> = emptyMap(),
) {
    init {
        require(text != null || binary != null) {
            "Either text or binary must be provided"
        }
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is AIInput) return false
        return text == other.text &&
            binary.contentEquals(other.binary) &&
            metadata == other.metadata
    }

    override fun hashCode(): Int {
        var result = text?.hashCode() ?: 0
        result = 31 * result + (binary?.contentHashCode() ?: 0)
        result = 31 * result + metadata.hashCode()
        return result
    }
}
