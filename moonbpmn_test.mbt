///|
test "minimal linear process is valid" {
  let process = @moonbpmn.ProcessModel::new("order", "Order approval")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Submitted"))
  process.add_node(@moonbpmn.ProcessNode::task("review", "Review"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Approved"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "review"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "review", "done"))
  let report = @moonbpmn.validate(process)
  assert_true(report.is_valid())
  assert_eq(report.error_count(), 0)
}

///|
test "dangling sequence flow is diagnosed" {
  let process = @moonbpmn.ProcessModel::new("broken", "Broken process")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "missing"))
  let report = @moonbpmn.validate(process)
  assert_false(report.is_valid())
  assert_true(report.has_code(@moonbpmn.DiagnosticCode::MissingTarget))
}

///|
test "unreachable task is diagnosed" {
  let process = @moonbpmn.ProcessModel::new("island", "Island process")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_node(@moonbpmn.ProcessNode::task("island", "Unreachable"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "done"))
  let report = @moonbpmn.validate(process)
  assert_true(report.has_code(@moonbpmn.DiagnosticCode::UnreachableNode))
}
