///|
fn approval_process() -> @moonbpmn.ProcessModel {
  let process = @moonbpmn.ProcessModel::new("approval", "Approval")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::task("review", "Review"))
  process.add_node(
    @moonbpmn.ProcessNode::exclusive_gateway("choice", "Decision"),
  )
  process.add_node(@moonbpmn.ProcessNode::end_event("approved", "Approved"))
  process.add_node(@moonbpmn.ProcessNode::end_event("rejected", "Rejected"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "review"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "review", "choice"))
  process.add_flow(
    @moonbpmn.SequenceFlow::conditional(
      "approve", "choice", "approved", "approved", "approved",
    ),
  )
  process.add_flow(@moonbpmn.SequenceFlow::new("reject", "choice", "rejected"))
  process
}

///|
test "runner completes a linear process" {
  let process = @moonbpmn.ProcessModel::new("linear", "Linear")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::task("work", "Work"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "work"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "work", "done"))
  let result = @moonbpmn.run(process, @moonbpmn.VariableSet::new(), 20)
  assert_true(result.is_completed())
  assert_eq(result.visited_nodes, ["start", "work", "done"])
  assert_eq(result.steps, 3)
}

///|
test "exclusive gateway selects a true condition" {
  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::bool("approved", true))
  let result = @moonbpmn.run(approval_process(), variables, 20)
  assert_true(result.is_completed())
  assert_eq(result.selected_flows, ["f1", "f2", "approve"])
}

///|
test "exclusive gateway uses its default branch" {
  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::bool("approved", false))
  let result = @moonbpmn.run(approval_process(), variables, 20)
  assert_true(result.is_completed())
  assert_eq(result.selected_flows, ["f1", "f2", "reject"])
}

///|
test "runner reports unknown condition variables" {
  let result = @moonbpmn.run(
    approval_process(),
    @moonbpmn.VariableSet::new(),
    20,
  )
  assert_eq(
    result.status,
    @moonbpmn.RunStatus::RunStalled("unknown condition variable: approved"),
  )
}
