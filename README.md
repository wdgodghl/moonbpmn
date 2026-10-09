# MoonBPMN

MoonBPMN is a MoonBit-native BPMN 2.0 process model, validator, and deterministic
token execution engine. It is intended as reusable infrastructure for workflow
tools, process editors, teaching software, CI validation, and embedded runtimes.

The project is under active development for the 2026 MoonBit October Hackathon.
The first milestone implements a typed process model and structural validation;
BPMN XML import and token execution are the next milestones.

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

## Development

MoonBPMN requires `moonc` 0.10.14 or newer.

```shell
moon check
moon test
moon info
moon fmt --check
```

See `README.mbt.md` for the checked MoonBit example and `docs/PROJECT_SCOPE.md`
for the committed scope.

## License

Apache-2.0.
