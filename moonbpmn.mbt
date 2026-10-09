///|
/// Validate a process model and return every structural diagnostic found.
pub fn validate(process : ProcessModel) -> ValidationReport {
  let diagnostics : Array[Diagnostic] = []
  validate_process_identity(process, diagnostics)
  validate_node_identity(process, diagnostics)
  validate_flow_identity(process, diagnostics)
  validate_flow_endpoints(process, diagnostics)
  validate_event_counts(process, diagnostics)
  validate_node_degrees(process, diagnostics)
  validate_reachability(process, diagnostics)
  ValidationReport::new(diagnostics)
}
