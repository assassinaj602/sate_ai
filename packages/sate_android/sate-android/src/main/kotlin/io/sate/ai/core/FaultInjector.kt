package io.sate.ai.core

/// A fault injector simulates a specific failure mode against a model adapter.
interface FaultInjector {
    val type: FaultType
    val name: String
    val description: String

    /// Inject the fault. Called before running inference.
    suspend fun inject()

    /// Reset the fault state. Called after the test.
    suspend fun reset()
}
