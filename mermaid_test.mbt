///|
test "Mermaid exporter preserves nodes flows and conditions" {
  let process = @moonbpmn.ProcessModel::new("diagram", "Diagram")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Start"))
  process.add_node(@moonbpmn.ProcessNode::exclusive_gateway("choice", "Choose"))
  process.add_node(@moonbpmn.ProcessNode::end_event("done", "Done"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "choice"))
  process.add_flow(
    @moonbpmn.SequenceFlow::conditional(
      "f2", "choice", "done", "approved", "approved",
    ),
  )
  assert_eq(
    @moonbpmn.to_mermaid(process),
    "flowchart TD\n  start((\"Start\"))\n  choice{\"Choose\"}\n  done(((\"Done\")))\n  start --> choice\n  choice -->|approved| done\n",
  )
}
