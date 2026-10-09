# MoonBPMN project scope

## Goal

Build a reusable MoonBit implementation of an executable BPMN 2.0 core. The
project is a library first: editors, CLIs, CI systems, and Wasm applications
should be able to depend on the same model, validator, and runtime.

## Committed release scope

### Process model

- Process, flow nodes, sequence flows, conditions, and extension metadata.
- Start/end events, tasks, exclusive gateways, and parallel gateways.
- Stable identifiers and normalized model serialization.

### BPMN XML

- Namespace-aware import for the supported subset.
- Source-location-aware diagnostics.
- Deterministic normalized XML export.
- Explicit unsupported-element diagnostics.

### Static validation

- Identity and reference integrity.
- Start/end event and node-degree rules.
- Reachability and path-to-completion analysis.
- Gateway split/join consistency.
- Cycle and deadlock diagnostics where they can be determined statically.

### Runtime

- Deterministic token semantics.
- Task completion and exclusive branch selection.
- Parallel split and join.
- Process variables and a small typed condition language.
- Append-only event log, snapshot, restore, and replay.

### Tooling

- Library API and a CLI for validate, normalize, run, and replay.
- JSON diagnostic output and Mermaid/DOT graph export.
- Native and Wasm-compatible core packages.

## Explicit non-goals for the first release

- Complete coverage of the full BPMN 2.0 specification.
- Human-task inboxes, persistence servers, authentication, or web UI.
- DMN, CMMN, BPMN choreography, and BPMN diagram interchange rendering.
- Compatibility claims for elements that are not exercised by conformance tests.

## Quality targets

- At least 2,000 lines of maintained MoonBit implementation code.
- At least 100 focused tests plus malformed-input and regression fixtures.
- CI gates for format, check, build, test, documentation tests, and publish dry-run.
- Every supported BPMN element documented with accepted and rejected examples.
