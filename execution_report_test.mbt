///|
test "execution result JSON contains the replayable event log" {
  let process = @moonbpmn.ProcessModel::new("json_run", "JSON run")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("finish", "start", "done"))
  let result = @moonbpmn.run(process, @moonbpmn.VariableSet::new(), 10)
  let json = @moonbpmn.execution_result_json(result)
  assert_true(json.contains("\"status\":\"completed\""))
  assert_true(json.contains("\"visitedNodes\":[\"start\",\"done\"]"))
  assert_true(json.contains("\"kind\":\"flow_selected\""))
  assert_true(json.contains("\"elementId\":\"finish\""))
}

///|
test "execution result JSON includes failure details" {
  let process = @moonbpmn.ProcessModel::new("invalid", "Invalid")
  let result = @moonbpmn.run(process, @moonbpmn.VariableSet::new(), 10)
  let json = @moonbpmn.execution_result_json(result)
  assert_true(json.contains("\"status\":\"invalid_model\""))
  assert_true(json.contains("\"message\":\"model is invalid\""))
}
