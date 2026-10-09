///|
/// Severity of a validation diagnostic.
pub(all) enum Severity {
  Error
  Warning
} derive(Eq)

///|
pub extend Severity with Eq::{equal, not_equal}

///|
/// Stable machine-readable diagnostic codes.
pub(all) enum DiagnosticCode {
  EmptyProcessId
  DuplicateNodeId
  DuplicateFlowId
  EmptyNodeId
  EmptyFlowId
  MissingSource
  MissingTarget
  MissingStartEvent
  MultipleStartEvents
  MissingEndEvent
  StartHasIncoming
  StartHasNoOutgoing
  EndHasOutgoing
  EndHasNoIncoming
  TaskHasNoIncoming
  TaskHasNoOutgoing
  UnreachableNode
} derive(Eq)

///|
pub extend DiagnosticCode with Eq::{equal, not_equal}

///|
/// One actionable problem found in a process definition.
pub(all) struct Diagnostic {
  severity : Severity
  code : DiagnosticCode
  element_id : String
  message : String
}

///|
pub fn Diagnostic::error(
  code : DiagnosticCode,
  element_id : String,
  message : String,
) -> Diagnostic {
  { severity: Error, code, element_id, message, }
}

///|
pub fn Diagnostic::warning(
  code : DiagnosticCode,
  element_id : String,
  message : String,
) -> Diagnostic {
  { severity: Warning, code, element_id, message, }
}

///|
pub(all) struct ValidationReport {
  diagnostics : Array[Diagnostic]
}

///|
fn ValidationReport::new(diagnostics : Array[Diagnostic]) -> ValidationReport {
  { diagnostics, }
}

///|
pub fn ValidationReport::is_valid(self : ValidationReport) -> Bool {
  for diagnostic in self.diagnostics {
    if diagnostic.severity == Error {
      return false
    }
  }
  true
}

///|
pub fn ValidationReport::error_count(self : ValidationReport) -> Int {
  let mut count = 0
  for diagnostic in self.diagnostics {
    if diagnostic.severity == Error {
      count = count + 1
    }
  }
  count
}

///|
pub fn ValidationReport::has_code(
  self : ValidationReport,
  code : DiagnosticCode,
) -> Bool {
  for diagnostic in self.diagnostics {
    if diagnostic.code == code {
      return true
    }
  }
  false
}
