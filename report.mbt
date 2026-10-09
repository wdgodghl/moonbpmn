///|
fn severity_name(severity : Severity) -> String {
  match severity {
    Error => "error"
    Warning => "warning"
  }
}

///|
fn diagnostic_code_name(code : DiagnosticCode) -> String {
  match code {
    EmptyProcessId => "empty_process_id"
    DuplicateNodeId => "duplicate_node_id"
    DuplicateFlowId => "duplicate_flow_id"
    EmptyNodeId => "empty_node_id"
    EmptyFlowId => "empty_flow_id"
    MissingSource => "missing_source"
    MissingTarget => "missing_target"
    MissingStartEvent => "missing_start_event"
    MultipleStartEvents => "multiple_start_events"
    MissingEndEvent => "missing_end_event"
    StartHasIncoming => "start_has_incoming"
    StartHasNoOutgoing => "start_has_no_outgoing"
    EndHasOutgoing => "end_has_outgoing"
    EndHasNoIncoming => "end_has_no_incoming"
    TaskHasNoIncoming => "task_has_no_incoming"
    TaskHasNoOutgoing => "task_has_no_outgoing"
    GatewayHasNoIncoming => "gateway_has_no_incoming"
    GatewayHasNoOutgoing => "gateway_has_no_outgoing"
    MultipleDefaultFlows => "multiple_default_flows"
    UnreachableNode => "unreachable_node"
    NoPathToEnd => "no_path_to_end"
    CycleDetected => "cycle_detected"
    ParallelJoinCannotSynchronize => "parallel_join_cannot_synchronize"
  }
}

///|
/// Serialize a validation report as stable, machine-readable JSON.
pub fn validation_report_json(report : ValidationReport) -> String {
  let items : Array[Json] = []
  for diagnostic in report.diagnostics {
    items.push({
      "severity": severity_name(diagnostic.severity),
      "code": diagnostic_code_name(diagnostic.code),
      "elementId": diagnostic.element_id,
      "message": diagnostic.message,
    })
  }
  let document : Json = {
    "valid": report.is_valid(),
    "errorCount": report.error_count(),
    "warningCount": report.warning_count(),
    "diagnostics": items,
  }
  document.stringify()
}
