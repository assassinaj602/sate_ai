---
name: Custom Fault Injector Proposal
about: Propose a new FaultInjector implementation for SATE AI
title: "[Injector] "
labels: injector, enhancement
assignees: ""
---

## Injector Name

e.g. `ThermalThrottleInjector`

## FaultType

Which `FaultType` enum value does this map to?
- [ ] `memoryPressure`
- [ ] `malformedInput`
- [ ] `latency`
- [ ] `thermalThrottle`
- [ ] `networkFailure`
- [ ] New type (please describe)

## What Failure Mode Does This Simulate?

Describe the real-world failure scenario this injector covers.

## Implementation Idea

How would this injector work? Platform channels? CPU busy-loop? Hooking?

```dart
class ThermalThrottleInjector implements FaultInjector {
  // Sketch of implementation
}
```

## Testing Plan

How would you verify this injector works correctly?

## Are you willing to implement this?

- [ ] Yes, I'd like to implement this myself
- [ ] No, I'm proposing it for others to implement
