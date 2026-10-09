///|
test "DOT exporter maps BPMN kinds and conditional flows" {
  let process = @moonbpmn.ProcessModel::new("dot", "DOT")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::exclusive_gateway("choice", "Choose"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "choice"))
  process.add_flow(
    @moonbpmn.SequenceFlow::conditional(
      "f2", "choice", "done", "approved", "approved",
    ),
  )
  let dot = @moonbpmn.to_dot(process)
  assert_true(dot.contains("\"start\" [label=\"Start\", shape=circle]"))
  assert_true(dot.contains("\"choice\" [label=\"Choose\", shape=diamond]"))
  assert_true(dot.contains("\"done\" [label=\"Done\", shape=doublecircle]"))
  assert_true(dot.contains("\"choice\" -> \"done\" [label=\"approved\"]"))
}

///|
test "DOT exporter escapes identifiers and labels" {
  let process = @moonbpmn.ProcessModel::new("quoted\"id", "Quoted")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Say \"go\""))
  let dot = @moonbpmn.to_dot(process)
  assert_true(dot.contains("digraph \"quoted\\\"id\""))
  assert_true(dot.contains("label=\"Say \\\"go\\\"\""))
}
