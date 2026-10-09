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

///|
test "parallel join waits for every incoming token" {
  let process = @moonbpmn.ProcessModel::new("parallel", "Parallel review")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::parallel_gateway("fork", "Fork"))
  process.add_node(@moonbpmn.ProcessNode::task("legal", "Legal review"))
  process.add_node(@moonbpmn.ProcessNode::task("risk", "Risk review"))
  process.add_node(@moonbpmn.ProcessNode::parallel_gateway("join", "Join"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "fork"))
  process.add_flow(@moonbpmn.SequenceFlow::new("legal", "fork", "legal"))
  process.add_flow(@moonbpmn.SequenceFlow::new("risk", "fork", "risk"))
  process.add_flow(@moonbpmn.SequenceFlow::new("legal_join", "legal", "join"))
  process.add_flow(@moonbpmn.SequenceFlow::new("risk_join", "risk", "join"))
  process.add_flow(@moonbpmn.SequenceFlow::new("finish", "join", "done"))
  let result = @moonbpmn.run(process, @moonbpmn.VariableSet::new(), 30)
  assert_true(result.is_completed())
  assert_eq(result.selected_flows, [
    "f1", "legal", "risk", "legal_join", "risk_join", "finish",
  ])
  assert_eq(result.visited_nodes.length(), 7)
}

///|
test "runner emits an ordered append-only event log" {
  let process = @moonbpmn.ProcessModel::new("events", "Events")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("finish", "start", "done"))
  let result = @moonbpmn.run(process, @moonbpmn.VariableSet::new(), 10)
  assert_eq(result.events.length(), 4)
  assert_eq(result.events[0].sequence, 0)
  assert_eq(result.events[0].kind, @moonbpmn.ExecutionEventKind::NodeEntered)
  assert_eq(result.events[1].kind, @moonbpmn.ExecutionEventKind::FlowSelected)
  assert_eq(result.events[2].element_id, "done")
  assert_eq(
    result.events[3].kind,
    @moonbpmn.ExecutionEventKind::ProcessCompleted,
  )
}
