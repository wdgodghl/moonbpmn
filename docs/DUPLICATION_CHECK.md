# Public duplication check

Checked on 2026-10-09 before repository creation.

## Search coverage

- GitHub repository search for `MoonBPMN` returned no repositories.
- GitHub repository search for BPMN and MoonBit returned no BPMN engine,
  parser, validator, or token runtime implemented in MoonBit.
- The Mooncakes public module index returned no module matching `moonbpmn` or
  `bpmn` in module names, descriptions, or keywords.

## Nearest adjacent project

`moonbit-community/uml` / `kokic/uml` is a PlantUML-to-SVG implementation. It
parses diagram notation and renders UML diagrams. MoonBPMN instead models BPMN
process semantics, validates executable workflow rules, and runs tokens. The
input format, domain model, public API, and primary use cases are different.

## Recheck policy

The ecosystem can change. Repeat the GitHub and Mooncakes searches immediately
before submitting the project proposal and before publishing the first release.
If a similar project appears, document the feature-level comparison and narrow
MoonBPMN's differentiating scope rather than claiming uniqueness without proof.
