# MoonBPMN compatibility matrix

MoonBPMN intentionally implements a documented executable subset instead of
claiming complete BPMN 2.0 conformance. Unsupported executable elements produce
an import issue when they are recognized.

## Model and XML

| BPMN feature | Status | Notes |
| --- | --- | --- |
| Process | Supported | One executable process per imported document |
| Start event | Supported | Exactly one required by the current validator |
| End event | Supported | One or more allowed |
| Task | Supported | Completes immediately in the in-memory runner |
| Exclusive gateway | Supported | Boolean conditions plus one default flow |
| Parallel gateway | Supported | FIFO split and incoming-token join |
| Sequence flow | Supported | IDs, names, source/target references, condition text |
| XML namespace prefixes | Supported | Prefix-independent local element names |
| XML entities | Supported | Standard entities in imported attributes and text |
| Normalized XML export | Supported | Stable declaration order and escaped values |
| CDATA conditions | Supported | Imported and normalized to escaped text |
| User/service/script task | Reported unsupported | Preserved compatibility is not claimed |
| Inclusive/event-based gateway | Reported unsupported | Not executed |
| Subprocesses | Reported unsupported | Not imported recursively |
| Boundary/intermediate events | Not supported | Planned after resumable task instances |
| BPMN DI diagram coordinates | Ignored | Use Mermaid or DOT export for visualization |

## Validation and runtime

| Capability | Status |
| --- | --- |
| Duplicate and empty identifiers | Supported |
| Missing sequence-flow references | Supported |
| Start/end and node-degree rules | Supported |
| Reachability and path-to-completion | Supported |
| Exclusive default-flow consistency | Supported |
| Boolean variables and literal conditions | Supported |
| Deterministic bounded execution | Supported |
| Parallel split and synchronization | Supported |
| Append-only event log | Supported |
| Sequence-checked event replay | Supported |
| JSON validation/execution reports | Supported |
| Runtime snapshots and paused tasks | Planned |

This table describes the current `main` branch. New supported elements require
tests for accepted input, rejected input, XML round trips, and runtime behavior.
