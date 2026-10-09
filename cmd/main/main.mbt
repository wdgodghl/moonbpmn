///|
fn build_order_approval() -> @moonbpmn.ProcessModel {
  let process = @moonbpmn.ProcessModel::new("order_approval", "Order approval")
  process.add_node(@moonbpmn.ProcessNode::start_event("start", "Submitted"))
  process.add_node(@moonbpmn.ProcessNode::task("review", "Review order"))
  process.add_node(
    @moonbpmn.ProcessNode::exclusive_gateway("decision", "Approved?"),
  )
  process.add_node(@moonbpmn.ProcessNode::end_event("approved", "Approved"))
  process.add_node(@moonbpmn.ProcessNode::end_event("rejected", "Rejected"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f1", "start", "review"))
  process.add_flow(@moonbpmn.SequenceFlow::new("f2", "review", "decision"))
  process.add_flow(
    @moonbpmn.SequenceFlow::conditional(
      "approve", "decision", "approved", "approved", "approved",
    ),
  )
  process.add_flow(
    @moonbpmn.SequenceFlow::named("reject", "decision", "rejected", "otherwise"),
  )
  process
}

///|
fn status_name(status : @moonbpmn.RunStatus) -> String {
  match status {
    RunCompleted => "completed"
    RunInvalidModel => "invalid-model"
    RunStalled(message) => "stalled: " + message
    RunStepLimitExceeded => "step-limit-exceeded"
  }
}

///|
fn main {
  let process = build_order_approval()
  let report = @moonbpmn.validate(process)
  println("MoonBPMN runnable example")
  println("process: " + process.id)
  println("nodes: " + process.node_count().to_string())
  println("flows: " + process.flow_count().to_string())
  println("validation JSON: " + @moonbpmn.validation_report_json(report))
  if !report.is_valid() {
    println("execution skipped because the model is invalid")
    return
  }
  let variables = @moonbpmn.VariableSet::new()
  variables.set(@moonbpmn.ProcessVariable::bool("approved", true))
  let result = @moonbpmn.run(process, variables, 100)
  println("execution: " + status_name(result.status))
  println("steps: " + result.steps.to_string())
  println("events: " + result.events.length().to_string())
  println("--- Mermaid ---")
  println(@moonbpmn.to_mermaid(process))
}
