# MoonBPMN

MoonBPMN is a MoonBit-native BPMN 2.0 process model, validator, and deterministic
token execution engine. It is intended as reusable infrastructure for workflow
tools, process editors, teaching software, CI validation, and embedded runtimes.

The project is under active development for the 2026 MoonBit October Hackathon.
The current milestone implements a typed process model, structural validation,
typed variables, deterministic token execution, event logs, JSON reports, and
Mermaid export. BPMN XML import is the next major milestone.

## Why MoonBPMN

Existing MoonBit UML and diagram packages focus on notation or rendering.
MoonBPMN focuses on BPMN process semantics:

- a typed process graph;
- actionable structural diagnostics;
- BPMN XML import and normalized export;
- deterministic token execution and event logs;
- snapshots, replay, and portable Wasm execution.

The initial compatibility target is an executable BPMN 2.0 subset rather than
the complete BPMN specification. Unsupported elements will produce explicit
diagnostics instead of being silently ignored.

## Current API

```moonbit check
///|
test "validate a minimal process" {
  let process = @moonbpmn.ProcessModel::new("order_approval", "Order approval")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Submitted"))
  process.add_node(@moonbpmn.ProcessNode::task("review", "Review order"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Approved"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "review"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "review", "done"))

  let report = @moonbpmn.validate(process)
  assert_true(report.is_valid())
}
```

Execute a conditional approval process:

```moonbit check
///|
test "execute an exclusive choice" {
  let process = @moonbpmn.ProcessModel::new("choice", "Choice")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::exclusive_gateway("route", "Route"))
  process.add_node(@moonbpmn.ProcessNode::end_event("yes", "Accepted"))
  process.add_node(@moonbpmn.ProcessNode::end_event("no", "Rejected"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "route"))
  process.add_flow(
    @moonbpmn.SequenceFlow::conditional(
      "accept", "route", "yes", "accepted", "accepted",
    ),
  )
  process.add_flow(@moonbpmn.SequenceFlow::new("reject", "route", "no"))

  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::bool("accepted", true))
  let result = @moonbpmn.run(process, variables, 100)
  assert_true(result.is_completed())
  assert_eq(result.selected_flows, ["f1", "accept"])
}
```

Run the example CLI:

```shell
moon run cmd/main
```

The example validates an order-approval model, prints a JSON validation report,
runs the approved branch, reports the append-only event count, and emits a
Mermaid flowchart. This makes it a reproducible smoke test as well as an API
demonstration.

## Supported executable subset

- start and end events;
- automatically completed tasks;
- exclusive gateways with boolean-variable conditions and one default flow;
- parallel split and synchronizing join gateways;
- deterministic FIFO token scheduling with a caller-provided step limit;
- stable validation diagnostics, JSON reports, and ordered execution events.

Unsupported BPMN elements are not claimed as compatible. The validator rejects
structurally invalid models before execution.

## Development

MoonBPMN requires `moonc` 0.10.14 or newer.

```shell
moon check
moon test
moon info
moon fmt --check
```

See [docs/PROJECT_SCOPE.md](docs/PROJECT_SCOPE.md) for the committed scope and
[docs/DUPLICATION_CHECK.md](docs/DUPLICATION_CHECK.md) for the public-project
comparison that motivated this project.

## License

Apache-2.0. BPMN is a standard published by the Object Management Group. Any
future ported code or imported fixture will be recorded with its source and
license; the current implementation is original MoonBit code.
