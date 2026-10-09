///|
test "validation report JSON exposes stable diagnostic codes" {
  let process = @moonbpmn.ProcessModel::new("broken", "Broken")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("bad", "start", "missing"))
  let json = @moonbpmn.validation_report_json(@moonbpmn.validate(process))
  assert_true(json.contains("\"valid\":false"))
  assert_true(json.contains("\"code\":\"missing_target\""))
  assert_true(json.contains("\"elementId\":\"bad\""))
}

///|
test "valid report JSON contains an empty diagnostic array" {
  let process = @moonbpmn.ProcessModel::new("ok", "OK")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("finish", "start", "done"))
  let json = @moonbpmn.validation_report_json(@moonbpmn.validate(process))
  assert_true(json.contains("\"valid\":true"))
  assert_true(json.contains("\"diagnostics\":[]"))
}
