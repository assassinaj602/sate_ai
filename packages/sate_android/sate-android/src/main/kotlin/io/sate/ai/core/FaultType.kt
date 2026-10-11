package io.sate.ai.core

/// Types of faults that can be injected into AI models.
enum class FaultType(val displayName: String) {
    MEMORY_PRESSURE("Memory Pressure"),
    MALFORMED_INPUT("Malformed Input"),
    QUANTIZATION_DRIFT("Quantization Drift"),
    THERMAL_THROTTLE("Thermal Throttle"),
    LATENCY("Latency"),
    MODEL_SWAP("Model Swap"),
    CONFIDENCE_VALIDATION("Confidence Validation"),
    GPU_MEMORY_PRESSURE("GPU Memory Pressure"),
    DATA_CORRUPTION("Data Corruption"),
    MODEL_VERSION_MISMATCH("Model Version Mismatch"),
    NETWORK_FAILURE("Network Failure"),
}
