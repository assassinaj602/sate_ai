package io.sate.ai.injectors

import io.sate.ai.core.FaultInjector
import io.sate.ai.core.FaultType

class MalformedInputInjector : FaultInjector {
    override val type = FaultType.MALFORMED_INPUT
    override val name = "Malformed Input Injector"
    override val description = "Injects empty, oversized, and binary garbage inputs"

    override suspend fun inject() { /* no state */ }
    override suspend fun reset() { /* no state */ }
}
