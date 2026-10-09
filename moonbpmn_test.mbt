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

///|
test "graph queries preserve sequence flow declaration order" {
  let process = @moonbpmn.ProcessModel::new("routing", "Routing")
  process.add_node(@moonbpmn.ProcessNode::exclusive_gateway("choice", "Choose"))
  process.add_node(@moonbpmn.ProcessNode::task("left", "Left"))
  process.add_node(@moonbpmn.ProcessNode::task("right", "Right"))
  process.add_flow(@moonbpmn.SequenceFlow::new("to_left", "choice", "left"))
  process.add_flow(@moonbpmn.SequenceFlow::new("to_right", "choice", "right"))
  let outgoing = process.outgoing_flows("choice")
  assert_eq(outgoing.length(), 2)
  assert_eq(outgoing[0].id, "to_left")
  assert_eq(outgoing[1].id, "to_right")
  assert_eq(process.predecessor_ids("right"), ["choice"])
  match process.find_flow("to_left") {
    Some(flow) => assert_eq(flow.target, "left")
    None => fail("expected to find flow to_left")
  }
}

///|
test "exclusive gateway rejects multiple unconditional branches" {
  let process = @moonbpmn.ProcessModel::new("bad_choice", "Bad choice")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::exclusive_gateway("choice", "Choose"))
  process.add_node(@moonbpmn.ProcessNode::end_event("left", "Left"))
  process.add_node(@moonbpmn.ProcessNode::end_event("right", "Right"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "choice"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "choice", "left"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f3", "choice", "right"))
  let report = @moonbpmn.validate(process)
  assert_true(report.has_code(@moonbpmn.DiagnosticCode::MultipleDefaultFlows))
}

///|
test "reachable cycle without completion path is diagnosed" {
  let process = @moonbpmn.ProcessModel::new("loop", "Loop")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::task("a", "A"))
  process.add_node(@moonbpmn.ProcessNode::task("b", "B"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "a"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "a", "b"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f3", "b", "a"))
  let report = @moonbpmn.validate(process)
  assert_true(report.has_code(@moonbpmn.DiagnosticCode::NoPathToEnd))
}

///|
test "cycle with an exit is valid but produces a warning" {
  let process = @moonbpmn.ProcessModel::new("cycle_exit", "Cycle with exit")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::task("work", "Work"))
  process.add_node(@moonbpmn.ProcessNode::exclusive_gateway("choice", "Again?"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "work"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "work", "choice"))
  process.add_flow(
    @moonbpmn.SequenceFlow::conditional(
      "again", "choice", "work", "again", "true",
    ),
  )
  process.add_flow(@moonbpmn.SequenceFlow::new("finish", "choice", "done"))
  let report = @moonbpmn.validate(process)
  assert_true(report.is_valid())
  assert_true(report.has_code(@moonbpmn.DiagnosticCode::CycleDetected))
  assert_eq(report.warning_count(), 2)
}

///|
test "parallel join rejects mutually exclusive direct inputs" {
  let process = @moonbpmn.ProcessModel::new("deadlock", "Deadlock")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::exclusive_gateway("choice", "Choose"))
  process.add_node(@moonbpmn.ProcessNode::parallel_gateway("join", "Join"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "choice"))
  process.add_flow(
    @moonbpmn.SequenceFlow::conditional(
      "left", "choice", "join", "left", "true",
    ),
  )
  process.add_flow(@moonbpmn.SequenceFlow::new("right", "choice", "join"))
  process.add_flow(@moonbpmn.SequenceFlow::new("finish", "join", "done"))
  let report = @moonbpmn.validate(process)
  assert_false(report.is_valid())
  assert_true(
    report.has_code(@moonbpmn.DiagnosticCode::ParallelJoinCannotSynchronize),
  )
}
